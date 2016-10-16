#!/bin/bash
# Switch between blue and green deployment groups
#------------------------------------------------
# Argument1: APP_NAME
#------------------------------------------------

# Input parameters 
APP_NAME=$1


##############################################################
## Get AWS Region
AMI_PARAMS_FILE="/app/${APP_NAME}/cd/vars/${APP_NAME}_ami_params.txt"
# Check ami params file exist
if [ ! -f ${AMI_PARAMS_FILE} ];
then
   echo "Error: [Launch AMI] AMI parameters file not found";
   exit 1;
fi;
# Read parameter values from file
AWS_REGION=`/gocd-data/scripts/read-parameter.sh ${AMI_PARAMS_FILE} AWS_REGION`

## Get prod parameters 
PROD_PARAMS_FILE="/app/stakater/prod-deployment-reference/deploy-prod/.terraform/deploy.tfvars"
# Check prod params file exist
if [ ! -f ${PROD_PARAMS_FILE} ];
then
   echo "Error: [rollback-deployment] Prod parameters file not found";
   exit 1;
fi;
# Read parameter values from file
TF_STATE_BUCKET_NAME=`/gocd-data/scripts/read-parameter.sh ${PROD_PARAMS_FILE} tf_state_bucket_name`
TF_GLOBAL_ADMIRAL_STATE_KEY=`/gocd-data/scripts/read-parameter.sh ${PROD_PARAMS_FILE} global_admiral_state_key`
TF_PROD_STATE_KEY=`/gocd-data/scripts/read-parameter.sh ${PROD_PARAMS_FILE} prod_state_key`
DEPLOY_INSTANCE_TYPE=`/gocd-data/scripts/read-parameter.sh ${PROD_PARAMS_FILE} instance_type`
# Remove unwanted characters
TF_STATE_BUCKET_NAME=${TF_STATE_BUCKET_NAME//\"}
TF_GLOBAL_ADMIRAL_STATE_KEY=${TF_GLOBAL_ADMIRAL_STATE_KEY//\"}
TF_PROD_STATE_KEY=${TF_PROD_STATE_KEY//\"}
DEPLOY_INSTANCE_TYPE=${DEPLOY_INSTANCE_TYPE//\"}

## Get deployment state values
DEPLOYMENT_STATE_FILE_PATH="/app/${APP_NAME}/cd/blue-green-deployment"
DEPLOYMENT_STATE_FILE_NAME="${APP_NAME}_deployment_state.txt"
DEPLOYMENT_STATE_FILE="${DEPLOYMENT_STATE_FILE_PATH}/${DEPLOYMENT_STATE_FILE_NAME}"
# Read parameters from file
LIVE_GROUP=`/gocd-data/scripts/read-parameter.sh ${DEPLOYMENT_STATE_FILE} LIVE_GROUP`
BLUE_GROUP_AMI_ID=`/gocd-data/scripts/read-parameter.sh ${DEPLOYMENT_STATE_FILE} BLUE_GROUP_AMI_ID`
GREEN_GROUP_AMI_ID=`/gocd-data/scripts/read-parameter.sh ${DEPLOYMENT_STATE_FILE} GREEN_GROUP_AMI_ID`
IS_GROUP_SWITCH_VALID=`/gocd-data/scripts/read-parameter.sh ${DEPLOYMENT_STATE_FILE} IS_GROUP_SWITCH_VALID`
##############################################################


## Exit if group switch is not valid
if ! $IS_GROUP_SWITCH_VALID;
then
   echo "ERROR [switch-deployment-group]: Cannot switch group. Invalid groups"
   exit 1
fi;

CLUSTER_MIN_SIZE=1
CLUSTER_MAX_SIZE=1

## Switch group
if [ $LIVE_GROUP == "null" ]
then
   echo "NO LIVE GROUP BUT SWITCH TO BLUE GROUP VALID: SWITCH TO BLUE GROUP"

   BLUE_CLUSTER_MIN_SIZE=${CLUSTER_MIN_SIZE}
   BLUE_CLUSTER_MAX_SIZE=${CLUSTER_MAX_SIZE}
   BLUE_GROUP_AMI_ID=${BLUE_GROUP_AMI_ID}

   GREEN_CLUSTER_MIN_SIZE=0
   GREEN_CLUSTER_MAX_SIZE=0
   GREEN_GROUP_AMI_ID=${GREEN_GROUP_AMI_ID}

elif [ $LIVE_GROUP == "blue" ]
then
   echo "LIVE GROUP BLUE: SWITCH TO GREEN GROUP"

   # Terminate all instances of blue group
   BLUE_CLUSTER_MIN_SIZE=0
   BLUE_CLUSTER_MAX_SIZE=0
   BLUE_GROUP_AMI_ID=${BLUE_GROUP_AMI_ID}

   GREEN_CLUSTER_MIN_SIZE=${CLUSTER_MIN_SIZE}
   GREEN_CLUSTER_MAX_SIZE=${CLUSTER_MAX_SIZE}
   GREEN_GROUP_AMI_ID=${GREEN_GROUP_AMI_ID}   
elif [ $LIVE_GROUP == "green" ]
then
   echo "LIVE GROUP GREEN: SWITCH TO BLUE GROUP"

   # Terminate all instances of green group
   BLUE_CLUSTER_MIN_SIZE=${CLUSTER_MIN_SIZE}
   BLUE_CLUSTER_MAX_SIZE=${CLUSTER_MAX_SIZE}
   BLUE_GROUP_AMI_ID=${BLUE_GROUP_AMI_ID}

   GREEN_CLUSTER_MIN_SIZE=0
   GREEN_CLUSTER_MAX_SIZE=0
   GREEN_GROUP_AMI_ID=${GREEN_GROUP_AMI_ID}
fi;


# Write terraform variables to .tfvars file
/gocd-data/scripts/write-terraform-variables.sh ${APP_NAME} ${AWS_REGION} ${TF_STATE_BUCKET_NAME} ${TF_PROD_STATE_KEY} ${TF_GLOBAL_ADMIRAL_STATE_KEY} ${DEPLOY_INSTANCE_TYPE} ${BLUE_GROUP_AMI_ID} ${BLUE_CLUSTER_MIN_SIZE} ${BLUE_CLUSTER_MAX_SIZE} ${GREEN_GROUP_AMI_ID} ${GREEN_CLUSTER_MIN_SIZE} ${GREEN_CLUSTER_MAX_SIZE}

# Apply terraform changes
/gocd-data/scripts/terraform-apply-changes.sh

## Update deployment state file
if [ $LIVE_GROUP == "null" ]
then
   /gocd-data/scripts/update-deployment-state.sh ${APP_NAME} blue ${BLUE_GROUP_AMI_ID} ${GREEN_GROUP_AMI_ID} true false
elif [ $LIVE_GROUP == "blue" ]
then
   /gocd-data/scripts/update-deployment-state.sh ${APP_NAME} green ${BLUE_GROUP_AMI_ID} ${GREEN_GROUP_AMI_ID} true false
elif [ $LIVE_GROUP == "green" ]
then
   /gocd-data/scripts/update-deployment-state.sh ${APP_NAME} blue ${BLUE_GROUP_AMI_ID} ${GREEN_GROUP_AMI_ID} true false
fi;

