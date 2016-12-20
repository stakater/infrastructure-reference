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


# Create/Update groups in blue green deployment
#----------------------------------------------
# Argument1: APP_NAME
# Argument2: ENVIRONMENT
# Argument3: AMI_ID
# Argument4: AWS_REGION
# Argument5: DEPLOY_INSTANCE_TYPE
# Argument6: DEPLOY_STATE_KEY
# Argument7: SSL_CERTIFICATE_ARN
# Argument8: IS_ELB_INTERNAL
# Argument9: ENV_STATE_KEY
#----------------------------------------------

# Get parameter values
APP_NAME=$1
ENVIRONMENT=$2
AMI_ID=$3
AWS_REGION=$4
DEPLOY_INSTANCE_TYPE=$5
DEPLOY_STATE_KEY=$6
SSL_CERTIFICATE_ARN=$7
IS_ELB_INTERNAL=$8
ENV_STATE_KEY=$9

CLUSTER_MIN_SIZE=1
CLUSTER_MAX_SIZE=5
CLUSTER_DESIRED_SIZE=$CLUSTER_MIN_SIZE
MIN_ELB_CAPACITY=1
ACTIVE_LOAD_BALANCER=${APP_NAME//_/\-}-${ENVIRONMENT//_/\-}-elb-active
TEST_LOAD_BALANCER=${APP_NAME//_/\-}-${ENVIRONMENT//_/\-}-elb-test

##############################################################
#################
# Prod Params
#################
ARE_BG_PARAMS_EMPTY=false;
BG_PARAMS_FILE="/gocd-data/scripts/bg.parameters.txt"
# Check prod params file exist
if [ ! -f ${BG_PARAMS_FILE} ];
then
   echo "Error: [Deploy-to-AMI] bg parameters file not found";
   exit 1;
fi;

# Read parameter values from file
TF_STATE_BUCKET_NAME=`/gocd-data/scripts/read-parameter.sh ${BG_PARAMS_FILE} TF_STATE_BUCKET_NAME`
TF_GLOBAL_ADMIRAL_STATE_KEY=`/gocd-data/scripts/read-parameter.sh ${BG_PARAMS_FILE} TF_GLOBAL_ADMIRAL_STATE_KEY`

# Check parameter values not empty
if test -z ${TF_STATE_BUCKET_NAME};
then
   echo "Error: Value for TF_STATE_BUCKET_NAME not defined.";
   ARE_BG_PARAMS_EMPTY=true;
fi;

if test -z ${TF_GLOBAL_ADMIRAL_STATE_KEY};
then
   echo "Error: Value for TF_GLOBAL_ADMIRAL_STATE_KEY not defined.";
   ARE_BG_PARAMS_EMPTY=true;
fi;

if test -z ${ENV_STATE_KEY};
then
   echo "Error: Value for ENV_STATE_KEY not defined.";
   ARE_BG_PARAMS_EMPTY=true;
fi;

# Check ami params not empty
if $ARE_BG_PARAMS_EMPTY;
then
    echo "ERROR: Invalid PROD parameters.";
    exit 1;
fi;

## Get deployment state values
DEPLOYMENT_STATE_FILE_PATH="/app/${APP_NAME}/${ENVIRONMENT}/cd/blue-green-deployment"
DEPLOYMENT_STATE_FILE_NAME="${APP_NAME}_${ENVIRONMENT}_deployment_state.txt"
DEPLOYMENT_STATE_FILE="${DEPLOYMENT_STATE_FILE_PATH}/${DEPLOYMENT_STATE_FILE_NAME}"
# Read parameters from file
LIVE_GROUP=`/gocd-data/scripts/read-parameter.sh ${DEPLOYMENT_STATE_FILE} LIVE_GROUP`
BLUE_GROUP_AMI_ID=`/gocd-data/scripts/read-parameter.sh ${DEPLOYMENT_STATE_FILE} BLUE_GROUP_AMI_ID`
GREEN_GROUP_AMI_ID=`/gocd-data/scripts/read-parameter.sh ${DEPLOYMENT_STATE_FILE} GREEN_GROUP_AMI_ID`
##############################################################

# Output values
echo "###################################################"
echo "APP_NAME: ${APP_NAME}"
echo "AMI_ID: ${AMI_ID}"
echo "AWS_REGION: ${AWS_REGION}"
echo "LIVE_GROUP: ${LIVE_GROUP}"
echo "BLUE_GROUP_AMI_ID: ${BLUE_GROUP_AMI_ID}"
echo "GREEN_GROUP_AMI_ID: ${GREEN_GROUP_AMI_ID}"
echo "DEPLOYMENT_STATE_FILE: ${DEPLOYMENT_STATE_FILE_PATH}/${DEPLOYMENT_STATE_FILE_NAME}"
echo "DEPLOY_INSTANCE_TYPE: ${DEPLOY_INSTANCE_TYPE}"
echo "TF_STATE_BUCKET_NAME: ${TF_STATE_BUCKET_NAME}"
echo "TF_GLOBAL_ADMIRAL_STATE_KEY: ${TF_GLOBAL_ADMIRAL_STATE_KEY}"
echo "ENV_STATE_KEY: ${ENV_STATE_KEY}"
echo "SSL_CERTIFICATE_ARN: ${SSL_CERTIFICATE_ARN}"
echo "IS_ELB_INTERNAL: ${IS_ELB_INTERNAL}"
echo "###################################################"

if [ $LIVE_GROUP == "null" ]
then
   echo "NO LIVE GROUP: UPDATING BLUE GROUP"

   # First deployment. Create blue group
   BLUE_CLUSTER_MIN_SIZE=${CLUSTER_MIN_SIZE}
   BLUE_CLUSTER_MAX_SIZE=${CLUSTER_MAX_SIZE}
   BLUE_CLUSTER_DESIRED_SIZE=${CLUSTER_DESIRED_SIZE}
   BLUE_GROUP_AMI_ID=${AMI_ID}
   BLUE_GROUP_LOAD_BALANCERS=${TEST_LOAD_BALANCER}
   BLUE_GROUP_MIN_ELB_CAPACITY=${MIN_ELB_CAPACITY}

   GREEN_CLUSTER_MIN_SIZE=0
   GREEN_CLUSTER_MAX_SIZE=0
   GREEN_CLUSTER_DESIRED_SIZE=0
   GREEN_GROUP_AMI_ID=${AMI_ID}
   GREEN_GROUP_LOAD_BALANCERS=${TEST_LOAD_BALANCER}
   GREEN_GROUP_MIN_ELB_CAPACITY=0
elif [ $LIVE_GROUP == "blue" ]
then
   echo "LIVE GROUP BLUE: UPDATING GREEN GROUP"

   # Update GREEN group for new deployment
   BLUE_CLUSTER_MIN_SIZE=${CLUSTER_MIN_SIZE}
   BLUE_CLUSTER_MAX_SIZE=${CLUSTER_MAX_SIZE}
   BLUE_CLUSTER_DESIRED_SIZE=${CLUSTER_DESIRED_SIZE}
   BLUE_GROUP_AMI_ID=${BLUE_GROUP_AMI_ID}
   BLUE_GROUP_LOAD_BALANCERS=${ACTIVE_LOAD_BALANCER}\
   BLUE_GROUP_MIN_ELB_CAPACITY=${MIN_ELB_CAPACITY}

   GREEN_CLUSTER_MIN_SIZE=${CLUSTER_MIN_SIZE}
   GREEN_CLUSTER_MAX_SIZE=${CLUSTER_MAX_SIZE}
   GREEN_CLUSTER_DESIRED_SIZE=${CLUSTER_DESIRED_SIZE}
   GREEN_GROUP_AMI_ID=${AMI_ID}
   GREEN_GROUP_LOAD_BALANCERS=${TEST_LOAD_BALANCER}
   GREEN_GROUP_MIN_ELB_CAPACITY=${MIN_ELB_CAPACITY}
elif [ $LIVE_GROUP == "green" ]
then
   echo "LIVE GROUP GREEN: UPDATING BLUE GROUP"

   # Update BLUE group for new deployment
   BLUE_CLUSTER_MIN_SIZE=${CLUSTER_MIN_SIZE}
   BLUE_CLUSTER_MAX_SIZE=${CLUSTER_MAX_SIZE}
   BLUE_CLUSTER_DESIRED_SIZE=${CLUSTER_DESIRED_SIZE}
   BLUE_GROUP_AMI_ID=${AMI_ID}
   BLUE_GROUP_LOAD_BALANCERS=${TEST_LOAD_BALANCER}
   BLUE_GROUP_MIN_ELB_CAPACITY=${MIN_ELB_CAPACITY}

   GREEN_CLUSTER_MIN_SIZE=${CLUSTER_MIN_SIZE}
   GREEN_CLUSTER_MAX_SIZE=${CLUSTER_MAX_SIZE}
   GREEN_CLUSTER_DESIRED_SIZE=${CLUSTER_DESIRED_SIZE}
   GREEN_GROUP_AMI_ID=${GREEN_GROUP_AMI_ID}
   GREEN_GROUP_LOAD_BALANCERS=${ACTIVE_LOAD_BALANCER}
   GREEN_GROUP_MIN_ELB_CAPACITY=${MIN_ELB_CAPACITY}
fi;

## Output deployment parameters decided
echo "#######################################################################"
echo "BLUE_CLUSTER_MIN_SIZE: ${BLUE_CLUSTER_MIN_SIZE}"
echo "BLUE_CLUSTER_MAX_SIZE: ${BLUE_CLUSTER_MAX_SIZE}"
echo "BLUE_CLUSTER_DESIRED_SIZE: ${BLUE_CLUSTER_DESIRED_SIZE}"
echo "GREEN_CLUSTER_MIN_SIZE: ${GREEN_CLUSTER_MIN_SIZE}"
echo "GREEN_CLUSTER_MAX_SIZE: ${GREEN_CLUSTER_MAX_SIZE}"
echo "GREEN_CLUSTER_DESIRED_SIZE: ${GREEN_CLUSTER_DESIRED_SIZE}"
echo "BLUE_GROUP_AMI_ID: ${BLUE_GROUP_AMI_ID}"
echo "GREEN_GROUP_AMI_ID: ${GREEN_GROUP_AMI_ID}"
echo "BLUE_GROUP_LOAD_BALANCERS: ${BLUE_GROUP_LOAD_BALANCERS}"
echo "GREEN_GROUP_LOAD_BALANCERS: ${GREEN_GROUP_LOAD_BALANCERS}"
echo "BLUE_GROUP_MIN_ELB_CAPACITY: ${BLUE_GROUP_MIN_ELB_CAPACITY}"
echo "GREEN_GROUP_MIN_ELB_CAPACITY: ${GREEN_GROUP_MIN_ELB_CAPACITY}"
echo "#######################################################################"

## Automated Deployment
# Write terraform variables to .tfvars file
/gocd-data/scripts/write-terraform-variables.sh ${APP_NAME} ${ENVIRONMENT} ${AWS_REGION} ${TF_STATE_BUCKET_NAME} ${ENV_STATE_KEY} ${TF_GLOBAL_ADMIRAL_STATE_KEY} ${DEPLOY_INSTANCE_TYPE} ${BLUE_GROUP_AMI_ID} ${BLUE_CLUSTER_MIN_SIZE} ${BLUE_CLUSTER_MAX_SIZE} ${BLUE_CLUSTER_DESIRED_SIZE} ${BLUE_GROUP_LOAD_BALANCERS} ${BLUE_GROUP_MIN_ELB_CAPACITY} ${GREEN_GROUP_AMI_ID} ${GREEN_CLUSTER_MIN_SIZE} ${GREEN_CLUSTER_MAX_SIZE} ${GREEN_CLUSTER_DESIRED_SIZE} ${GREEN_GROUP_LOAD_BALANCERS} ${GREEN_GROUP_MIN_ELB_CAPACITY} "${SSL_CERTIFICATE_ARN}" ${IS_ELB_INTERNAL}

# Apply terraform changes
/gocd-data/scripts/terraform-apply-changes.sh ${APP_NAME} ${ENVIRONMENT} ${TF_STATE_BUCKET_NAME} ${DEPLOY_STATE_KEY} ${AWS_REGION}
# Check status and fail pipeline if exit code 1 (error while applying changes)
APPLY_CHANGES_STATUS=$?
if [ ${APPLY_CHANGES_STATUS} = 1 ];
then
    exit 1;
fi;

## Update deployment state file
if [ $LIVE_GROUP == "null" ]
then
   /gocd-data/scripts/update-deployment-state.sh ${APP_NAME} ${ENVIRONMENT} ${LIVE_GROUP} ${AMI_ID} null true true false
elif [ $LIVE_GROUP == "blue" ]
then
   /gocd-data/scripts/update-deployment-state.sh ${APP_NAME} ${ENVIRONMENT} ${LIVE_GROUP} ${BLUE_GROUP_AMI_ID} ${AMI_ID} true true false
elif [ $LIVE_GROUP == "green" ]
then
   /gocd-data/scripts/update-deployment-state.sh ${APP_NAME} ${ENVIRONMENT} ${LIVE_GROUP} ${AMI_ID} ${GREEN_GROUP_AMI_ID} true true false
fi;
