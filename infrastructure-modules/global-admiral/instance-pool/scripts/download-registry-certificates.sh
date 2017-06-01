#######################################################################
# This script is an additional user-data script for modules that require
# registry certificates
# NOTE: This is not a standalone script and is to be used with
#       combination of the bootstrap-user-data script.
#######################################################################
aws_region=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}');

regCertDir="/etc/registry-certificates"
mkdir -m 700 -p ${regCertDir}
cd ${regCertDir}

regCertFile="docker-registry/registry-certificates/ca.pem"

resource="/${configBucket}/${regCertFile}"
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
    https://${configBucket}.s3-${aws_region}.amazonaws.com/${regCertFile}

  if [ -f ${regCertDir}/ca.pem && grep -q "BEGIN CERTIFICATE" ${regCertDir}/ca.pem ] ;
  then
    ready=1
  else
    let "retry--"
  fi
done

# if ca.pem file is downloaded and is a valid certificate copy to docker registry certificate location
# else delete the downloaded files
if [ -f ${regCertDir}/ca.pem ] && grep -q "BEGIN CERTIFICATE" ${regCertDir}/ca.pem ;
then
  dockerCertDir="/etc/docker/certs.d/${stackName}-registry:5000/"
  mkdir -p ${dockerCertDir}
  #NOTE: Rename the ca.pem file to ca.crt
  mv ${regCertDir}/ca.pem ${regCertDir}/ca.crt
  cp ${regCertDir}/ca.crt ${dockerCertDir}/ca.crt
else
  rm -f ${regCertFile}/*
fi
