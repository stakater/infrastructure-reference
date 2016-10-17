#!/bin/bash
# This shell sript returns value of the parameter with the specified tag
#-----------------------------------------------------------------------
# Argument1: PROPERTIES_FILE
# Argument1: KEY
#-----------------------------------------------------------------------

# Input parameters
PROPERTIES_FILE=$1
KEY=$2

# Check if file exists
if [ ! -f ${PROPERTIES_FILE} ];
then
   value="null";
else
   # Get value for key
   value=`cat ${PROPERTIES_FILE} | grep ${KEY} | cut -d'=' -f2`
   if [ "$value" = "" ];
   then
      value="null";
   fi;
fi;

# Return value
echo ${value}

