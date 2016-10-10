#! /bin/bash
AWS_REGION=""
DEPLOY_STATE_KEY=""
APP_NAME=""
DEPLOY_INSTANCE_TYPE="t2.medium" # default value

kOptionFlag=false;
rOptionFlag=false;
aOptionFlag=false;
# Get options from the command line
while getopts ":k:r:a:i:" OPTION
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
          APP_NAME=$OPTARG
          ;;
        i)
          DEPLOY_INSTANCE_TYPE=$OPTARG
          ;;
        *)
          echo "Usage: $(basename $0) -k <key for the state file> -r <aws-region> -a <app-name> -i <deploy instance type>"
          exit 0
          ;;
    esac
done

if ! $kOptionFlag || ! $rOptionFlag || ! $aOptionFlag;
then
  echo "Usage: $(basename $0) -k <key for the state file> -r <aws-region> -a <app-name> -i <deploy instance type>"
  exit 0;
fi

##################
# AMI Params
##################
AMI_PARAMS_FILE="/app/${APP_NAME}/cd/vars/${APP_NAME}_ami_params.txt"
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
##############################################

#################
# Prod Params
#################
ARE_PROD_PARAMS_EMPTY=false;
PROD_PARAMS_FILE="/gocd-data/scripts/prod.parameters.txt"
# Check prod params file exist
if [ ! -f ${PROD_PARAMS_FILE} ];
then
   echo "Error: [Deploy-to-AMI] Prod parameters file not found";
   exit 1;
fi;

# Read parameter values from file
TF_STATE_BUCKET_NAME=`/gocd-data/scripts/read-parameter.sh ${PROD_PARAMS_FILE} TF_STATE_BUCKET_NAME`
TF_GLOBAL_ADMIRAL_STATE_KEY=`/gocd-data/scripts/read-parameter.sh ${PROD_PARAMS_FILE} TF_GLOBAL_ADMIRAL_STATE_KEY`
TF_PROD_STATE_KEY=`/gocd-data/scripts/read-parameter.sh ${PROD_PARAMS_FILE} TF_PROD_STATE_KEY`

# Check parameter values not empty
if test -z ${TF_STATE_BUCKET_NAME};
then
   echo "Error: Value for TF_STATE_BUCKET_NAME not defined.";
   ARE_PROD_PARAMS_EMPTY=true;
fi;

if test -z ${TF_GLOBAL_ADMIRAL_STATE_KEY};
then
   echo "Error: Value for TF_GLOBAL_ADMIRAL_STATE_KEY not defined.";
   ARE_PROD_PARAMS_EMPTY=true;
fi;

if test -z ${TF_PROD_STATE_KEY};
then
   echo "Error: Value for TF_PROD_STATE_KEY not defined.";
   ARE_PROD_PARAMS_EMPTY=true;
fi;

# Check ami params not empty
if $ARE_PROD_PARAMS_EMPTY;
then
    echo "ERROR: Invalid PROD parameters.";
    exit 1;
fi;
###############################################

# Clone deployment code
deployCodeLocation="/app/stakater/prod-deployment-reference"
if [ ! -d "${deployCodeLocation}" ];
then
  sudo mkdir -p ${deployCodeLocation}
fi;
if [ ! "$(ls -A ${deployCodeLocation})" ];
then
  sudo git clone https://github.com/stakater/prod-deployment-reference.git ${deployCodeLocation};
fi;

cd ${deployCodeLocation}

# Enable remote config
sudo /opt/terraform/terraform remote config \
  -backend S3 \
  -backend-config="bucket=$TF_STATE_BUCKET_NAME" \
  -backend-config="key=$DEPLOY_STATE_KEY" \
  -backend-config="region=$AWS_REGION";

cd ${deployCodeLocation}/deploy-prod

# Write vars to be used by the deploy code in a TF vars file
tfvarsFile="${deployCodeLocation}/.terraform/deploy.tfvars"
sudo sh -c "{
  echo \"aws_region = \\\"${AWS_REGION}\\\"
  tf_state_bucket_name = \\\"${TF_STATE_BUCKET_NAME}\\\"
  prod_state_key = \\\"${TF_PROD_STATE_KEY}\\\"
  global_admiral_state_key = \\\"${TF_GLOBAL_ADMIRAL_STATE_KEY}\\\"
  prod_ami = \\\"${AMI_ID}\\\"
  instance_type = \\\"${DEPLOY_INSTANCE_TYPE}\\\"
  app_name = \\\"${APP_NAME}\\\" \"
} > ${tfvarsFile}"

sudo /opt/terraform/terraform get -update

# Create keypair before deploy-prod module is created
sudo /opt/terraform/terraform plan -var-file="${tfvarsFile}" -target null_resource.create-key-pair
sudo /opt/terraform/terraform apply -var-file="${tfvarsFile}" -target null_resource.create-key-pair

# Create rest of the resources
sudo /opt/terraform/terraform plan -var-file="${tfvarsFile}"
sudo /opt/terraform/terraform apply -var-file="${tfvarsFile}"