#! /bin/bash
AWS_REGION=""
DEPLOY_STATE_KEY=""
APP_NAME=""
DEPLOY_INSTANCE_TYPE="t2.micro" # default value
ENABLE_SSL=false;
INTERNAL_SUPPORT=false;

kOptionFlag=false;
rOptionFlag=false;
aOptionFlag=false;
# Get options from the command line
while getopts ":k:r:a:i:s:t:" OPTION
do
    case $OPTION in
        k)
          DEPLOY_STATE_KEY=$OPTARG
          kOptionFlag=true;
          ;;
        r)
          rOptionFlag=true;
          AWS_REGION=$OPTARG
          ;;
        a)
          aOptionFlag=true;
          APP_NAME=$OPTARG
          ;;
        i)
          DEPLOY_INSTANCE_TYPE=$OPTARG
          ;;
        s)
          ENABLE_SSL=$OPTARG
          ;;
        t)
          INTERNAL_SUPPORT=$OPTARG
          ;;
        *)
          echo "Usage: $(basename $0) -k <key for the state file> -r <aws-region> -a <app-name> -i <deploy instance type> -s <Enable SSL ? > (optional) -t <INTERNAL SUPPORT ? > (optional)"
          exit 0
          ;;
    esac
done

if ! $kOptionFlag || ! $rOptionFlag || ! $aOptionFlag;
then
  echo "Usage: $(basename $0) -k <key for the state file> -r <aws-region> -a <app-name> -i <deploy instance type> -s <Enable SSL ? > (optional) -t <INTERNAL SUPPORT ? > (optional)"
  exit 0;
fi

##################
# AMI Params
##################
AMI_PARAMS_FILE="/app/${APP_NAME}/cd/vars/${APP_NAME}_ami_params.txt"
# Check ami params file exist
if [ ! -f ${AMI_PARAMS_FILE} ];
then
   echo "Error: [Deploy-to-AMI] AMI parameters file not found";
   exit 1;
fi;

# Read parameter values from file
AMI_ID=`/gocd-data/scripts/read-parameter.sh ${AMI_PARAMS_FILE} AMI_ID`
# Check parameter values not empty
if test -z ${AMI_ID};
then
   echo "Error: Value for AMI ID not defined.";
   exit 1;
fi;
##############################################

# Update blue green deployment group
/gocd-data/scripts/update-blue-green-deployment-groups.sh ${APP_NAME} ${AMI_ID} ${AWS_REGION} ${DEPLOY_INSTANCE_TYPE} ${DEPLOY_STATE_KEY} ${ENABLE_SSL} ${INTERNAL_SUPPORT}

