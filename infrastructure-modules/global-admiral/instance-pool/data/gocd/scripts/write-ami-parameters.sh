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


# This shell script writes parameters of ami to file used to launch ami 
#----------------------------------------------------------------------
# Argument1: APP_NAME
# Argument2: ENVIRONMENT
# Argument3: AMI_ID
# Argument4: VPC_ID
# Argument5: SUBNET_ID
# Argument6: AWS_REGION
#----------------------------------------------------------------------

# Inout parameters
APP_NAME=$1
ENVIRONMENT=$2
AMI_ID=$3
VPC_ID=$4
SUBNET_I=$5
AWS_REGION=$6

OUTPUT_FILE_PATH="/app/${ENVIRONMENT}_${APP_NAME}/cd/vars"
OUTPUT_FILE_NAME="${ENVIRONMENT}_${APP_NAME}_ami_params.txt"

# Check number of parameters equal 5
if [ "$#" -ne 6 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

# Create directory to write file
sudo mkdir -p ${OUTPUT_FILE_PATH}

sudo sh -c "{
  echo "APP_NAME=${APP_NAME}"
  echo "ENVIRONMENT=${ENVIRONMENT}"
  echo "AMI_ID=${AMI_ID}"
  echo "VPC_ID=${VPC_ID}"
  echo "SUBNET_ID=${SUBNET_ID}"
  echo "AWS_REGION=${AWS_REGION}"
} > ${OUTPUT_FILE_PATH}/${OUTPUT_FILE_NAME}"
