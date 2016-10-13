#!/bin/bash
# Switch between blue and green deployment groups
#------------------------------------------------
# Argument1: APP_NAME
#------------------------------------------------

# Input parameters 
APP_NAME=$1

AMI_PARAMS_FILE="/app/${APP_NAME}/cd/vars/${APP_NAME}_ami_params.txt"
# Check ami params file exist
if [ ! -f ${AMI_PARAMS_FILE} ];
then
   echo "Error: [Launch AMI] AMI parameters file not found";
   exit 1;
fi;
# Read parameter values from file
VPC_ID=`/gocd-data/scripts/read-parameter.sh ${AMI_PARAMS_FILE} VPC_ID`
SUBNET_ID=`/gocd-data/scripts/read-parameter.sh ${AMI_PARAMS_FILE} SUBNET_ID`
AWS_REGION=`/gocd-data/scripts/read-parameter.sh ${AMI_PARAMS_FILE} AWS_REGION`

DEPLOYMENT_STATE_FILE_PATH="/app/${APP_NAME}/cd/blue-green-deployment"
DEPLOYMENT_STATE_FILE_NAME="${APP_NAME}_deployment_state.txt"
DEPLOYMENT_STATE_FILE="${DEPLOYMENT_STATE_FILE_PATH}/${DEPLOYMENT_STATE_FILE_NAME}"

# Get deployment state values
LIVE_GROUP=`/gocd-data/scripts/read-parameter.sh ${DEPLOYMENT_STATE_FILE} LIVE_GROUP`
BLUE_GROUP_AMI_ID=`/gocd-data/scripts/read-parameter.sh ${DEPLOYMENT_STATE_FILE} BLUE_GROUP_AMI_ID`
GREEN_GROUP_AMI_ID=`/gocd-data/scripts/read-parameter.sh ${DEPLOYMENT_STATE_FILE} GREEN_GROUP_AMI_ID`
IS_GROUP_SWITCH_VALID=`/gocd-data/scripts/read-parameter.sh ${DEPLOYMENT_STATE_FILE} IS_GROUP_SWITCH_VALID`

## Exit if group switch is not valid
if ! $IS_GROUP_SWITCH_VALID;
then
   echo "ERROR [switch-deployment-group]: Cannot switch group. Invalid groups"
   exit 1
fi;

CLUSTER_MIN_SIZE=1
CLUSTER_MAX_SIZE=1
MIN_ELB_CAPACITY=1

## Switch group
if [ $LIVE_GROUP == "null" ]
then
   echo "NO LIVE GROUP BUT SWITCH TO BLUE GROUP VALID: SWITCH TO BLUE GROUP"

   BLUE_CLUSTER_MIN_SIZE=${CLUSTER_MIN_SIZE}
   BLUE_CLUSTER_MAX_SIZE=${CLUSTER_MAX_SIZE}
   BLUE_MIN_ELB_CAPACITY=${MIN_ELB_CAPACITY}
   BLUE_GROUP_AMI_ID=${BLUE_GROUP_AMI_ID}

   GREEN_CLUSTER_MIN_SIZE=0
   GREEN_CLUSTER_MAX_SIZE=0
   GREEN_MIN_ELB_CAPACITY=0
   GREEN_GROUP_AMI_ID=${GREEN_GROUP_AMI_ID}

elif [ $LIVE_GROUP == "blue" ]
then
   echo "LIVE GROUP BLUE: SWITCH TO GREEN GROUP"

   # Terminate all instances of blue group
   BLUE_CLUSTER_MIN_SIZE=0
   BLUE_CLUSTER_MAX_SIZE=0
   BLUE_MIN_ELB_CAPACITY=0
   BLUE_GROUP_AMI_ID=${BLUE_GROUP_AMI_ID}

   GREEN_CLUSTER_MIN_SIZE=${CLUSTER_MIN_SIZE}
   GREEN_CLUSTER_MAX_SIZE=${CLUSTER_MAX_SIZE}
   GREEN_MIN_ELB_CAPACITY=${MIN_ELB_CAPACITY}
   GREEN_GROUP_AMI_ID=${GREEN_GROUP_AMI_ID}   
elif [ $LIVE_GROUP == "green" ]
then
   echo "LIVE GROUP GREEN: SWITCH TO BLUE GROUP"

   # Terminate all instances of green group
   BLUE_CLUSTER_MIN_SIZE=${CLUSTER_MIN_SIZE}
   BLUE_CLUSTER_MAX_SIZE=${CLUSTER_MAX_SIZE}
   BLUE_MIN_ELB_CAPACITY=${MIN_ELB_CAPACITY}
   BLUE_GROUP_AMI_ID=${BLUE_GROUP_AMI_ID}

   GREEN_CLUSTER_MIN_SIZE=0
   GREEN_CLUSTER_MAX_SIZE=0
   GREEN_MIN_ELB_CAPACITY=0
   GREEN_GROUP_AMI_ID=${GREEN_GROUP_AMI_ID}
fi;


## Apply changes required
cd ~/terraform-aws-asg/examples/standard/;
sudo /opt/terraform/terraform get -update .;

sudo /opt/terraform/terraform apply -var-file=./terraform.tfvars -var ami_blue_group=${BLUE_GROUP_AMI_ID} -var ami_green_group=${GREEN_GROUP_AMI_ID} -var vpc_id=${VPC_ID} -var subnet_ids=${SUBNET_ID} -var region=${AWS_REGION} -var green_cluster_min_size=\"${GREEN_CLUSTER_MIN_SIZE}\" -var green_cluster_max_size=\"${GREEN_CLUSTER_MAX_SIZE}\" -var blue_cluster_min_size=\"${BLUE_CLUSTER_MIN_SIZE}\" -var blue_cluster_max_size=\"${BLUE_CLUSTER_MAX_SIZE}\" -var blue_min_elb_capacity=\"${BLUE_MIN_ELB_CAPACITY}\" -var green_min_elb_capacity=\"${GREEN_MIN_ELB_CAPACITY}\";

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
