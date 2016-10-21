#!/bin/bash
# Applies terraform changes
#---------------------------------
# Argument1: APP_NAME
# Argument2: TF_STATE_BUCKET_NAME
# Argument3: DEPLOY_STATE_KEY
# Argument4: AWS_REGION
#--------------------------------

APP_NAME=$1
TF_STATE_BUCKET_NAME=$2
DEPLOY_STATE_KEY=$3
AWS_REGION=$4

# Clone deployment code
deployCodeLocation="/app/stakater/prod-deployment-reference-${APP_NAME}"
tfvarsFile="${deployCodeLocation}/deploy-prod/.terraform/deploy.tfvars"

if [ ! -d "${deployCodeLocation}" ];
then
  sudo mkdir -p ${deployCodeLocation}
fi;
if [ ! "$(ls -A ${deployCodeLocation})" ];
then
  sudo git clone https://github.com/stakater/prod-deployment-reference.git ${deployCodeLocation};
fi;

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
sudo /opt/terraform/terraform plan -var-file="${tfvarsFile}"
sudo /opt/terraform/terraform apply -var-file="${tfvarsFile}"
