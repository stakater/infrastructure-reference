#!/bin/bash
# THis shell script builds Amazon Machine Images (AMI)
#-----------------------------------------------------
# Argument1: APP_NAME
# Argument2: APP_IMAGE_BUILD_VERSION
# Argument3: BUILD_UUID
# Argument4: APP_DOCKER_IMAGE
#-----------------------------------------------------

# Get parameter values
APP_DOCKER_OPTS=`/gocd-data/scripts/read-parameter.sh APP_DOCKER_OPTS`
DOCKER_REGISTRY=`/gocd-data/scripts/read-parameter.sh DOCKER_REGISTRY`
APP_NAME=$1
APP_IMAGE_BUILD_VERSION=$2
BUILD_UUID=$3
APP_DOCKER_IMAGE=$4

# AMI Baker
if [ ! -d "/app/amibaker" ];
then
  sudo mkdir -p /app/amibaker;
fi;
if [ ! "$(ls -A /app/amibaker)" ];
then
  sudo git clone https://github.com/stakater/ami-baker.git /app/amibaker;
fi;

cd /app/amibaker;
sudo git pull origin master;

sudo docker run -d --name packer_${GO_PIPELINE_NAME} -v /app/amibaker:/usr/src/app stakater/packer

sudo cp -f /etc/registry-certificates/ca.crt /app/amibaker/baker-data/ca.crt;
macAddress=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/);
vpc_id=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$macAddress/vpc-id);
subnet_id=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$macAddress/subnet-id);
aws_region=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}');
docker_registry_path="/etc/docker/certs.d/${DOCKER_REGISTRY}";
build_uuid=${BUILD_UUID};

# Output values
echo "#######################################################################"
echo macAddress: ${macAddress}
echo vpc_id: ${vpc_id}
echo subnet_id: ${subnet_id}
echo aws_region: ${aws_region}
echo docker_registry_path: ${docker_registry_path}
echo build_uuid: ${build_uuid}
echo APP_NAME: ${APP_NAME}
echo APP_IMAGE_BUILD_VERSION: ${APP_IMAGE_BUILD_VERSION}
echo APP_DOCKER_OPTS: ${APP_DOCKER_OPTS}
echo APP_DOCKER_IMAGE: ${APP_DOCKER_IMAGE}
echo "########################################################################"

# Bake AMI
sudo docker exec packer_${GO_PIPELINE_NAME} /bin/bash -c "./bake-ami.sh -r $aws_region -v $vpc_id -s $subnet_id -b $build_uuid -n ${APP_NAME}_${APP_IMAGE_BUILD_VERSION} -d ${APP_DOCKER_IMAGE} -o \"${APP_DOCKER_OPTS}\" -g $docker_registry_path"

aws_describe_json=$(aws ec2 describe-images --region $aws_region --filters Name=tag:BuildUUID,Values=${build_uuid});
AMI_ID=$(echo "$aws_describe_json" | jq --raw-output '.Images[0].ImageId');
echo "$AMI_ID"

# Remove docker container
sudo docker rm -vf packer_${GO_PIPELINE_NAME}

# Launch AMI
/gocd-data/scripts/launch-ami.sh  ${AMI_ID} ${vpc_id} ${subnet_id} ${aws_region}
