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