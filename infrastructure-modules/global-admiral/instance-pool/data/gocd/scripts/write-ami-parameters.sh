#!/bin/bash
# This shell script writes parameters of ami to file used to launch ami 
#----------------------------------------------------------------------
# Argument1: APP_NAME
# Argument2: AMI_ID
# Argument3: VPC_ID
# Argument4: SUBNET_ID
# Argument5: AWS_REGION
#----------------------------------------------------------------------

# Inout parameters
APP_NAME=$1
AMI_ID=$2
VPC_ID=$3
SUBNET_ID=$4
AWS_REGION=$5

OUTPUT_FILE_PATH="/app/${APP_NAME}/cd/vars"
OUTPUT_FILE_NAME="${APP_NAME}_ami_params.txt"

# Check number of parameters equal 5
if [ "$#" -ne 5 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

# Create directory to write file
sudo mkdir -p ${OUTPUT_FILE_PATH}

sudo sh -c "{
  echo "APP_NAME=${APP_NAME}"
  echo "AMI_ID=${AMI_ID}"
  echo "VPC_ID=${VPC_ID}"
  echo "SUBNET_ID=${SUBNET_ID}"
  echo "AWS_REGION=${AWS_REGION}"
} > ${OUTPUT_FILE_PATH}/${OUTPUT_FILE_NAME}"
