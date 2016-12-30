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


# This shell script builds Amazon Machine Images (AMI)
#-----------------------------------------------------
# Argument1: APP_NAME
# Argument2: ENVIRONMENT
#-----------------------------------------------------


# Get parameter values
APP_NAME=""
ENVIRONMENT=""

# Flags to make sure all options are given
aOptionFlag=false;
eOptionFlag=false;
# Get options from the command line
while getopts ":a:e:" OPTION
do
    case $OPTION in
        a)
          aOptionFlag=true
          APP_NAME=$OPTARG
          ;;
        e)
          eOptionFlag=true
          ENVIRONMENT=$OPTARG
          ;;
        *)
          echo "Usage: $(basename $0) -a <APP NAME> -e <ENVIRONMENT>"
          exit 0
          ;;
    esac
done

if [[ ! $aOptionFlag || ! $eOptionFlag ]] ;
then
  echo "Usage: $(basename $0) -a <APP NAME> -e <ENVIRONMENT>"
  exit 0;
fi

cd /app/stakater/prod-deployment-reference-${APP_NAME}-${ENVIRONMENT}/scripts
sudo ./destroy.sh