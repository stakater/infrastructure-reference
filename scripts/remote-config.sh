#!/bin/bash
#########################################
## This script updates terraform s3
## remote config with the given bucket
## name and key for state file
#########################################

AWS_PROFILE=${AWS_PROFILE}
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
AWS_REGION=$($DIR/read-cfg.sh $HOME/.aws/config "profile $AWS_PROFILE" region)

BUCKET_NAME=""
STATE_KEY=""

bOptionFlag=false;
kOptionFlag=false;
# Get options from the command line
while getopts ":b:k:" OPTION
do
    case $OPTION in
        b)
          BUCKET_NAME=$OPTARG
          bOptionFlag=true;
          ;;
        k)
          STATE_KEY=$OPTARG
          kOptionFlag=true;
          ;;
        *)
          echo "Usage: $(basename $0) -b <Name of Bucket> -k <key for the state file>"
          exit 0
          ;;
    esac
done

if ! $bOptionFlag || ! $kOptionFlag;
then
  echo "Usage: $(basename $0) -b <Name of Bucket> -k <key for the state file>"
  exit 0;
fi

terraform remote config \
  -backend S3 \
  -backend-config="bucket=$BUCKET_NAME" \
  -backend-config="key=$STATE_KEY" \
  -backend-config="region=$AWS_REGION";