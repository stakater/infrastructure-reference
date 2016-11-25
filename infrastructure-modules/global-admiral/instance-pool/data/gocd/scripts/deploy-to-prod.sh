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


AWS_REGION=""
DEPLOY_STATE_KEY=""
APP_NAME=""
DEPLOY_INSTANCE_TYPE="t2.nano" # default value
ENABLE_SSL=false;
INTERNAL_SUPPORT=false;

kOptionFlag=false;
rOptionFlag=false;
aOptionFlag=false;
# Get options from the command line
while getopts ":k:r:a:i:s:t:" OPTION
do
    case $OPTION in
        k)
          DEPLOY_STATE_KEY=$OPTARG
          kOptionFlag=true;
          ;;
        r)
          rOptionFlag=true;
          AWS_REGION=$OPTARG
          ;;
        a)
          aOptionFlag=true;
          APP_NAME=$OPTARG
          ;;
        i)
          DEPLOY_INSTANCE_TYPE=$OPTARG
          ;;
        s)
          ENABLE_SSL=$OPTARG
          ;;
        t)
          INTERNAL_SUPPORT=$OPTARG
          ;;
        *)
          echo "Usage: $(basename $0) -k <key for the state file> -r <aws-region> -a <app-name> -i <deploy instance type> -s <Enable SSL ? > (optional) -t <INTERNAL SUPPORT ? > (optional)"
          exit 0
          ;;
    esac
done

if ! $kOptionFlag || ! $rOptionFlag || ! $aOptionFlag;
then
  echo "Usage: $(basename $0) -k <key for the state file> -r <aws-region> -a <app-name> -i <deploy instance type> -s <Enable SSL ? > (optional) -t <INTERNAL SUPPORT ? > (optional)"
  exit 0;
fi

##################
# AMI Params
##################
AMI_PARAMS_FILE="/app/${APP_NAME}/cd/vars/${APP_NAME}_ami_params.txt"
# Check ami params file exist
if [ ! -f ${AMI_PARAMS_FILE} ];
then
   echo "Error: [Deploy-to-AMI] AMI parameters file not found";
   exit 1;
fi;

# Read parameter values from file
AMI_ID=`/gocd-data/scripts/read-parameter.sh ${AMI_PARAMS_FILE} AMI_ID`
# Check parameter values not empty
if test -z ${AMI_ID};
then
   echo "Error: Value for AMI ID not defined.";
   exit 1;
fi;
##############################################

# Update blue green deployment group
/gocd-data/scripts/update-blue-green-deployment-groups.sh ${APP_NAME} ${AMI_ID} ${AWS_REGION} ${DEPLOY_INSTANCE_TYPE} ${DEPLOY_STATE_KEY} ${ENABLE_SSL} ${INTERNAL_SUPPORT}

