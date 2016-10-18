#!/bin/bash
# This shell script builds Amazon Machine Images (AMI)
#-----------------------------------------------------
# Argument1: APP_NAME
# Argument2: APP_IMAGE_BUILD_VERSION
# Argument3: BUILD_UUID
# Argument4: APP_DOCKER_IMAGE
# Argument5: PROD_CLOUDINIT_S3_FULL_PATH - path to prodcution enviornment's cloudinit file in s3 (e.g. bucket-name/file/location)
#-----------------------------------------------------

PROPERTIES_FILE=/gocd-data/scripts/gocd.parameters.txt

# Get parameter values
APP_DOCKER_OPTS=`/gocd-data/scripts/read-parameter.sh ${PROPERTIES_FILE} APP_DOCKER_OPTS`
DOCKER_REGISTRY=`/gocd-data/scripts/read-parameter.sh ${PROPERTIES_FILE} DOCKER_REGISTRY`
APP_NAME=$1
APP_IMAGE_BUILD_VERSION=$2
BUILD_UUID=$3
APP_DOCKER_IMAGE=$4
PROD_CLOUDINIT_S3_FULL_PATH=$5
DATA_EBS_DEVICE_NAME=$6
DATA_EBS_VOL_SIZE=$7
LOGS_EBS_DEVICE_NAME=$8
LOGS_EBS_VOL_SIZE=$9

echo "APP_DOCKER_OPTS: ${APP_DOCKER_OPTS}";
echo "DOCKER_REGISTRY: ${DOCKER_REGISTRY}";

# Check number of parameters equals 4
if [ "$#" -lt 4 ]; then
    echo "ERROR: [Build AMI] Illegal number of parameters"
    exit 1
fi

# AMI Baker
AMI_BAKER_LOCATION="/app/stakater/amibaker"
if [ ! -d "$AMI_BAKER_LOCATION" ];
then
  sudo mkdir -p $AMI_BAKER_LOCATION;
fi;
if [ ! "$(ls -A $AMI_BAKER_LOCATION)" ];
then
  sudo git clone https://github.com/stakater/ami-baker.git $AMI_BAKER_LOCATION;
fi;

cd $AMI_BAKER_LOCATION;
sudo git pull origin master;

sudo docker run -d --name packer_${GO_PIPELINE_NAME} -v $AMI_BAKER_LOCATION:/usr/src/app stakater/packer

sudo cp -f /etc/registry-certificates/ca.crt $AMI_BAKER_LOCATION/baker-data/ca.crt;
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

# Default file
CLOUD_CONFIG_TMPL_PATH="cloud-config/cloud-config.tmpl.yaml"

# Download cloud config to ami-baker's cloud-config folder if path is given, else use default config
if [ ! -z ${PROD_CLOUDINIT_S3_FULL_PATH} ];
then
  CLOUD_CONFIG_TMPL_PATH="cloud-config/cloud-config-$APP_NAME.tmpl.yaml";
  sudo aws s3 cp s3://${PROD_CLOUDINIT_S3_FULL_PATH} "$CLOUD_CONFIG_TMPL_PATH"
fi;

# Bake AMI
sudo docker exec packer_${GO_PIPELINE_NAME} /bin/bash -c "./bake-ami.sh -r $aws_region -v $vpc_id -s $subnet_id -b $build_uuid -n ${APP_NAME}_${APP_IMAGE_BUILD_VERSION} -c ${CLOUD_CONFIG_TMPL_PATH} -d ${APP_DOCKER_IMAGE} -o \"${APP_DOCKER_OPTS}\" -g $docker_registry_path -e ${DATA_EBS_DEVICE_NAME} -z ${DATA_EBS_VOL_SIZE} -l ${LOGS_EBS_DEVICE_NAME} -x ${LOGS_EBS_VOL_SIZE}"

aws_describe_json=$(aws ec2 describe-images --region $aws_region --filters Name=tag:BuildUUID,Values=${build_uuid});
AMI_ID=$(echo "$aws_describe_json" | jq --raw-output '.Images[0].ImageId');
echo "$AMI_ID"

# Remove docker container
sudo docker rm -vf packer_${GO_PIPELINE_NAME}

# Write AMI parameters to file
/gocd-data/scripts/write-ami-parameters.sh ${APP_NAME} ${AMI_ID} ${vpc_id} ${subnet_id} ${aws_region}