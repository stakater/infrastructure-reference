#!/usr/bin/env bash

# Default Environment variables
COREOS_UPDATE_CHANNEL=${COREOS_UPDATE_CHANNEL}        # stable/beta/alpha
VM_TYPE=${VM_TYPE}                                        # hvm/pv - note: t1.micro supports only pv type

AWS_PROFILE=${AWS_PROFILE}
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
AWS_REGION=$($DIR/read-cfg.sh $HOME/.aws/config "profile $AWS_PROFILE" region)

TF_STATE_BUCKET_NAME=${TF_STATE_BUCKET_NAME}
TF_STATE_GLOBAL_ADMIRAL_KEY=${TF_STATE_GLOBAL_ADMIRAL_KEY}
TF_STATE_DEV_KEY=${TF_STATE_DEV_KEY}
TF_STATE_QA_KEY=${TF_STATE_QA_KEY}
TF_STATE_PROD_KEY=${TF_STATE_PROD_KEY}
TF_STATE_STAGE_KEY=${TF_STATE_STAGE_KEY}

PROD_CLOUDINIT_BUCKET_NAME=${PROD_CLOUDINIT_BUCKET_NAME}
PROD_CONFIG_BUCKET_NAME=${PROD_CONFIG_BUCKET_NAME}

STAGE_CLOUDINIT_BUCKET_NAME=${STAGE_CLOUDINIT_BUCKET_NAME}
STAGE_CONFIG_BUCKET_NAME=${STAGE_CONFIG_BUCKET_NAME}

# Database properties
DEV_DATABASE_USERNAME=${DEV_DATABASE_USERNAME}
DEV_DATABASE_PASSWORD=${DEV_DATABASE_PASSWORD}
DEV_DATABASE_NAME=${DEV_DATABASE_NAME}
QA_DATABASE_USERNAME=${QA_DATABASE_USERNAME}
QA_DATABASE_PASSWORD=${QA_DATABASE_PASSWORD}
QA_DATABASE_NAME=${QA_DATABASE_NAME}
PROD_DATABASE_USERNAME=${PROD_DATABASE_USERNAME}
PROD_DATABASE_PASSWORD=${PROD_DATABASE_PASSWORD}
PROD_DATABASE_NAME=${PROD_DATABASE_NAME}
STAGE_DATABASE_USERNAME=${STAGE_DATABASE_USERNAME}
STAGE_DATABASE_PASSWORD=${STAGE_DATABASE_PASSWORD}
STAGE_DATABASE_NAME=${STAGE_DATABASE_NAME}
# Get options from the command line
while getopts ":c:z:t:" OPTION
do
    case $OPTION in
        c)
          COREOS_UPDATE_CHANNEL=$OPTARG
          ;;
        z)
          AWS_REGION=$OPTARG
          ;;
        t)
          VM_TYPE=$OPTARG
          ;;
        *)
          echo "Usage: $(basename $0) -c <stable|beta|alpha> -z <aws zone> -t <hvm|pv>"
          exit 0
          ;;
    esac
done

#########################
# Preprossessing for terraform variable
# for current region's availability zones
#########################
#Fetch Availability Zones availble for current profile (i.e. account and region)
az_result=$(aws ec2 describe-availability-zones --output text --profile ${AWS_PROFILE} --query "AvailabilityZones[].ZoneName");
# Converting array in the format: "us-east-1a","us-east-1c","us-east-1d"
az_array=(${az_result//'\n'/})
array_length="${#az_array[@]}"
tf_avail_zones=""
for i in "${!az_array[@]}"; do
 tf_avail_zones="${tf_avail_zones} \"${az_array[$i]}\""

 if [[ $i -lt $((array_length - 1)) ]]
 then
   tf_avail_zones="${tf_avail_zones},"
 fi
done
####################
####################


# Get the AMI id
# core-os
url=`printf "http://%s.release.core-os.net/amd64-usr/current/coreos_production_ami_%s_%s.txt" $COREOS_UPDATE_CHANNEL $VM_TYPE $AWS_REGION`
# ubuntu
bastion_host_ami_id=$($DIR/get-ubuntu-ami-id.sh -r $AWS_REGION);

cat <<EOF
# Generated by scripts/get-vars.sh
variable "ami" { default = "`curl -s $url`" }
variable "bastion_host_ami_id" { default = "${bastion_host_ami_id}" }
variable "availability_zones" { default = [${tf_avail_zones} ] }
variable "tf_state_bucket_name" { default = "${TF_STATE_BUCKET_NAME}" }
variable "tf_state_global_admiral_key" { default = "${TF_STATE_GLOBAL_ADMIRAL_KEY}" }
variable "tf_state_dev_key" { default = "${TF_STATE_DEV_KEY}" }
variable "tf_state_qa_key" { default = "${TF_STATE_QA_KEY}" }
variable "tf_state_prod_key" { default = "${TF_STATE_PROD_KEY}" }
variable "prod_cloudinit_bucket_name" { default = "${PROD_CLOUDINIT_BUCKET_NAME}" }
variable "prod_config_bucket_name" { default = "${PROD_CONFIG_BUCKET_NAME}" }
variable "tf_state_stage_key" { default = "${TF_STATE_STAGE_KEY}" }
variable "stage_cloudinit_bucket_name" { default = "${STAGE_CLOUDINIT_BUCKET_NAME}" }
variable "stage_config_bucket_name" { default = "${STAGE_CONFIG_BUCKET_NAME}" }
variable "dev_database_username" { default= "${DEV_DATABASE_USERNAME}" }
variable "dev_database_password" { default= "${DEV_DATABASE_PASSWORD}" }
variable "dev_database_name" { default= "${DEV_DATABASE_NAME}" }
variable "qa_database_username" { default= "${QA_DATABASE_USERNAME}" }
variable "qa_database_password" { default= "${QA_DATABASE_PASSWORD}" }
variable "qa_database_name" { default= "${QA_DATABASE_NAME}" }
variable "prod_database_username" { default= "${PROD_DATABASE_USERNAME}" }
variable "prod_database_password" { default= "${PROD_DATABASE_PASSWORD}" }
variable "prod_database_name" { default= "${PROD_DATABASE_NAME}" }
variable "stage_database_username" { default= "${STAGE_DATABASE_USERNAME}" }
variable "stage_database_password" { default= "${STAGE_DATABASE_PASSWORD}" }
variable "stage_database_name" { default= "${STAGE_DATABASE_NAME}" }
EOF