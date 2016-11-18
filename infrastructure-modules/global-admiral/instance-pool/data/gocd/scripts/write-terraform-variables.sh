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
BLUE_GROUP_LOAD_BALANCERS=${10}
BLUE_GROUP_MIN_ELB_CAPACITY=${11}
GREEN_GROUP_AMI_ID=${12}
GREEN_CLUSTER_MIN_SIZE=${13}
GREEN_CLUSTER_MAX_SIZE=${14}
GREEN_GROUP_LOAD_BALANCERS=${15}
GREEN_GROUP_MIN_ELB_CAPACITY=${16}
ENABLE_SSL=${17}
INTERNAL_SUPPORT=${18}

# file path
deployCodeLocation="/app/stakater/prod-deployment-reference-${APP_NAME}"
terraformFolderPath="${deployCodeLocation}/deploy-prod/.terraform/"
tfvarsFile="${terraformFolderPath}/deploy.tfvars"

# Check if production deployment code exists
/gocd-data/scripts/clone-deployment-application-code.sh ${APP_NAME}

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
  aws_region = \\\"${AWS_REGION}\\\"
  tf_state_bucket_name = \\\"${TF_STATE_BUCKET_NAME}\\\"
  prod_state_key = \\\"${TF_PROD_STATE_KEY}\\\"
  global_admiral_state_key = \\\"${TF_GLOBAL_ADMIRAL_STATE_KEY}\\\"
  instance_type = \\\"${DEPLOY_INSTANCE_TYPE}\\\"
  ami_blue_group = \\\"${BLUE_GROUP_AMI_ID}\\\"
  blue_cluster_min_size = \\\"${BLUE_CLUSTER_MIN_SIZE}\\\"
  blue_cluster_max_size = \\\"${BLUE_CLUSTER_MAX_SIZE}\\\"
  blue_group_load_balancers = \\\"${BLUE_GROUP_LOAD_BALANCERS}\\\"
  blue_group_min_elb_capacity = \\\"${BLUE_GROUP_MIN_ELB_CAPACITY}\\\"
  ami_green_group = \\\"${GREEN_GROUP_AMI_ID}\\\"
  green_cluster_min_size = \\\"${GREEN_CLUSTER_MIN_SIZE}\\\"
  green_cluster_max_size = \\\"${GREEN_CLUSTER_MAX_SIZE}\\\"
  green_group_load_balancers = \\\"${GREEN_GROUP_LOAD_BALANCERS}\\\"
  green_group_min_elb_capacity = \\\"${GREEN_GROUP_MIN_ELB_CAPACITY}\\\"
  enable_ssl = \\\"${ENABLE_SSL_CONVERTED_VALUE}\\\"
  ssl_certificate_id = \\\"${SSL_CERTIFICATE_ID}\\\"
  internal_support = \\\"${INTERNAL_SUPPORT}\\\"
\"
} > ${tfvarsFile}"
