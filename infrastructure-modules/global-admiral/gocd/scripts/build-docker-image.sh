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

# Package
# Run  docker-compose file
if [ $ENVIRONMENT == "prod" ]
then
   sudo /opt/bin/docker-compose -f docker-compose-prod.yml up
elif [ $ENVIRONMENT == "dev" ]
then
   sudo /opt/bin/docker-compose -f docker-compose-dev.yml up
elif [ $ENVIRONMENT == "test" ]
then
   sudo /opt/bin/docker-compose -f docker-compose-test.yml up
fi;

# Remove old war files from project root directory
sudo rm -r ./*.war

# Copy war file to root directory
sudo cp -f /app/${APP_NAME}/*.war ./

# Remove copies of war file not needed anymore
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

# Delete empty docker images
/gocd-data/scripts/docker-cleanup.sh

