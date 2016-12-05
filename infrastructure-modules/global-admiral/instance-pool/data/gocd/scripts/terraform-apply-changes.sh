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


# Applies terraform changes
#---------------------------------
# Argument1: APP_NAME
# Argument2: ENVIRONMENT
# Argument3: TF_STATE_BUCKET_NAME
# Argument4: DEPLOY_STATE_KEY
# Argument5: AWS_REGION
#--------------------------------

APP_NAME=$1
ENVIRONMENT=$2
TF_STATE_BUCKET_NAME=$3
DEPLOY_STATE_KEY=$4
AWS_REGION=$5

# Clone deployment code
deployCodeLocation="/app/stakater/prod-deployment-reference-${APP_NAME}-${ENVIRONMENT}"
tfvarsFile="${deployCodeLocation}/deploy-prod/.terraform/deploy.tfvars"

/gocd-data/scripts/clone-deployment-application-code.sh ${APP_NAME} ${ENVIRONMENT}

cd ${deployCodeLocation}
sudo git pull origin master

cd ${deployCodeLocation}/deploy-prod

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
