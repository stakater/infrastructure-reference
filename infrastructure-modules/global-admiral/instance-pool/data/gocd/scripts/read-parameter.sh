#!/bin/bash
# This shell sript returns value of the parameter with the specified tag
#-----------------------------------------------------------------------
# Argument1: PROPERTIES_FILE
# Argument1: KEY
#-----------------------------------------------------------------------

# Input parameters
PROPERTIES_FILE=$1
KEY=$2

# Get value for key
value=''
value=`cat ${PROPERTIES_FILE} | grep ${KEY} | cut -d'=' -f2`

# Return value
echo ${value}

