#!/bin/bash
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

# Remove special characters from app name
SIMPLE_APP_NAME=${APP_NAME//[_-]/}

# Package
# Run docker-compose up command.
if [ $ENVIRONMENT == "prod" ]
then
   sudo /opt/bin/docker-compose -f docker-compose-prod.yml -p ${SIMPLE_APP_NAME} up app
elif [ $ENVIRONMENT == "dev" ]
then
   sudo /opt/bin/docker-compose -f docker-compose-dev.yml -p ${SIMPLE_APP_NAME} up app
elif [ $ENVIRONMENT == "test" ]
then
   sudo /opt/bin/docker-compose -f docker-compose-test.yml -p ${SIMPLE_APP_NAME} up app
fi;

# Remove old war files from project root directory
sudo rm -r ./*.war

# Copy war file to root directory
sudo cp -f /app/${APP_NAME}/*.war ./

# Remove copies of new war file not needed anymore
sudo rm -r /app/${APP_NAME}/*

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
sudo docker rmi -f ${SIMPLE_APP_NAME}_compile
sudo docker rmi -f ${SIMPLE_APP_NAME}_test
sudo docker rmi -f ${SIMPLE_APP_NAME}_app
sudo docker rm ${SIMPLE_APP_NAME}_app_1

# Delete empty docker images
/gocd-data/scripts/docker-cleanup.sh

