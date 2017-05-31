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

# This script stops Stack for specified ',' separated environments in the current region
#----------------------------------------------
# Argument1: ENVIRONMENTS
#----------------------------------------------

#Input Parameters
ENVIRONMENTS=$1
# Check number of parameters equals 1
if [ "$#" -ne 1 ]; then
    echo "ERROR: [Test Code] Illegal number of parameters"
    exit 1
fi
#check environment variable length... must be greater than 1
if [ ${#ENVIRONMENTS} -le 1 ]; then
    echo "ERROR: [Test Code] Illegal parameter value"
    exit 1
fi
region=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
region=${region::-1}

/gocd-data/scripts/suspend-ASG-processes.sh $ENVIRONMENTS $region
/gocd-data/scripts/stop-instances.sh $ENVIRONMENTS $region

