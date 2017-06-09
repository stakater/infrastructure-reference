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


# This shell script builds Amazon Machine Images (AMI)
#-----------------------------------------------------
# Argument1: APP_NAME
# Argument2: ENVIRONMENT
# Argument3: APP_IMAGE_BUILD_VERSION
# Argument4: BUILD_UUID
# Argument5: APP_DOCKER_IMAGE
# Argument6: APP_DOCKER_OPTS
# Argument7: CLOUDINIT_S3_FULL_PATH - path to prodcution enviornment's cloudinit file in s3 (e.g. bucket-name/file/location)
# Argument8: DATA_EBS_DEVICE_NAME: Data device name
# Argument9: DATA_EBS_VOL_SIZE: data device size
# Argument10: LOGS_EBS_DEVICE_NAME: logs device name
# Argument11: LOGS_EBS_VOL_SIZE: logs device size
#-----------------------------------------------------

PROPERTIES_FILE=/gocd-data/scripts/gocd.parameters.txt

# Get parameter values
DOCKER_REGISTRY=`/gocd-data/scripts/read-parameter.sh ${PROPERTIES_FILE} DOCKER_REGISTRY`
APP_NAME=""
ENVIRONMENT=""
APP_IMAGE_BUILD_VERSION=""
BUILD_UUID=""
APP_DOCKER_IMAGE=""
APP_DOCKER_OPTS=""
EXTRA_CLOUDCONFIG_UNITS=""
CLOUDINIT_S3_FULL_PATH=""
BAKER_INSTANCE_TYPE=""
DATA_EBS_DEVICE_NAME=""
DATA_EBS_VOL_SIZE=""
LOGS_EBS_DEVICE_NAME=""
LOGS_EBS_VOL_SIZE=""

# Flags to make sure required all options are given
aOptionFlag=false;
bOptionFlag=false;
uOptionFlag=false;
dOptionFlag=false;
oOptionFlag=false;
rOptionFlag=false;
volOptionCnt=0;
# Get options from the command line
while getopts ":a:b:u:d:o:c:y:e:z:l:x:r:i:" OPTION
do
    case $OPTION in
        a)
          aOptionFlag=true
          APP_NAME=$OPTARG
          ;;
        b)
          bOptionFlag=true
          APP_IMAGE_BUILD_VERSION=$OPTARG
          ;;
        u)
          uOptionFlag=true
          BUILD_UUID=$OPTARG
          ;;
        d)
          dOptionFlag=true
          APP_DOCKER_IMAGE=$OPTARG
          ;;
        o)
          oOptionFlag=true
          APP_DOCKER_OPTS=$OPTARG
          ;;
        r)
          rOptionFlag=true
          ENVIRONMENT=$OPTARG
          ;;
        c)
          CLOUDINIT_S3_FULL_PATH=$OPTARG #optional
          ;;
        y)
          dOptionFlag=true; # Set APP_DOCKER_IMAGE option to true, so that either(or both) of APP_DOCKER_IMAGE or EXTRA_CLOUDCONFIG_UNITS must be specified
          EXTRA_CLOUDCONFIG_UNITS=$OPTARG
          ;;
        e)
          volOptionCnt=$((volOptionCnt+1));
          DATA_EBS_DEVICE_NAME=$OPTARG
          ;;
        z)
          volOptionCnt=$((volOptionCnt-1));
          DATA_EBS_VOL_SIZE=$OPTARG
          ;;
        l)
          volOptionCnt=$((volOptionCnt+1));
          LOGS_EBS_DEVICE_NAME=$OPTARG
          ;;
        x)
          volOptionCnt=$((volOptionCnt-1));
          LOGS_EBS_VOL_SIZE=$OPTARG
          ;;
        i)
          BAKER_INSTANCE_TYPE=$OPTARG
          ;;
        *)
          echo "Usage: $(basename $0) -a <APP NAME> -b <APP IMAGE BUILD VERSION> -r <ENVIRONMENT> -u <Build UUID> -d <APP DOCKER IMAGE>(or -y <EXTRA_CLOUDCONFIG_UNITS>)  -o <APP DOCKER OPTIONS> -c <Full path (incl bucket name) of cloud config file> (optional) -e <EBS data volume device name> -z <EBS data volume device size> -l <EBS logs volume device name> -x <EBS logs volume size> -i <baker instance type> (optional)"
          exit 1
          ;;
    esac
