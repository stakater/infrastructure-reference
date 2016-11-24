#!/bin/bash
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
done | sort -k3 -r | awk '{print $1}' | readarray -t instanceId
for k in ${instanceId[@]}; do
  if [ "$k" != "$gocdId"  ] 
  if [ "$k" != "$gocdId"  ] 
  then
    echo "stopping instance " $k
    echo $(aws ec2 stop-instances --instance-ids $k --region $REGION)
  fi
done
