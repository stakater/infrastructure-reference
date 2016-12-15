#!/bin/bash

###############################################################################
# Copyright 2016 Aurora Solutions
#
#    http://www.aurorasolutions.io
#
# Aurora Solutions is an innovative services and product company at
# the forefront of the software industry, with processes and practices
# involving Domain Driven Design(DDD), Agile methodologies to build
# scalable, secure, reliable and high performance products.
#
# Stakater is an Infrastructure-as-a-Code DevOps solution to automate the
# creation of web infrastructure stack on Amazon. Stakater is a collection
# of Blueprints; where each blueprint is an opinionated, reusable, tested,
# supported, documented, configurable, best-practices definition of a piece
# of infrastructure. Stakater is based on Docker, CoreOS, Terraform, Packer,
# Docker Compose, GoCD, Fleet, ETCD, and much more.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################

# This script starts Instances for specified ',' separated environments in the specified region
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
gocdId=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
echo "GOcd Id: " $gocdId
data=$(aws ec2 describe-instances --region $REGION --query 'Reservations[].Instances[].{id:InstanceId, tag:Tags[?Key==`Name`].Value}'|jq '.')
total=$(echo ${data} | jq '.|length')
i=0
declare -A instances
command=".[$i].tag[0]"
while [ "$i" -lt "$total" ]; do
  getValue=".[$i].tag[0]"
  getKey=".[$i].id"
  key=$(echo ${data} | jq ${getKey})
  key=${key//\"/}
  value=$(echo ${data} | jq ${getValue})
  value=${value//\"/}
  instances["$key"]=$value
  i=$(($i + 1))
done
shopt -s lastpipe
for k in ${!instances[@]}; do
  for i in ${listToApplyOn[*]}; do
      if [[ ${instances["$k"]} == *$i* ]]
      then
        echo $k ' - ' ${instances["$k"]}
      fi
  done
done | sort -k3 | awk '{print $1}' | readarray -t instanceId

for k in ${instanceId[@]}; do
  if [ "$k" != "$gocdId"  ]
  then
    echo "starting instance " $k
    echo $(aws ec2 start-instances --instance-ids $k --region $REGION)
  fi
done
