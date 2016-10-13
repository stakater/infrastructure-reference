#!/bin/bash
# Create/Update groups in blue green deployment
#----------------------------------------------
# Argument1: APP_NAME
# Argument2: AMI_ID
# Argument3: VPC_ID
# Argument4: SUBNET_ID
# Argument5: AWS_REGION
#----------------------------------------------

# Get parameter values
APP_NAME=$1
AMI_ID=$2
VPC_ID=$3
SUBNET_ID=$4
AWS_REGION=$5

DEPLOYMENT_STATE_FILE_PATH="/app/${APP_NAME}/cd/blue-green-deployment"
DEPLOYMENT_STATE_FILE_NAME="${APP_NAME}_deployment_state.txt"
DEPLOYMENT_STATE_FILE="${DEPLOYMENT_STATE_FILE_PATH}/${DEPLOYMENT_STATE_FILE_NAME}"

# Get deployment state values
LIVE_GROUP=`/gocd-data/scripts/read-parameter.sh ${DEPLOYMENT_STATE_FILE} LIVE_GROUP`
BLUE_GROUP_AMI_ID=`/gocd-data/scripts/read-parameter.sh ${DEPLOYMENT_STATE_FILE} BLUE_GROUP_AMI_ID`
GREEN_GROUP_AMI_ID=`/gocd-data/scripts/read-parameter.sh ${DEPLOYMENT_STATE_FILE} GREEN_GROUP_AMI_ID`

CLUSTER_MIN_SIZE=1
CLUSTER_MAX_SIZE=1
MIN_ELB_CAPACITY=1

# Output values
echo "###################################################"
echo "APP_NAME: ${APP_NAME}"
echo "AMI_ID: ${AMI_ID}"
echo "VPC_ID: ${VPC_ID}"
echo "SUBNET_ID: ${SUBNET_ID}"
echo "AWS_REGION: ${AWS_REGION}"
echo "LIVE_GROUP: ${LIVE_GROUP}"
echo "BLUE_GROUP_AMI_ID: ${BLUE_GROUP_AMI_ID}"
echo "GREEN_GROUP_AMI_ID: ${GREEN_GROUP_AMI_ID}"
echo "DEPLOYMENT_STATE_FILE: ${DEPLOYMENT_STATE_FILE_PATH}/${DEPLOYMENT_STATE_FILE_NAME}"
echo "###################################################"

if [ $LIVE_GROUP == "null" ]
then
   echo "NO LIVE GROUP: UPDATING BLUE GROUP"
  
   # First deployment. Create blue group
   BLUE_CLUSTER_MIN_SIZE=${CLUSTER_MIN_SIZE}
   BLUE_CLUSTER_MAX_SIZE=${CLUSTER_MAX_SIZE}
   BLUE_MIN_ELB_CAPACITY=${MIN_ELB_CAPACITY}
   BLUE_GROUP_AMI_ID=${AMI_ID}
  
   GREEN_CLUSTER_MIN_SIZE=0
   GREEN_CLUSTER_MAX_SIZE=0
   GREEN_MIN_ELB_CAPACITY=0
   GREEN_GROUP_AMI_ID=${AMI_ID}
elif [ $LIVE_GROUP == "blue" ]
then
   echo "LIVE GROUP BLUE: UPDATING GREEN GROUP"

   # Update GREEN group for new deployment 
   BLUE_CLUSTER_MIN_SIZE=${CLUSTER_MIN_SIZE}
   BLUE_CLUSTER_MAX_SIZE=${CLUSTER_MAX_SIZE}
   BLUE_MIN_ELB_CAPACITY=${MIN_ELB_CAPACITY}
   BLUE_GROUP_AMI_ID=${BLUE_GROUP_AMI_ID}
  
   GREEN_CLUSTER_MIN_SIZE=${CLUSTER_MIN_SIZE}
   GREEN_CLUSTER_MAX_SIZE=${CLUSTER_MAX_SIZE}
   GREEN_MIN_ELB_CAPACITY=${MIN_ELB_CAPACITY}
   GREEN_GROUP_AMI_ID=${AMI_ID}
elif [ $LIVE_GROUP == "green" ]
then
   echo "LIVE GROUP GREEN: UPDATING BLUE GROUP"

   # Update BLUE group for new deployment
   BLUE_CLUSTER_MIN_SIZE=${CLUSTER_MIN_SIZE}
   BLUE_CLUSTER_MAX_SIZE=${CLUSTER_MAX_SIZE}
   BLUE_MIN_ELB_CAPACITY=${MIN_ELB_CAPACITY}
   BLUE_GROUP_AMI_ID=${AMI_ID}

   GREEN_CLUSTER_MIN_SIZE=${CLUSTER_MIN_SIZE}
   GREEN_CLUSTER_MAX_SIZE=${CLUSTER_MAX_SIZE}
   GREEN_MIN_ELB_CAPACITY=${MIN_ELB_CAPACITY}
   GREEN_GROUP_AMI_ID=${GREEN_GROUP_AMI_ID}
