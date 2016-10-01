#######################################################################
# This script is an additional user-data script for modules that require
# registry certificates
# NOTE: This is not a standalone script and is to be used with
#       combination of the bootstrap-user-data script.
#######################################################################

regCertDir="/etc/registry-certificates"
mkdir -m 700 -p ${regCertDir}
cd ${regCertDir}

regCertFile="docker-registry/registry-certificates/ca.pem"

resource="/${configBucket}/${regCertFile}"
create_string_to_sign
signature=$(/bin/echo -n "$stringToSign" | openssl sha1 -hmac ${s3Secret} -binary | base64)
debug_log
curl -s -L -O -H "Host: ${configBucket}.s3.amazonaws.com" \
  -H "Content-Type: ${contentType}" \
  -H "Authorization: AWS ${s3Key}:${signature}" \
  -H "x-amz-security-token:${s3Token}" \
  -H "Date: ${dateValue}" \
  https://${configBucket}.s3.amazonaws.com/${regCertFile}

# if ca.pem file is downloaded and is a valid certificate copy to docker registry certificate location
# else delete the downloaded files
if [ -f ${regCertDir}/ca.pem ] && grep -q "BEGIN CERTIFICATE" ${regCertDir}/ca.pem ;
then
  dockerCertDir="/etc/docker/certs.d/registry.${stackName}.local/"
  mkdir -p ${dockerCertDir}
  #NOTE: Rename the ca.pem file to ca.crt
  mv ${regCertDir}/ca.pem ${regCertDir}/ca.crt
  cp ${regCertDir}/ca.crt ${dockerCertDir}/ca.crt
else
  rm -f ${regCertFile}/*
fi
