#!/bin/bash
# This shell script compiles code and fails pipeline if there are compilation errors
#-----------------------------------------------------------------------------------
# Argument1: APP_NAME
# Argument2: ENVIRONMENT
#-----------------------------------------------------------------------------------

# Get parameter values
APP_NAME=$1
ENVIRONMENT=$2

# Check number of parameters equal 2
if [ "$#" -ne 2 ]; then
    echo "ERROR: [Compile Code] Illegal number of parameters"
    exit 1
fi

# Remove special characters from app name
APP_NAME=${APP_NAME//[_-]/}
# Convert ENVIRONMENT value to lowercase
ENVIRONMENT=`echo "$ENVIRONMENT" | sed 's/./\L&/g'`

# Compile Code
# Run docker-compose up command. Replace default directory name with APP_NAME
if [ $ENVIRONMENT == "prod" ]
then
   sudo /opt/bin/docker-compose -f docker-compose-prod.yml -p "${APP_NAME}${ENVIRONMENT}" up compile
elif [ $ENVIRONMENT == "dev" ]
then
   sudo /opt/bin/docker-compose -f docker-compose-dev.yml -p "${APP_NAME}${ENVIRONMENT}" up compile
elif [ $ENVIRONMENT == "test" ]
then
   sudo /opt/bin/docker-compose -f docker-compose-test.yml -p "${APP_NAME}${ENVIRONMENT}" up compile
fi;

# Check Status
STATUS=$(sudo docker wait ${APP_NAME}${ENVIRONMENT}_compile_1)
if [ "$STATUS" != "0" ]; then
   echo "Code Compilation FAILED: $STATUS"
   sudo docker rm -vf ${APP_NAME}${ENVIRONMENT}_compile_1
   exit 1
else
   echo "Code Compilation COMPLETE"
   sudo docker rm -vf ${APP_NAME}${ENVIRONMENT}_compile_1
   exit 0
fi
