#!/bin/bash
# Update deployment state for blue/green deployment
#--------------------------------------------------
# Argument1: APP_NAME
# Argument2: LIVE_GROUP
# Argument3: BLUE_GROUP_AMI_ID
# Argument4: GREEN_GROUP_AMI_ID
# Argument5: IS_DEPLOYMENT_ROLLBACK_VALID
# Argument6: IS_GROUP_SWITCH_VALID
#--------------------------------------------------

# Get parameter values
APP_NAME=$1
LIVE_GROUP=$2
BLUE_GROUP_AMI_ID=$3
GREEN_GROUP_AMI_ID=$4
IS_DEPLOYMENT_ROLLBACK_VALID=$5
IS_GROUP_SWITCH_VALID=$6

DEPLOYMENT_STATE_FILE_PATH="/app/${APP_NAME}/cd/blue-green-deployment"
DEPLOYMENT_STATE_FILE_NAME="${APP_NAME}_deployment_state.txt"
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
} > ${DEPLOYMENT_STATE_FILE}"
