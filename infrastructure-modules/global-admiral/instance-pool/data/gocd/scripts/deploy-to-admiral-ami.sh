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

AWS_REGION=""
DEPLOY_STATE_KEY=""
APP_NAMES_LIST=""
ENVIRONMENT=""
DEPLOY_INSTANCE_TYPE="t2.nano" # default value
ENV_STATE_KEY=""

kOptionFlag=false;
rOptionFlag=false;
aOptionFlag=false;
eOptionFlag=false;
fOptionFlag=false;
# Get options from the command line
while getopts ":k:r:a:e:f:i:" OPTION
do
    case $OPTION in
        k)
          DEPLOY_STATE_KEY=$OPTARG
          kOptionFlag=true;
          ;;
        r)
          rOptionFlag=true;
          AWS_REGION=$OPTARG
          ;;
        a)
          aOptionFlag=true;
          APP_NAMES_LIST=$OPTARG
          ;;
        e)
          eOptionFlag=true;
          ENVIRONMENT=$OPTARG
          ;;
        f)
          fOptionFlag=true;
          ENV_STATE_KEY=$OPTARG
          ;;
        i)
          DEPLOY_INSTANCE_TYPE=$OPTARG
          ;;
        *)
          echo "Usage: $(basename $0) -k <key for the state file> -r <aws-region> -a <app-names(comma-separated)> -e <environment> -f <tf-state-key> -i <deploy instance type>"
          exit 1
          ;;
    esac
done

if ! $kOptionFlag || ! $rOptionFlag || ! $aOptionFlag || ! $eOptionFlag;
then
  echo "Usage: $(basename $0) -k <key for the state file> -r <aws-region> -a <app-names(comma-separated)> -e <environment> -f <tf-state-key> -i <deploy instance type>"
  exit 1;
fi

# Parse comma separated list into an array and
# join alphabetically ordered app names by '-'
JOINED_APP_NAMES=$(/gocd-data/scripts/sort-and-combine-comma-separated-list.sh ${APP_NAMES_LIST});

####################
# GOCD PARAMS
####################
GOCD_PARAMS_FILE="/gocd-data/scripts/gocd.parameters.txt"
if [ ! -f ${GOCD_PARAMS_FILE} ];
then
   echo "Error: [Deploy-to-AMI] GoCD parameters file not found";
   exit 1;
fi;

# Get parameter values
STACK_NAME=`/gocd-data/scripts/read-parameter.sh ${GOCD_PARAMS_FILE} STACK_NAME`
# Check parameter values not empty
if test -z ${STACK_NAME};
then
   echo "Error: Value for STACK NAME not defined in $GOCD_PARAMS_FILE";
   exit 1;
fi;

##################
# AMI Params
##################
AMI_PARAMS_FILE="/app/${JOINED_APP_NAMES}/${ENVIRONMENT}/cd/vars/${JOINED_APP_NAMES}_${ENVIRONMENT}_ami_params.txt"
# Check ami params file exist
if [ ! -f ${AMI_PARAMS_FILE} ];
then
   echo "Error: [Deploy-to-AMI] AMI parameters file not found";
   exit 1;
fi;

# Read parameter values from file
AMI_ID=`/gocd-data/scripts/read-parameter.sh ${AMI_PARAMS_FILE} AMI_ID`
# Check parameter values not empty
if test -z ${AMI_ID};
then
   echo "Error: Value for AMI ID not defined.";
   exit 1;
fi;

##############################################################
#################
# Prod Params
#################
ARE_BG_PARAMS_EMPTY=false;
BG_PARAMS_FILE="/gocd-data/scripts/bg.parameters.txt"
# Check prod params file exist
if [ ! -f ${BG_PARAMS_FILE} ];
then
   echo "Error: [Deploy-to-AMI] bg parameters file not found";
   exit 1;
fi;

# Read parameter values from file
TF_STATE_BUCKET_NAME=`/gocd-data/scripts/read-parameter.sh ${BG_PARAMS_FILE} TF_STATE_BUCKET_NAME`
TF_GLOBAL_ADMIRAL_STATE_KEY=`/gocd-data/scripts/read-parameter.sh ${BG_PARAMS_FILE} TF_GLOBAL_ADMIRAL_STATE_KEY`

