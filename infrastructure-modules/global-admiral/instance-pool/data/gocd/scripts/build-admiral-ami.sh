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
# Deploy to Admiral via AMI
# This script creates AMI for infrastructure apps and then deploys that AMI
# Authors: Hazim
###############################################################################

#Comma separated list of app names
APP_NAMES_LIST=""
# 'stage' or 'prod'
ENV=""
CLOUDINIT_S3_FULL_PATH=""
VERSION=""
BAKER_INSTANCE_TYPE=""

DATA_EBS_DEVICE_NAME=""
DATA_EBS_VOL_SIZE=""
LOGS_EBS_DEVICE_NAME=""
LOGS_EBS_VOL_SIZE=""

GOCD_PARAMS_FILE="/gocd-data/scripts/gocd.parameters.txt"

aOptionFlag=false
rOptionFlag=false
vOptionFlag=false
while getopts ":a:r:b:c:v:i:e:z:l:x" OPTION
do
    case $OPTION in
        a)
          if [ ! -z "$OPTARG" ]; then aOptionFlag=true; fi #if not empty string, then set flag true
          APP_NAMES_LIST=$OPTARG;
          # Convert APP_NAMES_LIST value to lowercase
          APP_NAMES_LIST=`echo "$APP_NAMES_LIST" | sed 's/./\L&/g'`
          ;;
        r)
          if [ ! -z "$OPTARG" ]; then rOptionFlag=true; fi #if not empty string, then set flag true
          ENV=$OPTARG;
          # Convert ENV value to lowercase
          ENV=`echo "$ENV" | sed 's/./\L&/g'`
          if [[ "$ENV" != "stage" && "$ENV" != "prod" ]]; then
            echo "ERROR: Unknown value for ENV, please enter one of 'stage' or 'prod'";
            exit 1;
          fi
          ;;
        b)
          CONFIG_BUCKET_NAME=$OPTARG;
          ;;
        c)
          CLOUDINIT_S3_FULL_PATH=$OPTARG; #optional
          ;;
        v)
          if [ ! -z "$OPTARG" ]; then vOptionFlag=true; fi #if not empty string, then set flag true
          VERSION=$OPTARG
          ;;
        i)
          BAKER_INSTANCE_TYPE="$OPTARG"
          ;;
        e)
          DATA_EBS_DEVICE_NAME=$OPTARG
          ;;
        z)
          DATA_EBS_VOL_SIZE=$OPTARG
          ;;
        l)
          LOGS_EBS_DEVICE_NAME=$OPTARG
          ;;
        x)
          LOGS_EBS_VOL_SIZE=$OPTARG
          ;;
        *)
          echo "Usage: $(basename $0) -a <APP NAMES LIST> (Comma separated list) \
                                      -r <ENVIRONMENT> \
                                      -b <Config bucket name> \
                                      -c <Full path (incl bucket name) of cloud config file> (optional) \
                                      -v <version> \
                                      -i <Baker instance type> (optional)
                                      -e <EBS data volume device name> \
                                      -z <EBS data volume device size> \
                                      -l <EBS logs volume device name> \
                                      -x <EBS logs volume size>";
          exit 1
          ;;
    esac
done

if ! $aOptionFlag || ! $rOptionFlag  || ! $vOptionFlag;
then
    echo "Usage: $(basename $0) -a <APP NAMES LIST> (Comma separated list) \
                              -r <ENVIRONMENT> \
                              -b <Config bucket name> \
                              -c <Full path (incl bucket name) of cloud config file> (optional) \
                              -v <version> \
                              -i <Baker instance type> (optional)
                              -e <EBS data volume device name> \
                              -z <EBS data volume device size> \
                              -l <EBS logs volume device name> \
                              -x <EBS logs volume size>";
    exit 1;
fi

# If bucket name is not specified as opts, read from config file
if [ -z "$CONFIG_BUCKET_NAME" ];
then
  if [ "$ENV" == "stage" ]
  then
    CONFIG_BUCKET_NAME=`/gocd-data/scripts/read-parameter.sh ${GOCD_PARAMS_FILE} STAGE_CONFIG_BUCKET_NAME`
  elif [ "$ENV" == "prod" ]
  then
    CONFIG_BUCKET_NAME=$`/gocd-data/scripts/read-parameter.sh ${GOCD_PARAMS_FILE} PROD_CONFIG_BUCKET_NAME`
  fi
  # if still no value
  if [ -z "$CONFIG_BUCKET_NAME" ]; then echo "ERROR: Could not read value for CONFIG_BUCKET_NAME"; exit 1; fi
