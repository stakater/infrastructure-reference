#!/bin/bash
# Deploy to cluster
#-----------------------------------
# Argument1: CLUSTER_ENV (`dev` or `qa`)
# Argument2: APP_DOCKER_IMAGE
#-----------------------------------

# Get parameter values
APP_DOCKER_OPTS=`/gocd-data/scripts/read-parameter.sh APP_DOCKER_OPTS`
DEV_CLUSTER_ENDPOINT=`/gocd-data/scripts/read-parameter.sh DEV_CLUSTER_ENDPOINT`
QA_CLUSTER_ENDPOINT=`/gocd-data/scripts/read-parameter.sh QA_CLUSTER_ENDPOINT`
APP_NAME=$1
CLUSTER_ENV=$2
APP_DOCKER_IMAGE=$3

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