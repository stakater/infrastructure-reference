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


# This shell script deletes Amazon Machine Images (AMI)
#-----------------------------------------------------
# Argument1: APP_NAME
# Argument2: ENVIRONMENT
#-----------------------------------------------------

APP_NAME=""
ENVIRONMENT=""

aOptionFlag=true;
eOptionFlag=true;
# Get options from the command line
while getopts ":a:e:" OPTION
do
    case $OPTION in
        a)
          aOptionFlag=false
          APP_NAME=$OPTARG
          ;;
        e)
          eOptionFlag=false
          ENVIRONMENT=$OPTARG
          ;;
        *)
          echo "Usage: $(basename $0) -a <APP NAME> -e <ENVIRONMENT>"
          exit 0
          ;;
    esac
done

if $aOptionFlag || $eOptionFlag ; then
  echo "Usage: $(basename $0) -a <APP NAME> -e <ENVIRONMENT>"
  exit 0;
fi

region=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
region=${region::-1}

## Get Blue Green AMIs
DEPLOYMENT_STATE_FILE_PATH="/app/${APP_NAME}/${ENVIRONMENT}/cd/blue-green-deployment"
DEPLOYMENT_STATE_FILE_NAME="${APP_NAME}_${ENVIRONMENT}_deployment_state.txt"
DEPLOYMENT_STATE_FILE="${DEPLOYMENT_STATE_FILE_PATH}/${DEPLOYMENT_STATE_FILE_NAME}"
blueGroupAmi="'`/gocd-data/scripts/read-parameter.sh ${DEPLOYMENT_STATE_FILE} BLUE_GROUP_AMI_ID`'"
greenGroupAmi="'`/gocd-data/scripts/read-parameter.sh ${DEPLOYMENT_STATE_FILE} GREEN_GROUP_AMI_ID`'"

## GET Latest AMI
OUTPUT_FILE_PATH="/app/${APP_NAME}/${ENVIRONMENT}/cd/vars"
OUTPUT_FILE_NAME="${APP_NAME}_${ENVIRONMENT}_ami_params.txt"
OUTPUT_STATE_FILE="${OUTPUT_FILE_PATH}/${OUTPUT_FILE_NAME}"

latestAmi="'`/gocd-data/scripts/read-parameter.sh ${OUTPUT_STATE_FILE} AMI_ID`'"

requiredAmis="["$blueGroupAmi","$greenGroupAmi","$latestAmi"]"
echo "These AMIs will not be deleted "${requiredAmis}

query="Images[?!contains(${requiredAmis},ImageId)].{id:ImageId,tag:Tags[?Key=='BuildUUID'].Value|[0]}"
filter="Name=name,Values=${APP_NAME}_${ENVIRONMENT}*"


data=`aws ec2 describe-images --filters $filter --query $query --region $region`

length=`echo $data | jq '.| length'`
length=$(($length-1))

for i in $(seq 0 1 $length); do
   ami=`echo $data | jq ".[${i}].id"`
   ami=${ami//\"/}
   tag=`echo $data | jq ".[${i}].tag"`
   echo "deleting AMI $ami"
   aws ec2 deregister-image --image-id $ami --region $region
   filter="Name=tag:BuildUUID,Values=$tag"
   snapshots=(`aws ec2 describe-snapshots --filters $filter --query 'Snapshots[].SnapshotId' --region $region --output text`)
   for snapshot in ${snapshots[@]}; do
      snapshot=${snapshot//\"/}
      echo "deleting snapshot $snapshot"
      aws ec2 delete-snapshot --snapshot-id $snapshot --region $region
   done
done