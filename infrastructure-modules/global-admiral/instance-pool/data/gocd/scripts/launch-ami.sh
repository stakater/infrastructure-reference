#!/bin/bash
# This shell script deploys an AMI 
#-----------------------------------------------------
# Argument1: APP_NAME
#-----------------------------------------------------

# Get parameter values
APP_NAME=$1

# Check number of parameters equal 1
if [ "$#" -ne 1 ]; then
    echo "ERROR: [Launch AMI] Illegal number of parameters"
    exit 1
fi

ARE_AMI_PARAMS_EMPTY=false;
AMI_PARAMS_FILE="/app/${APP_NAME}/cd/vars/${APP_NAME}_ami_params.txt"

# Check ami params file exist
if [ ! -f ${AMI_PARAMS_FILE} ];
then
   echo "Error: [Launch AMI] AMI parameters file not found";
   exit 1;
fi;

# Read parameter values from file
AMI_ID=`/gocd-data/scripts/read-parameter.sh ${AMI_PARAMS_FILE} AMI_ID`
VPC_ID=`/gocd-data/scripts/read-parameter.sh ${AMI_PARAMS_FILE} VPC_ID`
SUBNET_ID=`/gocd-data/scripts/read-parameter.sh ${AMI_PARAMS_FILE} SUBNET_ID`
AWS_REGION=`/gocd-data/scripts/read-parameter.sh ${AMI_PARAMS_FILE} AWS_REGION`

# Output values
echo "###################################################"
echo "APP_NAME: ${APP_NAME}"
echo "AMI_ID: ${AMI_ID}"
echo "VPC_ID: ${VPC_ID}"
echo "SUBNET_ID: ${SUBNET_ID}"
echo "AWS_REGION: ${AWS_REGION}"
echo "###################################################"

# Check parameter values not empty
if test -z ${AMI_ID};
then
   echo "Error: Value for AMI ID not defined.";
   ARE_AMI_PARAMS_EMPTY=true;
fi;

if test -z ${VPC_ID};
then
   echo "Error: Value for VPC ID not defined.";
   ARE_AMI_PARAMS_EMPTY=true;
fi;

if test -z ${SUBNET_ID};
then
   echo "Error: Value for SUBNET ID not defined.";
   ARE_AMI_PARAMS_EMPTY=true;
fi;

if test -z ${AWS_REGION};
then
   echo "Error: Value for AWS REGION not defined.";
   ARE_AMI_PARAMS_EMPTY=true;
fi;

# Check ami params not empty
if $ARE_AMI_PARAMS_EMPTY;
then
    echo "ERROR: Invalid AMI parameters.";
    exit 1;
fi;

# Update blue green deployment group
/gocd-data/scripts/update-blue-green-deployment-groups.sh ${APP_NAME} ${AMI_ID} ${VPC_ID} ${SUBNET_ID} ${AWS_REGION}
