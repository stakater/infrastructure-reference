#!/bin/bash
# Return value of the parameter with the specified tag
#--------------------------------------------

# Key to serach value for
KEY=$1

# Properties file
PROPERTIES_FILE=/gocd-data/scripts/gocd.parameters.txt

# Get value for key
value=''
value=`cat ${PROPERTIES_FILE} | grep ${KEY} | cut -d'=' -f2`

echo ${value}