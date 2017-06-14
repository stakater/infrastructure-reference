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
## This script updates initiates terraform
## with s3 backend and properties in the
## given config file
#########################################

CONFIG_FILE=""

cOptionFlag=false;
# Get options from the command line
while getopts ":c:" OPTION
do
    case $OPTION in
        c)
          CONFIG_FILE=$OPTARG
          cOptionFlag=true;
          ;;
        *)
          echo "Usage: $(basename $0) -c <Backend config file>"
          exit 1;
          ;;
    esac
done

if ! $cOptionFlag;
then
  echo "Usage: $(basename $0) -c <Backend config file>"
  exit 1;
fi

terraform init \
  -backend=true \
  -backend-config="$CONFIG_FILE";