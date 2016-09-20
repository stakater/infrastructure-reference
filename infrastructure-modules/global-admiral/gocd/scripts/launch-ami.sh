#!/bin/bash
# THis shell script deploys and AMI 
#-----------------------------------------------------
# Argument1: AMI_ID
# Argument2: VPC_ID
# Argument3: SUBNET_ID
# Argument4: AWS_REGION
#-----------------------------------------------------

# Get parameter values
AMI_ID=$1
VPC_ID=$2
SUBNET_ID=$3
AWS_REGION=$4

# Output values
echo "###################################################"
echo "AMI_ID: ${AMI_ID}"
echo "VPC_ID: ${VPC_ID}"
echo "SUBNET_ID: ${SUBNET_ID}"
echo "AWS_REGION: ${AWS_REGION}"
echo "###################################################"

## Automated Deployment

# Download amd update modules
cd ~/terraform-aws-asg/examples/standard/;
sudo /opt/terraform/terraform get -update .;

# Destroy terraform managed infrastructure
#sudo /opt/terraform/terraform destroy -force -var-file=./terraform.tfvars -var ami=${AMI_ID} -var vpc_id=${VPC_ID} -var subnet_ids=${SUBNET_ID} -var region=${AWS_REGION};

# Create execution plan
sudo /opt/terraform/terraform plan -var-file=./terraform.tfvars -var ami=${AMI_ID} -var vpc_id=${VPC_ID} -var subnet_ids=${SUBNET_ID} -var region=${AWS_REGION};

# Apply changes required
sudo /opt/terraform/terraform apply -var-file=./terraform.tfvars -var ami=${AMI_ID} -var vpc_id=${VPC_ID} -var subnet_ids=${SUBNET_ID} -var region=${AWS_REGION};

