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


# Update deployment state for blue/green deployment
#--------------------------------------------------
# Argument1: APP_NAME
# Argument2: ENVIRONMENT
# Argument3: LIVE_GROUP
# Argument4: BLUE_GROUP_AMI_ID
# Argument5: GREEN_GROUP_AMI_ID
# Argument6: IS_DEPLOYMENT_ROLLBACK_VALID
# Argument7: IS_GROUP_SWITCH_VALID
# Argument8: SWITCHED_TO_NEW_GROUP
#--------------------------------------------------

# Get parameter values
APP_NAME=$1
ENVIRONMENT=$2
LIVE_GROUP=$3
BLUE_GROUP_AMI_ID=$4
GREEN_GROUP_AMI_ID=$5
IS_DEPLOYMENT_ROLLBACK_VALID=$6
IS_GROUP_SWITCH_VALID=$7
SWITCHED_TO_NEW_GROUP=$8

DEPLOYMENT_STATE_FILE_PATH="/app/${APP_NAME}/${ENVIRONMENT}/cd/blue-green-deployment"
DEPLOYMENT_STATE_FILE_NAME="${APP_NAME}_${ENVIRONMENT}_deployment_state.txt"
DEPLOYMENT_STATE_FILE="${DEPLOYMENT_STATE_FILE_PATH}/${DEPLOYMENT_STATE_FILE_NAME}"

# Create directory if it does npt exists
if [ ! -d "$DEPLOYMENT_STATE_FILE_PATH" ];
then
sudo mkdir -p ${DEPLOYMENT_STATE_FILE_PATH}
fi;

# Write deployment state to file 
sudo sh -c "{
  echo "LIVE_GROUP=${LIVE_GROUP}"
  echo "BLUE_GROUP_AMI_ID=${BLUE_GROUP_AMI_ID}"
  echo "GREEN_GROUP_AMI_ID=${GREEN_GROUP_AMI_ID}"
  echo "IS_DEPLOYMENT_ROLLBACK_VALID=${IS_DEPLOYMENT_ROLLBACK_VALID}"
  echo "IS_GROUP_SWITCH_VALID=${IS_GROUP_SWITCH_VALID}"
  echo "SWITCHED_TO_NEW_GROUP=${SWITCHED_TO_NEW_GROUP}"
} > ${DEPLOYMENT_STATE_FILE}"
