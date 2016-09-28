#!/bin/bash
# This shell script compiles code and fails pipeline if there are compilation errors
#-----------------------------------------------------------------------------------
# Argument1: APP_NAME
# Argument2: ENVIRONMENT
#-----------------------------------------------------------------------------------

# Get parameter values
APP_NAME=$1
ENVIRONMENT=$2

# Remove special characters from app name
APP_NAME=${APP_NAME//[_-]/}

# Compile Code 
# Run docker-compose up command. Replace default directory name with APP_NAME
if [ $ENVIRONMENT == "prod" ]
then
   sudo /opt/bin/docker-compose -f docker-compose-prod.yml -p ${APP_NAME} up compile
elif [ $ENVIRONMENT == "dev" ]
then
   sudo /opt/bin/docker-compose -f docker-compose-dev.yml -p ${APP_NAME} up compile
elif [ $ENVIRONMENT == "test" ]
then
   sudo /opt/bin/docker-compose -f docker-compose-test.yml -p ${APP_NAME} up compile
fi;

# Check Status
STATUS=$(sudo docker wait ${APP_NAME}_compile_1)
if [ "$STATUS" != "0" ]; then
   echo "Code Compilation FAILED: $STATUS"
   sudo docker rm ${APP_NAME}_compile_1
   exit 1
else
   echo "Code Compilation COMPLETE"
   sudo docker rm ${APP_NAME}_compile_1
   exit 0
fi
