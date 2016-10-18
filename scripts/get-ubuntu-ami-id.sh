#!/bin/bash
AWS_REGION=""
rOptionFlag=false
while getopts ":r:" OPTION
do
    case $OPTION in
        r)
          rOptionFlag=true;
          AWS_REGION=$OPTARG;
          ;;
        *)
          echo "Usage: $(basename $0) -r <AWS region>"
          exit 0
          ;;
    esac
done

if ! $rOptionFlag ;
then
  echo "Usage: $(basename $0) -r <AWS region>"
  exit 0;
fi

name=$(\
    aws --region ${AWS_REGION} ec2 describe-images --owners 099720109477 \
        --filters Name=root-device-type,Values=ebs \
            Name=architecture,Values=x86_64 \
            Name=name,Values='*hvm-ssd/ubuntu-trusty-14.04*' \
    | awk -F ': ' '/"Name"/ { print $2 | "sort" }' \
    | tr -d '",' | tail -1);

ami_id=$(\
    aws --region ${AWS_REGION} ec2 describe-images --owners 099720109477 \
        --filters Name=name,Values="$name" \
    | awk -F ': ' '/"ImageId"/ { print $2 }' | tr -d '",');
    
echo $ami_id;