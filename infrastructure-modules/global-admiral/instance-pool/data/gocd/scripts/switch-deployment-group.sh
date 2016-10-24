#!/bin/bash
# Switch between blue and green deployment groups
#------------------------------------------------
# Argument1: APP_NAME
# Argument2: AWS_REGION
# Argument3: DEPLOY_STATE_KEY
#------------------------------------------------

# Input parameters 
APP_NAME=$1
AWS_REGION=$2
DEPLOY_STATE_KEY=$3

CLUSTER_MIN_SIZE=1
CLUSTER_MAX_SIZE=1
MIN_ELB_CAPACITY=1
ACTIVE_LOAD_BALANCER=${APP_NAME//_/\-}-prod-elb-active
TEST_LOAD_BALANCER=${APP_NAME//_/\-}-prod-elb-test

##############################################################
## Get prod parameters 
PROD_PARAMS_FILE="/app/stakater/prod-deployment-reference-${APP_NAME}/deploy-prod/.terraform/deploy.tfvars"
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

# Output values
echo "###################################################"
echo "APP_NAME: ${APP_NAME}"
echo "AWS_REGION: ${AWS_REGION}"
echo "LIVE_GROUP: ${LIVE_GROUP}"
echo "BLUE_GROUP_AMI_ID: ${BLUE_GROUP_AMI_ID}"
echo "GREEN_GROUP_AMI_ID: ${GREEN_GROUP_AMI_ID}"
echo "DEPLOYMENT_STATE_FILE: ${DEPLOYMENT_STATE_FILE_PATH}/${DEPLOYMENT_STATE_FILE_NAME}"
echo "DEPLOY_INSTANCE_TYPE: ${DEPLOY_INSTANCE_TYPE}"
echo "TF_STATE_BUCKET_NAME: ${TF_STATE_BUCKET_NAME}"
echo "TF_GLOBAL_ADMIRAL_STATE_KEY: ${TF_GLOBAL_ADMIRAL_STATE_KEY}"
echo "TF_PROD_STATE_KEY: ${TF_PROD_STATE_KEY}"
echo "DEPLOY_STATE_KEY: ${DEPLOY_STATE_KEY}"
echo "###################################################"


## Exit if group switch is not valid
if ! $IS_GROUP_SWITCH_VALID;
then
   echo "ERROR [switch-deployment-group]: Cannot switch group. Invalid groups"
   exit 1
fi;

## Switch group
if [ $LIVE_GROUP == "null" ]
then
   echo "NO LIVE GROUP BUT SWITCH TO BLUE GROUP VALID: SWITCH TO BLUE GROUP"

   BLUE_CLUSTER_MIN_SIZE=${CLUSTER_MIN_SIZE}
   BLUE_CLUSTER_MAX_SIZE=${CLUSTER_MAX_SIZE}
   BLUE_GROUP_AMI_ID=${BLUE_GROUP_AMI_ID}
   BLUE_GROUP_LOAD_BALANCERS=${ACTIVE_LOAD_BALANCER}
   BLUE_GROUP_MIN_ELB_CAPACITY=${MIN_ELB_CAPACITY}

   GREEN_CLUSTER_MIN_SIZE=0
   GREEN_CLUSTER_MAX_SIZE=0
   GREEN_GROUP_AMI_ID=${GREEN_GROUP_AMI_ID}
   GREEN_GROUP_LOAD_BALANCERS=${TEST_LOAD_BALANCER}
   GREEN_GROUP_MIN_ELB_CAPACITY=0

elif [ $LIVE_GROUP == "blue" ]
then
   echo "LIVE GROUP BLUE: SWITCH TO GREEN GROUP"

   # Terminate all instances of blue group
   BLUE_CLUSTER_MIN_SIZE=0
   BLUE_CLUSTER_MAX_SIZE=0
   BLUE_GROUP_AMI_ID=${BLUE_GROUP_AMI_ID}
   BLUE_GROUP_LOAD_BALANCERS=${TEST_LOAD_BALANCER}
   BLUE_GROUP_MIN_ELB_CAPACITY=0

   GREEN_CLUSTER_MIN_SIZE=${CLUSTER_MIN_SIZE}
   GREEN_CLUSTER_MAX_SIZE=${CLUSTER_MAX_SIZE}
   GREEN_GROUP_AMI_ID=${BLUE_GROUP_AMI_ID}
   GREEN_GROUP_LOAD_BALANCERS=${ACTIVE_LOAD_BALANCER}
   GREEN_GROUP_MIN_ELB_CAPACITY=${MIN_ELB_CAPACITY}  
elif [ $LIVE_GROUP == "green" ]
then
   echo "LIVE GROUP GREEN: SWITCH TO BLUE GROUP"

   # Terminate all instances of green group
   BLUE_CLUSTER_MIN_SIZE=${CLUSTER_MIN_SIZE}
   BLUE_CLUSTER_MAX_SIZE=${CLUSTER_MAX_SIZE}
   BLUE_GROUP_AMI_ID=${BLUE_GROUP_AMI_ID}
   BLUE_GROUP_LOAD_BALANCERS=${ACTIVE_LOAD_BALANCER}
   BLUE_GROUP_MIN_ELB_CAPACITY=${MIN_ELB_CAPACITY}

   GREEN_CLUSTER_MIN_SIZE=0
   GREEN_CLUSTER_MAX_SIZE=0
   GREEN_GROUP_AMI_ID=${GREEN_GROUP_AMI_ID}
   GREEN_GROUP_LOAD_BALANCERS=${TEST_LOAD_BALANCER}
   GREEN_GROUP_MIN_ELB_CAPACITY=0
fi;

## Output deployment parameters decided
echo "#######################################################################"
echo "BLUE_CLUSTER_MIN_SIZE: ${BLUE_CLUSTER_MIN_SIZE}"
echo "BLUE_CLUSTER_MAX_SIZE: ${BLUE_CLUSTER_MAX_SIZE}"
echo "GREEN_CLUSTER_MIN_SIZE: ${GREEN_CLUSTER_MIN_SIZE}"
echo "GREEN_CLUSTER_MAX_SIZE: ${GREEN_CLUSTER_MAX_SIZE}"
echo "BLUE_GROUP_AMI_ID: ${BLUE_GROUP_AMI_ID}"
echo "GREEN_GROUP_AMI_ID: ${GREEN_GROUP_AMI_ID}"
echo "BLUE_GROUP_LOAD_BALANCERS: ${BLUE_GROUP_LOAD_BALANCERS}"
echo "GREEN_GROUP_LOAD_BALANCERS: ${GREEN_GROUP_LOAD_BALANCERS}"
echo "BLUE_GROUP_MIN_ELB_CAPACITY: ${BLUE_GROUP_MIN_ELB_CAPACITY}"
echo "GREEN_GROUP_MIN_ELB_CAPACITY: ${GREEN_GROUP_MIN_ELB_CAPACITY}"
echo "#######################################################################"

# Write terraform variables to .tfvars file
/gocd-data/scripts/write-terraform-variables.sh ${APP_NAME} ${AWS_REGION} ${TF_STATE_BUCKET_NAME} ${TF_PROD_STATE_KEY} ${TF_GLOBAL_ADMIRAL_STATE_KEY} ${DEPLOY_INSTANCE_TYPE} ${BLUE_GROUP_AMI_ID} ${BLUE_CLUSTER_MIN_SIZE} ${BLUE_CLUSTER_MAX_SIZE} ${BLUE_GROUP_LOAD_BALANCERS} ${BLUE_GROUP_MIN_ELB_CAPACITY} ${GREEN_GROUP_AMI_ID} ${GREEN_CLUSTER_MIN_SIZE} ${GREEN_CLUSTER_MAX_SIZE} ${GREEN_GROUP_LOAD_BALANCERS} ${GREEN_GROUP_MIN_ELB_CAPACITY}

# Apply terraform changes
/gocd-data/scripts/terraform-apply-changes.sh ${APP_NAME} ${TF_STATE_BUCKET_NAME} ${DEPLOY_STATE_KEY} ${AWS_REGION}
# Check status and fail pipeline if exit code 1 (error while applying changes)
APPLY_CHANGES_STATUS=$?
if [ ${APPLY_CHANGES_STATUS} = 1 ];
then
    exit 1;
fi;

## Update deployment state file
if [ $LIVE_GROUP == "null" ]
then
   /gocd-data/scripts/update-deployment-state.sh ${APP_NAME} blue ${BLUE_GROUP_AMI_ID} null true false
elif [ $LIVE_GROUP == "blue" ]
then
   /gocd-data/scripts/update-deployment-state.sh ${APP_NAME} green ${BLUE_GROUP_AMI_ID} ${GREEN_GROUP_AMI_ID} true false
elif [ $LIVE_GROUP == "green" ]
then
   /gocd-data/scripts/update-deployment-state.sh ${APP_NAME} blue ${BLUE_GROUP_AMI_ID} ${GREEN_GROUP_AMI_ID} true false
fi;

