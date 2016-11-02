#!/bin/bash
# Clones production deployment code
#----------------------------------
# Argument1: APP_NAME
#----------------------------------

APP_NAME=$1

# Clone deployment code
deployCodeLocation="/app/stakater/prod-deployment-reference-${APP_NAME}"

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

