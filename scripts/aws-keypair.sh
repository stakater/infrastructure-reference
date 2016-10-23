#!/bin/bash

AWS_PROFILE=${AWS_PROFILE}
STACK_NAME=${STACK_NAME}

# Input located at the end of the script
# Default key name
key=${STACK_NAME}
# Default bucket name
CONFIG_BUCKET_NAME=${STACK_NAME}-config

echo "Getting AWS account number..."
AWS_ACCOUNT=$(aws --profile ${AWS_PROFILE} iam get-user | jq ".User.Arn" | grep -Eo '[[:digit:]]{12}')
echo $AWS_ACCOUNT

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
AWS_REGION=$($DIR/read_cfg.sh $HOME/.aws/config "profile $AWS_PROFILE" region)

TMP_DIR=${BUILD}/keypairs

create(){
  if  aws --profile ${AWS_PROFILE} ec2 describe-key-pairs --key-name ${key} > /dev/null 2>&1 ;
  then
    echo "keypair ${key} already exists."
  else
    mkdir -p ${TMP_DIR}
    chmod 700 ${TMP_DIR}
    echo "Creating keypair ${key} and uploading to s3"
    aws --profile ${AWS_PROFILE} ec2 create-key-pair --key-name ${key} --query 'KeyMaterial' --output text > ${TMP_DIR}/${key}.pem
    aws --region ${AWS_REGION} --profile ${AWS_PROFILE} s3 cp ${TMP_DIR}/${key}.pem s3://${CONFIG_BUCKET_NAME}/keypairs/${key}.pem

    chmod 600 ${TMP_DIR}/${key}.pem
    echo "ssh-add ${TMP_DIR}/${key}.pem"
    ssh-add ${TMP_DIR}/${key}.pem
    # Clean up
    # rm -rf ${TMP_DIR}
  fi
}

destroy(){
  if  ! aws --profile ${AWS_PROFILE} ec2 describe-key-pairs --key-name ${key} > /dev/null 2>&1 ;
  then
    echo "keypair ${key} does not exists."
  else
    if [ -f ${TMP_DIR}/${key}.pem ];
    then
      echo "Remove from ssh agent"
      ssh-add -L |grep "${TMP_DIR}/${key}.pem" > ${TMP_DIR}/${key}.pub
      [ -s ${TMP_DIR}/${key}.pub ] && ssh-add -d ${TMP_DIR}/${key}.pub
      aws --region ${AWS_REGION} --profile ${AWS_PROFILE} s3 rm s3://${CONFIG_BUCKET_NAME}/keypairs/${key}.pem
      echo "Delete aws keypair ${key}"
      aws --profile ${AWS_PROFILE} ec2 delete-key-pair --key-name ${key}
      echo "Remove from ${TMP_DIR}"
      rm -rf ${TMP_DIR}/${key}.pem
      rm -rf ${TMP_DIR}/${key}.pub
    fi
  fi
}

while getopts ":b:c:d:h" OPTION
do
  case $OPTION in
    b)
      CONFIG_BUCKET_NAME=$OPTARG
      ;;
    c)
      key=$OPTARG
      create
      ;;
    d)
      key=$OPTARG
      destroy
      ;;
    *)
      echo "Usage: $(basename $0) -b bucketname -c|-d keyname"
      exit 1
      ;;
  esac
done
exit 0