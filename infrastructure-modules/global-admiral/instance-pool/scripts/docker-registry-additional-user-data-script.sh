#######################################################################
# This script is an additional user-data script for Docker Registry module.
# NOTE: This is not a standalone script and is to be used with
#       combination of the bootstrap-user-data script.
#
# Download `upload-registry-certs.sh` from docker_registry to /etc/scripts
# Downloading this script will allow gen-certificate.service to generate
# certificates then upload them to s3
#######################################################################
aws_region=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}');

scriptsDir="/etc/scripts"
mkdir -m 700 -p ${scriptsDir}
cd ${scriptsDir}

uploadScriptFile="docker-registry/upload-registry-certs.sh"

resource="/${configBucket}/${uploadScriptFile}"
create_string_to_sign
signature=$(/bin/echo -n "$stringToSign" | openssl sha1 -hmac ${s3Secret} -binary | base64)
debug_log

retry=5
ready=0
#Retry 5 times untill file is downloaded
until [[ $retry -eq 0 ]]  || [[ $ready -eq 1  ]]
do
  curl -s -L -O -H "Host: ${configBucket}.s3-${aws_region}.amazonaws.com" \
    -H "Content-Type: ${contentType}" \
    -H "Authorization: AWS ${s3Key}:${signature}" \
    -H "x-amz-security-token:${s3Token}" \
    -H "Date: ${dateValue}" \
    https://${configBucket}.s3-${aws_region}.amazonaws.com/${uploadScriptFile}

  if [ -f ${scriptsDir}/upload-registry-certs.sh ] ;
  then
    ready=1
  else
    let "retry--"
  fi
done
# make script file executable
chmod a+x upload-registry-certs.sh