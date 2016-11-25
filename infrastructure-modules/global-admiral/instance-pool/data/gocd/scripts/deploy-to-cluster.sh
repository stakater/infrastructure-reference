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


# Deploy to cluster
#-----------------------------------
# Argument1: APP_NAME
# Argument2: CLUSTER_ENV (`dev` or `qa`)
# Argument3: APP_DOCKER_IMAGE
# Argument4: APP_DOCKER_OPTS
#-----------------------------------

GOCD_PARAMS_FILE="/gocd-data/scripts/gocd.parameters.txt"
# Get parameter values
DEV_CLUSTER_ENDPOINT=`/gocd-data/scripts/read-parameter.sh ${GOCD_PARAMS_FILE} DEV_CLUSTER_ENDPOINT`
QA_CLUSTER_ENDPOINT=`/gocd-data/scripts/read-parameter.sh ${GOCD_PARAMS_FILE} QA_CLUSTER_ENDPOINT`
APP_NAME=$1
CLUSTER_ENV=$2
APP_DOCKER_IMAGE=$3
APP_DOCKER_OPTS=$4

# Convert CLUSTER_ENV value to lowercase
CLUSTER_ENV=`echo "$CLUSTER_ENV" | sed 's/./\L&/g'`

# Configure GIT
git config --global user.email "you@example.com"
git config --global user.name "Your Name"

# /app/application-unit
if [ ! -d "/app/application-unit" ];
then
  sudo mkdir -p /app/application-unit;
  sudo chown go:go /app/application-unit;
fi;
if [ ! "$(ls -A /app/application-unit)" ];
then
  git clone https://github.com/stakater/application-unit.git /app/application-unit;
else
  cd /app/application-unit;
  git pull origin master;
fi;

cd /app/application-unit;
./substitute-Docker-vars.sh -f application.service.tmpl -d "${APP_DOCKER_IMAGE}" -o "${APP_DOCKER_OPTS}";
sudo mv application.service application-${APP_NAME}-${CLUSTER_ENV}.service

cluster_endpoint=""
if [ $CLUSTER_ENV == "dev" ]
then
  cluster_endpoint=$DEV_CLUSTER_ENDPOINT
elif [ $CLUSTER_ENV == "qa" ]
then
  cluster_endpoint=$QA_CLUSTER_ENDPOINT
fi

fleetctl --etcd-key-prefix=/stakater/${CLUSTER_ENV}/worker --endpoint=http://${cluster_endpoint}:4001 destroy application-${APP_NAME}-${CLUSTER_ENV}.service
sleep 5;
fleetctl --etcd-key-prefix=/stakater/${CLUSTER_ENV}/worker --endpoint=http://${cluster_endpoint}:4001 start application-${APP_NAME}-${CLUSTER_ENV}.service