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


# This shell script builds docker image
#--------------------------------------------
# Argument1: APP_NAME
# Argument2: ENVIRONMENT
# Argument3: APP_IMAGE_BUILD_VERSION
# Argument4: APP_DOCKER_IMAGE
#--------------------------------------------

# Get parameter values
APP_NAME=$1
ENVIRONMENT=$2
APP_IMAGE_BUILD_VERSION=$3
APP_DOCKER_IMAGE=$4

# Check number of parameters equals 4
if [ "$#" -ne 4 ]; then
    echo "ERROR: [Build Docker Image] Illegal number of parameters"
    exit 1
fi

# Remove special characters from app name
SIMPLE_APP_NAME=${APP_NAME//[_-]/}
# Convert ENVIRONMENT value to lowercase
ENVIRONMENT=`echo "$ENVIRONMENT" | sed 's/./\L&/g'`

# Package
# Run docker-compose up command.
if [ $ENVIRONMENT == "prod" ]
then
   sudo /opt/bin/docker-compose -f docker-compose-prod.yml -p "${SIMPLE_APP_NAME}${ENVIRONMENT}" up app
elif [ $ENVIRONMENT == "dev" ]
then
   sudo /opt/bin/docker-compose -f docker-compose-dev.yml -p "${SIMPLE_APP_NAME}${ENVIRONMENT}" up app
elif [ $ENVIRONMENT == "test" ]
then
   sudo /opt/bin/docker-compose -f docker-compose-test.yml -p "${SIMPLE_APP_NAME}${ENVIRONMENT}" up app
fi;

# Remove old war files from project root directory
if [ -f ./*.war ];
then
   sudo rm -r ./*.war
fi;

# Copy war file to root directory
sudo cp -f /app/${APP_NAME}_${ENVIRONMENT}/*.war ./

# Remove copies of new war file not needed anymore
sudo rm -r /app/${APP_NAME}_${ENVIRONMENT}/*.war

# Publish
# Build image
sudo docker build -t ${APP_DOCKER_IMAGE} -f Dockerfile_deploy .

# Push docker image
sudo docker push ${APP_DOCKER_IMAGE}

newTag=${APP_DOCKER_IMAGE}:${APP_IMAGE_BUILD_VERSION}
echo ${newTag}
sudo docker tag -f ${APP_DOCKER_IMAGE} ${newTag}
sudo docker push ${newTag}

# Delete unwanted images/containers
sudo docker rmi -f ${SIMPLE_APP_NAME}${ENVIRONMENT}_compile
sudo docker rmi -f ${SIMPLE_APP_NAME}${ENVIRONMENT}_test
sudo docker rmi -f ${SIMPLE_APP_NAME}${ENVIRONMENT}_app
sudo docker rm -vf ${SIMPLE_APP_NAME}${ENVIRONMENT}_app_1

# Delete empty docker images
/gocd-data/scripts/docker-cleanup.sh

