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

# This shell script cleans docker images
#--------------------------------------------
# Argument1: APP_DOCKER_IMAGE
#--------------------------------------------

APP_DOCKER_IMAGE=$1
# Check number of parameters equals 1
if [ "$#" -ne 1 ]; then
    echo "ERROR: [Docker Clean Up] Illegal number of parameters"
    exit 1
fi

# Delete orphaned docker images with <none> repository and tag
#--------------------------------------------
echo "Delete Empty Docker Images ...";
deleteImage()
{
  images="sudo docker images | grep 'none' | awk '{print $3}' | xargs sudo docker rmi"
  echo "Deleting images..."
  bash -c "$images"
}

cmd="sudo docker images | grep 'none' | awk '{print $3}'"
count=$(bash -c "$cmd")
echo $count
if [ -n "$count" ]
then
  deleteImage || true
  echo "Images Deleted Successfully!"
else
  echo "No empty Docker images found."
fi

# Delete Old tagged images
old_images=$(sudo docker images | grep $APP_DOCKER_IMAGE | grep 'latest' -v | awk 'NR!=1{print $3}')

if [[ ! -z "$old_images" ]]
then
  echo "Old images with tags are $old_images."
  echo "Deleting them"
  sudo docker rmi $old_images
else
  echo "No Old images with tags found"
fi
