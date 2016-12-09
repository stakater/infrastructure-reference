#!/bin/bash
# This script suspends Launch and Health Check processes for specified ',' separated environments in the specified region
#----------------------------------------------
# Argument1: ENVIRONMENTS
# Argument2: REGION
#----------------------------------------------

#Input Parameters
ENVIRONMENTS=$1
REGION=$2
# Check number of parameters equals 2
if [ "$#" -ne 2 ]; then
    echo "ERROR: [Test Code] Illegal number of parameters"
    exit 1
fi
#check environment variable length... must be greater than 1
if [ ${#ENVIRONMENTS} -le 1 ]; then
    echo "ERROR: [Test Code] Illegal parameter value"
    exit 1
fi

IFS=',' read -r -a listToApplyOn <<< $ENVIRONMENTS
shopt -s lastpipe
aws autoscaling describe-auto-scaling-groups --region $REGION | jq '.AutoScalingGroups[].AutoScalingGroupName' | readarray -t ASGs
total=${#ASGs[@]}
for k in ${ASGs[@]}; do
  k=${k//\"/}
  for i in ${listToApplyOn[*]}; do
    if [[ $k == *$i* ]]
    then
      echo "suspending processes for $k"
      aws autoscaling suspend-processes --region $REGION --auto-scaling-group-name $k --scaling-processes Launch HealthCheck
    fi
  done
done
