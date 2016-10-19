#!/bin/bash
# Write terraform variables to .tfvars file
#-----------------------------------------------------

# Input parameters
APP_NAME=$1
AWS_REGION=$2
TF_STATE_BUCKET_NAME=$3
TF_PROD_STATE_KEY=$4
TF_GLOBAL_ADMIRAL_STATE_KEY=$5
DEPLOY_INSTANCE_TYPE=$6
BLUE_GROUP_AMI_ID=$7
BLUE_CLUSTER_MIN_SIZE=$8
BLUE_CLUSTER_MAX_SIZE=$9
GREEN_GROUP_AMI_ID=${10}
GREEN_CLUSTER_MIN_SIZE=${11}
GREEN_CLUSTER_MAX_SIZE=${12}


# file path
deployCodeLocation="/app/stakater/prod-deployment-reference"
tfvarsFile="${deployCodeLocation}/deploy-prod/.terraform/deploy.tfvars"

# Write vars to be used by the deploy code in a TF vars file
sudo sh -c "{
  echo \"app_name = \\\"${APP_NAME}\\\"
  aws_region = \\\"${AWS_REGION}\\\"
  tf_state_bucket_name = \\\"${TF_STATE_BUCKET_NAME}\\\"
  prod_state_key = \\\"${TF_PROD_STATE_KEY}\\\"
  global_admiral_state_key = \\\"${TF_GLOBAL_ADMIRAL_STATE_KEY}\\\"
  instance_type = \\\"${DEPLOY_INSTANCE_TYPE}\\\"
  ami_blue_group = \\\"${BLUE_GROUP_AMI_ID}\\\"
  blue_cluster_min_size = \\\"${BLUE_CLUSTER_MIN_SIZE}\\\"
  blue_cluster_max_size = \\\"${BLUE_CLUSTER_MAX_SIZE}\\\"
  ami_green_group = \\\"${GREEN_GROUP_AMI_ID}\\\"
  green_cluster_min_size = \\\"${GREEN_CLUSTER_MIN_SIZE}\\\"
  green_cluster_max_size = \\\"${GREEN_CLUSTER_MAX_SIZE}\\\"  \"
} > ${tfvarsFile}"