# Check parameter values not empty
if test -z ${TF_STATE_BUCKET_NAME};
then
   echo "Error: Value for TF_STATE_BUCKET_NAME not defined.";
   ARE_BG_PARAMS_EMPTY=true;
fi;

if test -z ${TF_GLOBAL_ADMIRAL_STATE_KEY};
then
   echo "Error: Value for TF_GLOBAL_ADMIRAL_STATE_KEY not defined.";
   ARE_BG_PARAMS_EMPTY=true;
fi;

if test -z ${ENV_STATE_KEY};
then
   echo "Error: Value for ENV_STATE_KEY not defined.";
   ARE_BG_PARAMS_EMPTY=true;
fi;

# Check ami params not empty
if $ARE_BG_PARAMS_EMPTY;
then
    echo "ERROR: Invalid PROD parameters.";
    exit 1;
fi;
##############################################

################################################################
# Clone deploy code
################################################################
# file path
deployCodeLocation="/app/stakater/admiral-deployment-${JOINED_APP_NAMES}-${ENVIRONMENT}"
terraformFolderPath="${deployCodeLocation}/deploy-admiral/.terraform/"
tfvarsFile="${terraformFolderPath}/deploy.tfvars"

# Check if production deployment code exists
if [ ! -d "${deployCodeLocation}" ];
then
  echo "Ceating Directory."
  sudo mkdir -p ${deployCodeLocation}
else
  echo "Directory Already Exists."
fi;

if [ -d ${deployCodeLocation}/.git ]; then
  echo "${deployCodeLocation} is a git repository.";
else
  echo "${deployCodeLocation} is not a git repository. Cloning ...."
  sudo git clone https://github.com/stakater/admiral-deployment.git?ref=v0.1.0 ${deployCodeLocation};
fi;

################################################################
# Write terraform variables file
################################################################

# Check if .terraform folder exists
if [ ! -d "${terraformFolderPath}" ];
then
  sudo mkdir -p ${terraformFolderPath}
fi;

# Write vars to be used by the deploy code in a TF vars file
sudo sh -c "{
  echo \"stack_name = \\\"${STACK_NAME}\\\"
  environment = \\\"${ENVIRONMENT}\\\"
  aws_region = \\\"${AWS_REGION}\\\"
  tf_state_bucket_name = \\\"${TF_STATE_BUCKET_NAME}\\\"
  env_state_key = \\\"${ENV_STATE_KEY}\\\"
  global_admiral_state_key = \\\"${TF_GLOBAL_ADMIRAL_STATE_KEY}\\\"
  instance_type = \\\"${DEPLOY_INSTANCE_TYPE}\\\"
  ami_id = \\\"${AMI_ID}\\\"
\"
} > ${tfvarsFile}"

cd ${deployCodeLocation}
sudo git pull origin master
cd ${deployCodeLocation}/deploy-admiral
################################################################
# Apply Terraform changes
################################################################

# Enable remote config
sudo /opt/terraform/terraform remote config \
  -backend S3 \
  -backend-config="bucket=$TF_STATE_BUCKET_NAME" \
  -backend-config="key=$DEPLOY_STATE_KEY" \
  -backend-config="region=$AWS_REGION";

sudo /opt/terraform/terraform get -update

# Create keypair before deploy-prod module is created
sudo /opt/terraform/terraform plan -var-file="${tfvarsFile}" -target null_resource.create-key-pair
sudo /opt/terraform/terraform apply -var-file="${tfvarsFile}" -target null_resource.create-key-pair

# Create rest of the resources
## Plan terraform changes and terminate if there are errors
if ! sudo /opt/terraform/terraform plan -var-file="${tfvarsFile}"
then
   echo "ERROR: [terraform-apply-changes] Terraform plan failed"
   exit 1
fi;

## Apply terraform changes and terminate if there are errors
if ! sudo /opt/terraform/terraform apply -var-file="${tfvarsFile}"
then
   echo "ERROR: [terraform-apply-changes] Applying terraform changes failed"
   exit 1
fi;