done
if [[ ! $aOptionFlag || ! $bOptionFlag || ! $uOptionFlag || ! $dOptionFlag || ! $oOptionFlag || ! $rOptionFlag ]] || [[ $volOptionCnt -ne  0 ]] ;
then
  echo "Usage: $(basename $0) -a <APP NAME> -b <APP IMAGE BUILD VERSION> -r <ENVIRONMENT> -u <Build UUID> -d <APP DOCKER IMAGE>(or -y <EXTRA_CLOUDCONFIG_UNITS>) -o <APP DOCKER OPTIONS> -c <Full path (incl bucket name) of cloud config file> (optional) -e <EBS data volume device name> -z <EBS data volume device size> -l <EBS logs volume device name> -x <EBS logs volume size> -i <baker instance type> (optional)"
  exit 1;
fi

# AMI Baker
AMI_BAKER_LOCATION="/app/stakater/amibaker"
if [ ! -d "$AMI_BAKER_LOCATION" ];
then
  sudo mkdir -p $AMI_BAKER_LOCATION;
fi;
if [ ! "$(ls -A $AMI_BAKER_LOCATION)" ];
then
  sudo git clone https://github.com/stakater/ami-baker.git?ref=v0.1.0 $AMI_BAKER_LOCATION;
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
echo ENVIRONMENT: ${ENVIRONMENT}
echo APP_IMAGE_BUILD_VERSION: ${APP_IMAGE_BUILD_VERSION}
echo APP_DOCKER_OPTS: ${APP_DOCKER_OPTS}
echo APP_DOCKER_IMAGE: ${APP_DOCKER_IMAGE}
echo DATA_EBS_DEVICE_NAME: ${DATA_EBS_DEVICE_NAME}
echo DATA_EBS_VOL_SIZE: ${DATA_EBS_VOL_SIZE}
echo LOGS_EBS_DEVICE_NAME: ${LOGS_EBS_DEVICE_NAME}
echo LOGS_EBS_VOL_SIZE: ${LOGS_EBS_VOL_SIZE}
echo "########################################################################"

# Default file
CLOUD_CONFIG_TMPL_PATH="cloud-config/cloud-config.tmpl.yaml"

# Download cloud config to ami-baker's cloud-config folder if path is given, else use default config
if [ "X${CLOUDINIT_S3_FULL_PATH}" != "X" ];
then
  CLOUD_CONFIG_TMPL_PATH="cloud-config/cloud-config-$APP_NAME-$ENVIRONMENT.tmpl.yaml";
  sudo aws --region ${aws_region} s3 cp s3://${CLOUDINIT_S3_FULL_PATH} "$CLOUD_CONFIG_TMPL_PATH"
fi;

# Bake AMI
sudo docker exec packer_${GO_PIPELINE_NAME} /bin/bash -c "./bake-ami.sh -r $aws_region -v $vpc_id -s $subnet_id -b $build_uuid -n ${APP_NAME}_${ENVIRONMENT}_${APP_IMAGE_BUILD_VERSION} -c ${CLOUD_CONFIG_TMPL_PATH} -y '${EXTRA_CLOUDCONFIG_UNITS}' -d \"${APP_DOCKER_IMAGE}\" -o \"${APP_DOCKER_OPTS}\" -g \"$docker_registry_path\" -e \"${DATA_EBS_DEVICE_NAME}\" -z \"${DATA_EBS_VOL_SIZE}\" -l \"${LOGS_EBS_DEVICE_NAME}\" -x \"${LOGS_EBS_VOL_SIZE}\" -i \"${BAKER_INSTANCE_TYPE}\""

aws_describe_json=$(aws ec2 describe-images --region $aws_region --filters Name=tag:BuildUUID,Values=${build_uuid});
AMI_ID=$(echo "$aws_describe_json" | jq --raw-output '.Images[0].ImageId');
echo "$AMI_ID"

# Remove docker container
sudo docker rm -vf packer_${GO_PIPELINE_NAME}

# Write AMI parameters to file
/gocd-data/scripts/write-ami-parameters.sh ${APP_NAME} ${ENVIRONMENT} ${AMI_ID} ${vpc_id} ${subnet_id} ${aws_region}