#!/usr/bin/env bash
REPO=$1
DEPLOY_CODE_LOCATION=$2

if [ ! -d "${DEPLOY_CODE_LOCATION}" ];
then
  echo "Ceating Directory."
  sudo mkdir -p ${DEPLOY_CODE_LOCATION}
else
  echo "Directory Already Exists."
fi;

if [ -d ${DEPLOY_CODE_LOCATION}/.git ]; then
  echo "${DEPLOY_CODE_LOCATION} is a git repository.";
else
  echo "${DEPLOY_CODE_LOCATION} is not a git repository. Cloning ...."
  sudo git clone ${REPO} ${DEPLOY_CODE_LOCATION};
fi;