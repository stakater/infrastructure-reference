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


# Write terraform variables to .tfvars file
#-----------------------------------------------------

# Input parameters
APP_NAME=$1
ENVIRONMENT=$2
AWS_REGION=$3
TF_STATE_BUCKET_NAME=$4
ENV_STATE_KEY=$5
TF_GLOBAL_ADMIRAL_STATE_KEY=$6
DEPLOY_INSTANCE_TYPE=$7
BLUE_GROUP_AMI_ID=$8
BLUE_CLUSTER_MIN_SIZE=$9
BLUE_CLUSTER_MAX_SIZE=${10}
BLUE_CLUSTER_DESIRED_SIZE=${11}
BLUE_GROUP_LOAD_BALANCERS=${12}
BLUE_GROUP_MIN_ELB_CAPACITY=${13}
GREEN_GROUP_AMI_ID=${14}
GREEN_CLUSTER_MIN_SIZE=${15}
GREEN_CLUSTER_MAX_SIZE=${16}
GREEN_CLUSTER_DESIRED_SIZE=${17}
GREEN_GROUP_LOAD_BALANCERS=${18}
GREEN_GROUP_MIN_ELB_CAPACITY=${19}
ENABLE_SSL=${20}
INTERNAL_SUPPORT=${21}

# file path
deployCodeLocation="/app/stakater/prod-deployment-reference-${APP_NAME}-${ENVIRONMENT}"
terraformFolderPath="${deployCodeLocation}/deploy-prod/.terraform/"
tfvarsFile="${terraformFolderPath}/deploy.tfvars"

# Check if production deployment code exists
/gocd-data/scripts/clone-deployment-application-code.sh ${deployCodeLocation}

# Check if .terraform folder exists
if [ ! -d "${terraformFolderPath}" ];
then
  sudo mkdir -p ${terraformFolderPath}
fi;

# If enable_ssl is set, set the value in tfvars to 1 (as used by terraform)
# And fetch ssl certificate id from cert-arn file
ENABLE_SSL_CONVERTED_VALUE=0;
SSL_CERTIFICATE_ID=""
if [[ "${ENABLE_SSL}" == "true" || "${ENABLE_SSL}" == "1" ]];
then
  ENABLE_SSL_CONVERTED_VALUE=1;
  CRT_PARAM_FILE="/app/certs/cert-arn.txt"
  SSL_CERTIFICATE_ID=`/gocd-data/scripts/read-parameter.sh ${CRT_PARAM_FILE} ssl_certificate_id`
fi;

# Write vars to be used by the deploy code in a TF vars file
sudo sh -c "{
  echo \"app_name = \\\"${APP_NAME}\\\"
  environment = \\\"${ENVIRONMENT}\\\"
  aws_region = \\\"${AWS_REGION}\\\"
  tf_state_bucket_name = \\\"${TF_STATE_BUCKET_NAME}\\\"
  env_state_key = \\\"${ENV_STATE_KEY}\\\"
  global_admiral_state_key = \\\"${TF_GLOBAL_ADMIRAL_STATE_KEY}\\\"
  instance_type = \\\"${DEPLOY_INSTANCE_TYPE}\\\"
  ami_blue_group = \\\"${BLUE_GROUP_AMI_ID}\\\"
  blue_cluster_min_size = \\\"${BLUE_CLUSTER_MIN_SIZE}\\\"
  blue_cluster_max_size = \\\"${BLUE_CLUSTER_MAX_SIZE}\\\"
  blue_cluster_desired_size = \\\"${BLUE_CLUSTER_DESIRED_SIZE}\\\"
  blue_group_load_balancers = \\\"${BLUE_GROUP_LOAD_BALANCERS}\\\"
  blue_group_min_elb_capacity = \\\"${BLUE_GROUP_MIN_ELB_CAPACITY}\\\"
  ami_green_group = \\\"${GREEN_GROUP_AMI_ID}\\\"
  green_cluster_min_size = \\\"${GREEN_CLUSTER_MIN_SIZE}\\\"
  green_cluster_max_size = \\\"${GREEN_CLUSTER_MAX_SIZE}\\\"
  green_cluster_desired_size = \\\"${GREEN_CLUSTER_DESIRED_SIZE}\\\"
  green_group_load_balancers = \\\"${GREEN_GROUP_LOAD_BALANCERS}\\\"
  green_group_min_elb_capacity = \\\"${GREEN_GROUP_MIN_ELB_CAPACITY}\\\"
  enable_ssl = \\\"${ENABLE_SSL_CONVERTED_VALUE}\\\"
  ssl_certificate_id = \\\"${SSL_CERTIFICATE_ID}\\\"
  internal_support = \\\"${INTERNAL_SUPPORT}\\\"
\"
} > ${tfvarsFile}"