fi

# Parse comma separated list into an array
IFS=',' read -ra APP_NAMES <<< "$APP_NAMES_LIST"
# Sort APP_NAMES array in alphabetical order, so that order does not matter when maintaining directories, states etc
SORTED_APP_NAMES=( $(for arr in "${APP_NAMES[@]}"
do
        echo $arr
done | sort) );

# join alphabetically ordered app names by '-'
JOINED_APP_NAMES=$(IFS=- ; echo "${SORTED_APP_NAMES[*]}");

ADMIRAL_DATA_LOCATION="/app/stakater/admiral-${ENV}"
sudo mkdir -p $ADMIRAL_DATA_LOCATION;

COMBINED_UNITS="";
for app in "${APP_NAMES[@]}"; do
    echo "APP_NAME: ${app}"
    # If directory with app name exists in the current working dir
    if [ ! -d ${app} ];
    then
      echo "ERROR: The given repo does not contian a folder for the app: $app";
      exit 1;
    fi

    # Navigate to the app directory
    pushd ${app}

    # If the app folder contains .service files
    UNIT_FILES=(`find ./ -maxdepth 1 -name "*.service"`)
    if [ ${#UNIT_FILES[@]} -gt 0 ];
    then
      # Upload all sub-directories, in the app directory, to S3
      for subdirectory in */; do
        # Make sure if result is a dir not a symlink
        if [[ -d $subdirectory ]]; then
          aws s3 cp --recursive "${subdirectory}" "s3://${CONFIG_BUCKET_NAME}/admiral/${app}/${subdirectory}"  || { echo >&2 "ERROR: aws s3 cp failed with: $?"; exit 1; }
        fi
      done

      unit_file_no=1;
      # Concat all .service files in the app directory, to the cloud-config file of the AMI to be baked
      for unit_file in "${UNIT_FILES[@]}";
      do
        # remove first two characters from unit file var i.e. './'
        unit_file_name="${unit_file:2}"
        #If more than one unit files for app, append number to unit file name
        if [ $unit_file_no -gt 1 ]; then unit_file_name="${unit_file_name%.*}${unit_file_no}.service"; fi

        # Append spaces before each line of unit_file
        SPACES="        ";
        unit_data=$(sed -e "s/^/${SPACES}/" $unit_file)

        # Combine files as a cloud-config
        COMBINED_UNITS="${COMBINED_UNITS}
    - name: ${unit_file_name}
      command: start
      enabled: true
      content: |
${unit_data}
      "
      unit_file_no=$((unit_file_no + 1))
      done
    else
        echo "ERROR: No unit files found for application '$app'"
    fi
    # Navigate back to the working dir
    popd
done

# Output values
echo "#######################################################################"
echo JOINED_APP_NAMES: ${JOINED_APP_NAMES}
echo ENV: ${ENV}
echo CLOUDINIT_S3_FULL_PATH: ${CLOUDINIT_S3_FULL_PATH}
echo VERSION: ${VERSION}
echo DATA_EBS_DEVICE_NAME: ${DATA_EBS_DEVICE_NAME}
echo DATA_EBS_VOL_SIZE: ${DATA_EBS_VOL_SIZE}
echo LOGS_EBS_DEVICE_NAME: ${LOGS_EBS_DEVICE_NAME}
echo LOGS_EBS_VOL_SIZE: ${LOGS_EBS_VOL_SIZE}
echo "########################################################################"

/gocd-data/scripts/build-ami.sh -a "${JOINED_APP_NAMES}" \
                                -r "${ENV}" \
                                -b "${VERSION}" \
                                -u $(uuid -v4) \
                                -i "${BAKER_INSTANCE_TYPE}" \
                                -y "${COMBINED_UNITS}" \
                                -o "" \
                                -c "${CLOUDINIT_S3_FULL_PATH}" \
                                -e "${DATA_EBS_DEVICE_NAME}" \
                                -z "${DATA_EBS_VOL_SIZE}" \
                                -l "${LOGS_EBS_DEVICE_NAME}" \
                                -x "${LOGS_EBS_VOL_SIZE}";