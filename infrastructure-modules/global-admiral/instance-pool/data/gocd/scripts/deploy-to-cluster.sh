#!/bin/bash
# Deploy to cluster
#-----------------------------------
# Argument1: CLUSTER_ENV
# Argument2: APP_DOCKER_IMAGE
#-----------------------------------

# Get parameter values
APP_DOCKER_OPTS=`/gocd-data/scripts/read-parameter.sh APP_DOCKER_OPTS`
ROUTE53_HOSTED_ZONE_NAME=`/gocd-data/scripts/read-parameter.sh ROUTE53_HOSTED_ZONE_NAME`
CLUSTER_ENV=$1
APP_DOCKER_IMAGE=$2

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

cd /app/application-unit;
sudo mv application.service application-${APP_NAME}-${CLUSTER_ENV}.service

host_ip=$(ip route show | awk '/default/ {print $3}');
cluster_ip=$(curl -s -L http://${host_ip}:4001/v2/keys/stakater/${CLUSTER_ENV}/ip | jq '.node.value' | sed s/\"//g);
echo $(jq --version)
hosted_zone_id=$(aws route53 list-hosted-zones | jq --arg ROUTE53_HOSTED_ZONE_NAME "$ROUTE53_HOSTED_ZONE_NAME" '.HostedZones[] | select(.Name==$ROUTE53_HOSTED_ZONE_NAME) | .Id')
hosted_zone_id=${hosted_zone_id##*/}
hosted_zone_id=${hosted_zone_id%%\"*}

cd /gocd-data/route53;
sudo chmod +x substitite-record-values.sh;
sudo ./substitite-record-values.sh -f record-change-batch.json.tmpl -i ${cluster_ip} -n ${APP_NAME}_${CLUSTER_ENV}.${ROUTE53_HOSTED_ZONE_NAME} -a "UPSERT"

aws route53 change-resource-record-sets --hosted-zone-id ${hosted_zone_id} --change-batch file://record-change-batch.json
cd /app/application-unit;

fleetctl --etcd-key-prefix=/stakater/${CLUSTER_ENV}/ --endpoint=http://${cluster_ip}:4001 destroy application-${APP_NAME}-${CLUSTER_ENV}.service
sleep 5;
fleetctl --etcd-key-prefix=/stakater/${CLUSTER_ENV}/ --endpoint=http://${cluster_ip}:4001 start application-${APP_NAME}-${CLUSTER_ENV}.service
