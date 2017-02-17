#!/bin/bash
###############################################################################
# Copyright 2016 Aurora Solutions
#
#    http://www.aurorasolutions.io
#
# Aurora Solutions is an innovative services and product company at
# the forefront of the software industry, with processes and practices
# involving Domain Driven Design(DDD), Agile methodologies to build
# scalable, secure, reliable and high performance products.
#
# Stakater is an Infrastructure-as-a-Code DevOps solution to automate the
# creation of web infrastructure stack on Amazon. Stakater is a collection
# of Blueprints; where each blueprint is an opinionated, reusable, tested,
# supported, documented, configurable, best-practices definition of a piece
# of infrastructure. Stakater is based on Docker, CoreOS, Terraform, Packer,
# Docker Compose, GoCD, Fleet, ETCD, and much more.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################

###############################################################################
# Deploy to Admiral
# This script deploys infrastructure apps to admiral cluster
# Authors: Hazim
###############################################################################

APP_NAME=""
# "dev" or "qa"
CLUSTER_ENV=""
CLUSTER_ENDPOINT=""
CONFIG_BUCKET_NAME=""

GOCD_PARAMS_FILE="/gocd-data/scripts/gocd.parameters.txt"

aOptionFlag=false
eOptionFlag=false
while getopts ":a:e:c:b:" OPTION
do
    case $OPTION in
        a)
          if [ ! -z "$OPTARG" ]; then aOptionFlag=true; fi #if not empty string, then set flag true
          APP_NAME=$OPTARG;
          ;;
        e)
          if [ ! -z "$OPTARG" ]; then eOptionFlag=true; fi #if not empty string, then set flag true
          CLUSTER_ENV=$OPTARG;
          # Convert CLUSTER_ENV value to lowercase
          CLUSTER_ENV=`echo "$CLUSTER_ENV" | sed 's/./\L&/g'`
          if [[ "$CLUSTER_ENV" != "dev" && "$CLUSTER_ENV" != "qa" ]]; then
            echo "ERROR: Unknown value for CLUSTER_ENV, please enter one of 'dev' or 'qa'";
            exit 1;
          fi
          ;;
        c)
          CLUSTER_ENDPOINT=$OPTARG;
          ;;
        b)
          CONFIG_BUCKET_NAME=$OPTARG;
          ;;
        *)
          echo "Usage: $(basename $0) -a <Application name> -e <Deployment environment> -c <Cluster endpoint>(Optional) -b <config-bucket-name>(Optional)"
          exit 1
          ;;
    esac
done

if ! $aOptionFlag || ! $eOptionFlag;
then
  echo "Usage: $(basename $0) -a <Application name> -e <Deployment environment> -c <Cluster endpoint>(Optional) -b <config-bucket-name>(Optional)"
  exit 1;
fi

# If bucket name is not specified as opts, read from config file
if [ -z "$CONFIG_BUCKET_NAME" ];
then
  if [ "$CLUSTER_ENV" == "dev" ]
  then
    CONFIG_BUCKET_NAME=`/gocd-data/scripts/read-parameter.sh ${GOCD_PARAMS_FILE} DEV_CONFIG_BUCKET_NAME`
  elif [ "$CLUSTER_ENV" == "qa" ]
  then
    CONFIG_BUCKET_NAME=$`/gocd-data/scripts/read-parameter.sh ${GOCD_PARAMS_FILE} QA_CONFIG_BUCKET_NAME`
  fi
  # if still no value
  if [ -z "$CONFIG_BUCKET_NAME" ]; then echo "ERROR: Could not read value for CONFIG_BUCKET_NAME"; exit 1; fi
fi

# If cluster endpoint is not specified as opts, read from config file
if [ -z "$CLUSTER_ENDPOINT" ];
then
  if [ "$CLUSTER_ENV" == "dev" ]
  then
    CLUSTER_ENDPOINT=`/gocd-data/scripts/read-parameter.sh ${GOCD_PARAMS_FILE} DEV_ADMIRAL_ENDPOINT`
  elif [ "$CLUSTER_ENV" == "qa" ]
  then
    CLUSTER_ENDPOINT=$`/gocd-data/scripts/read-parameter.sh ${GOCD_PARAMS_FILE} QA_ADMIRAL_ENDPOINT`
  fi
  # if still no value
  if [ -z "$CLUSTER_ENDPOINT" ]; then echo "ERROR: Could not read value for CLUSTER_ENDPOINT"; exit 1; fi
fi

# If directory with app name exists in the current working dir
if [ ! -d ${APP_NAME} ];
then
  echo "ERROR: The given repo does not contian a folder for the app: $APP_NAME";
  exit 1;
fi

# Navigate to the app directory
pushd ${APP_NAME}

# If the app folder contains .service files
UNIT_FILES=(`find ./ -maxdepth 1 -name "*.service"`)
if [ ${#UNIT_FILES[@]} -gt 0 ];
then
  # Upload all sub-directories, in the app directory, to S3
  for subdirectory in */; do
    # Make sure if result is a dir not a symlink
    if [[ -d $subdirectory ]]; then
      aws s3 cp --recursive "${subdirectory}" "s3://${CONFIG_BUCKET_NAME}/admiral/${APP_NAME}/${subdirectory}"  || { echo >&2 "ERROR: aws s3 cp failed with: $?"; exit 1; }
    fi
  done

  # Submit all .service files in the app directory
  for unit_file in "${UNIT_FILES[@]}"
  do
    echo "INFO: Submitting unit '$unit_file'"
    fleetctl --etcd-key-prefix=/stakater/${CLUSTER_ENV}/admiral --endpoint=http://${CLUSTER_ENDPOINT}:4001 destroy "$unit_file"
    fleetctl --etcd-key-prefix=/stakater/${CLUSTER_ENV}/admiral --endpoint=http://${CLUSTER_ENDPOINT}:4001 start "$unit_file"  || { echo >&2 "ERROR: fleet start failed with: $?"; exit 1; }
  done
else
    echo "ERROR: No unit files found for application '$APP_NAME'"
fi

# Navigate back to the working dir
popd