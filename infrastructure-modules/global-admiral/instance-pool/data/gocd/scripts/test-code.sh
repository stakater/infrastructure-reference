#!/bin/bash
# This shell script executes application tests and fails pipeline if tests fail
#------------------------------------------------------------------------------
# Argument1: APP_NAME
# Argument2: ENVIRONMENT
#------------------------------------------------------------------------------

# Get parameter values
APP_NAME=$1
ENVIRONMENT=$2

# Check number of parameters equals 2
if [ "$#" -ne 2 ]; then
    echo "ERROR: [Test Code] Illegal number of parameters"
    exit 1
fi

# Remove special characters from app name
APP_NAME=${APP_NAME//[_-]/}
# Convert ENVIRONMENT value to lowercase
ENVIRONMENT=`echo "$ENVIRONMENT" | sed 's/./\L&/g'`

# Execute Application Tests
# Run docker-compose up command. Replace default directory name with APP_NAME
if [ $ENVIRONMENT == "prod" ]
then
   sudo /opt/bin/docker-compose -f docker-compose-prod.yml -p "${APP_NAME}${ENVIRONMENT}" up test
elif [ $ENVIRONMENT == "dev" ]
then
   sudo /opt/bin/docker-compose -f docker-compose-dev.yml -p "${APP_NAME}${ENVIRONMENT}" up test
elif [ $ENVIRONMENT == "test" ]
then
   sudo /opt/bin/docker-compose -f docker-compose-test.yml -p "${APP_NAME}${ENVIRONMENT}" up test
fi;

# Check Status
STATUS=$(sudo docker wait ${APP_NAME}${ENVIRONMENT}_test_1)
if [ "$STATUS" != "0" ]; then
   echo " Tests FAILED: $STATUS"
   sudo docker rm -vf ${APP_NAME}${ENVIRONMENT}_test_1
   sudo docker rmi -f ${APP_NAME}${ENVIRONMENT}_test
   sudo docker rmi -f  ${APP_NAME}${ENVIRONMENT}_compile
   exit 1
else
   echo " Tests PASSED"
   sudo docker rm ${APP_NAME}${ENVIRONMENT}_test_1
   exit 0
fi