fi;

## Output deployment parameters decided
echo "#######################################################################"
echo "BLUE_CLUSTER_MIN_SIZE: ${BLUE_CLUSTER_MIN_SIZE}"
echo "BLUE_CLUSTER_MAX_SIZE: ${BLUE_CLUSTER_MAX_SIZE}"
echo "GREEN_CLUSTER_MIN_SIZE: ${GREEN_CLUSTER_MIN_SIZE}"
echo "GREEN_CLUSTER_MAX_SIZE: ${GREEN_CLUSTER_MAX_SIZE}"
echo "BLUE_GROUP_AMI_ID: ${BLUE_GROUP_AMI_ID}"
echo "GREEN_GROUP_AMI_ID: ${GREEN_GROUP_AMI_ID}"
echo "BLUE_MIN_ELB_CAPACITY: ${BLUE_MIN_ELB_CAPACITY}"
echo "GREEN_MIN_ELB_CAPACITY: ${GREEN_MIN_ELB_CAPACITY}"
echo "#######################################################################"

## Automated Deployment
# Download amd update modules
cd ~/terraform-aws-asg/examples/standard/;
sudo /opt/terraform/terraform get -update .;

# Destroy terraform managed infrastructure
#sudo /opt/terraform/terraform destroy -force -var-file=./terraform.tfvars -var ami_blue_group=${BLUE_GROUP_AMI_ID} -var ami_green_group=${GREEN_GROUP_AMI_ID} -var vpc_id=${VPC_ID} -var subnet_ids=${SUBNET_ID} -var region=${AWS_REGION} -var green_cluster_min_size=\"${GREEN_CLUSTER_MIN_SIZE}\" -var green_cluster_max_size=\"${GREEN_CLUSTER_MAX_SIZE}\" -var blue_cluster_min_size=\"${BLUE_CLUSTER_MIN_SIZE}\" -var blue_cluster_max_size=\"${BLUE_CLUSTER_MAX_SIZE}\" -var blue_min_elb_capacity=\"${BLUE_MIN_ELB_CAPACITY}\" -var green_min_elb_capacity=\"${GREEN_MIN_ELB_CAPACITY}\";

# Create execution plan
sudo /opt/terraform/terraform plan -var-file=./terraform.tfvars -var ami_blue_group=${BLUE_GROUP_AMI_ID} -var ami_green_group=${GREEN_GROUP_AMI_ID} -var vpc_id=${VPC_ID} -var subnet_ids=${SUBNET_ID} -var region=${AWS_REGION} -var green_cluster_min_size=\"${GREEN_CLUSTER_MIN_SIZE}\" -var green_cluster_max_size=\"${GREEN_CLUSTER_MAX_SIZE}\" -var blue_cluster_min_size=\"${BLUE_CLUSTER_MIN_SIZE}\" -var blue_cluster_max_size=\"${BLUE_CLUSTER_MAX_SIZE}\" -var blue_min_elb_capacity=\"${BLUE_MIN_ELB_CAPACITY}\" -var green_min_elb_capacity=\"${GREEN_MIN_ELB_CAPACITY}\";

# Apply changes required
sudo /opt/terraform/terraform apply -var-file=./terraform.tfvars -var ami_blue_group=${BLUE_GROUP_AMI_ID} -var ami_green_group=${GREEN_GROUP_AMI_ID} -var vpc_id=${VPC_ID} -var subnet_ids=${SUBNET_ID} -var region=${AWS_REGION} -var green_cluster_min_size=\"${GREEN_CLUSTER_MIN_SIZE}\" -var green_cluster_max_size=\"${GREEN_CLUSTER_MAX_SIZE}\" -var blue_cluster_min_size=\"${BLUE_CLUSTER_MIN_SIZE}\" -var blue_cluster_max_size=\"${BLUE_CLUSTER_MAX_SIZE}\" -var blue_min_elb_capacity=\"${BLUE_MIN_ELB_CAPACITY}\" -var green_min_elb_capacity=\"${GREEN_MIN_ELB_CAPACITY}\";


## Update deployment state file
if [ $LIVE_GROUP == "null" ]
then
   /gocd-data/scripts/update-deployment-state.sh ${APP_NAME} ${LIVE_GROUP} ${AMI_ID} null true true
elif [ $LIVE_GROUP == "blue" ]
then
   /gocd-data/scripts/update-deployment-state.sh ${APP_NAME} ${LIVE_GROUP} ${BLUE_GROUP_AMI_ID} ${AMI_ID} false true
elif [ $LIVE_GROUP == "green" ]
then
   /gocd-data/scripts/update-deployment-state.sh ${APP_NAME} ${LIVE_GROUP} ${AMI_ID} ${GREEN_GROUP_AMI_ID} false true
fi;
