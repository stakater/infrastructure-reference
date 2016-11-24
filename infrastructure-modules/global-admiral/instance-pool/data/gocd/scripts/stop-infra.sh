#!/bin/bash
ENVIRONMENTS=$1
# Check number of parameters equals 1
if [ "$#" -ne 1 ]; then
    echo "ERROR: [Test Code] Illegal number of parameters"
    exit 1
fi
#check environment variable length... must be greater than 1
if [ ${#ENVIRONMENTS} -le 1 ]; then
    echo "ERROR: [Test Code] Illegal parameter value"
    exit 1
fi
region=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
region=${region::-1}

/gocd-data/scripts/suspend-ASG-processes.sh $ENVIRONMENTS $region
/gocd-data/scripts/stopInstances.sh $ENVIRONMENTS $region

