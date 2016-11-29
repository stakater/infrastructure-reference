#!/bin/bash
# Create/Update groups in blue green deployment
#----------------------------------------------
# Argument1: APP_NAME
# Argument2: AMI_ID
# Argument3: AWS_REGION
# Argument4: DEPLOY_INSTANCE_TYPE
# Argument5: DEPLOY_STATE_KEY
#----------------------------------------------

# Get parameter values
APP_NAME=$1
AMI_ID=$2
AWS_REGION=$3
DEPLOY_INSTANCE_TYPE=$4
DEPLOY_STATE_KEY=$5
ENABLE_SSL=$6
INTERNAL_SUPPORT=$7

CLUSTER_MIN_SIZE=1
CLUSTER_MAX_SIZE=5
CLUSTER_DESIRED_SIZE=$CLUSTER_MIN_SIZE
MIN_ELB_CAPACITY=1
ACTIVE_LOAD_BALANCER=${APP_NAME//_/\-}-prod-elb-active
TEST_LOAD_BALANCER=${APP_NAME//_/\-}-prod-elb-test

##############################################################
#################
# Prod Params
#################
ARE_PROD_PARAMS_EMPTY=false;
PROD_PARAMS_FILE="/gocd-data/scripts/prod.parameters.txt"
# Check prod params file exist
if [ ! -f ${PROD_PARAMS_FILE} ];
then
   echo "Error: [Deploy-to-AMI] Prod parameters file not found";
   exit 1;
fi;

# Read parameter values from file
TF_STATE_BUCKET_NAME=`/gocd-data/scripts/read-parameter.sh ${PROD_PARAMS_FILE} TF_STATE_BUCKET_NAME`
TF_GLOBAL_ADMIRAL_STATE_KEY=`/gocd-data/scripts/read-parameter.sh ${PROD_PARAMS_FILE} TF_GLOBAL_ADMIRAL_STATE_KEY`
TF_PROD_STATE_KEY=`/gocd-data/scripts/read-parameter.sh ${PROD_PARAMS_FILE} TF_PROD_STATE_KEY`

# Check parameter values not empty
if test -z ${TF_STATE_BUCKET_NAME};
then
   echo "Error: Value for TF_STATE_BUCKET_NAME not defined.";
   ARE_PROD_PARAMS_EMPTY=true;
fi;

if test -z ${TF_GLOBAL_ADMIRAL_STATE_KEY};
then
   echo "Error: Value for TF_GLOBAL_ADMIRAL_STATE_KEY not defined.";
   ARE_PROD_PARAMS_EMPTY=true;
fi;

if test -z ${TF_PROD_STATE_KEY};
then
   echo "Error: Value for TF_PROD_STATE_KEY not defined.";
   ARE_PROD_PARAMS_EMPTY=true;
fi;

# Check ami params not empty
if $ARE_PROD_PARAMS_EMPTY;
then
    echo "ERROR: Invalid PROD parameters.";
    exit 1;
fi;

## Get deployment state values
DEPLOYMENT_STATE_FILE_PATH="/app/${APP_NAME}/cd/blue-green-deployment"
DEPLOYMENT_STATE_FILE_NAME="${APP_NAME}_deployment_state.txt"
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
echo "TF_PROD_STATE_KEY: ${TF_PROD_STATE_KEY}"
echo "ENABLE_SSL: ${ENABLE_SSL}"
echo "INTERNAL_SUPPORT: ${INTERNAL_SUPPORT}"
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
/gocd-data/scripts/write-terraform-variables.sh ${APP_NAME} ${AWS_REGION} ${TF_STATE_BUCKET_NAME} ${TF_PROD_STATE_KEY} ${TF_GLOBAL_ADMIRAL_STATE_KEY} ${DEPLOY_INSTANCE_TYPE} ${BLUE_GROUP_AMI_ID} ${BLUE_CLUSTER_MIN_SIZE} ${BLUE_CLUSTER_MAX_SIZE} ${BLUE_CLUSTER_DESIRED_SIZE} ${BLUE_GROUP_LOAD_BALANCERS} ${BLUE_GROUP_MIN_ELB_CAPACITY} ${GREEN_GROUP_AMI_ID} ${GREEN_CLUSTER_MIN_SIZE} ${GREEN_CLUSTER_MAX_SIZE} ${GREEN_CLUSTER_DESIRED_SIZE} ${GREEN_GROUP_LOAD_BALANCERS} ${GREEN_GROUP_MIN_ELB_CAPACITY} ${ENABLE_SSL} ${INTERNAL_SUPPORT}

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
   /gocd-data/scripts/update-deployment-state.sh ${APP_NAME} ${LIVE_GROUP} ${AMI_ID} null true true false
elif [ $LIVE_GROUP == "blue" ]
then
   /gocd-data/scripts/update-deployment-state.sh ${APP_NAME} ${LIVE_GROUP} ${BLUE_GROUP_AMI_ID} ${AMI_ID} true true false
elif [ $LIVE_GROUP == "green" ]
then
   /gocd-data/scripts/update-deployment-state.sh ${APP_NAME} ${LIVE_GROUP} ${AMI_ID} ${GREEN_GROUP_AMI_ID} true true false
fi;
