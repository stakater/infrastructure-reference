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


# Clones production deployment code
#----------------------------------
# Argument1: APP_NAME
# Argument1: ENVIRONMENT
#----------------------------------

APP_NAME=$1
ENVIRONMENT=$2

# Clone deployment code
deployCodeLocation="/app/stakater/prod-deployment-reference-${APP_NAME}-${ENVIRONMENT}"

if [ ! -d "${deployCodeLocation}" ];
then
  echo "Ceating Directory."
  sudo mkdir -p ${deployCodeLocation}
else
  echo "Directory Already Exists."
fi;

if [ -d ${deployCodeLocation}/.git ]; then
  echo "${deployCodeLocation} is a git repository.";
else
  echo "${deployCodeLocation} is not a git repository. Cloning ...."
  sudo git clone https://github.com/stakater/prod-deployment-reference.git ${deployCodeLocation};
fi;

