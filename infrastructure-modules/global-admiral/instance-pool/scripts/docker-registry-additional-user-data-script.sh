#######################################################################
# This script is an additional user-data script for Docker Registry module.
# NOTE: This is not a standalone script and is to be used with
#       combination of the bootstrap-user-data script.
#
# Download `upload-registry-certs.sh` from docker_registry to /etc/scripts
# Downloading this script will allow gen-certificate.service to generate
# certificates then upload them to s3
#######################################################################

scriptsDir="/etc/scripts"
mkdir -m 700 -p ${scriptsDir}
cd ${scriptsDir}

uploadScriptFile="docker-registry/upload-registry-certs.sh"

resource="/${configBucket}/${uploadScriptFile}"
create_string_to_sign
signature=$(/bin/echo -n "$stringToSign" | openssl sha1 -hmac ${s3Secret} -binary | base64)
debug_log
curl -s -L -O -H "Host: ${configBucket}.s3.amazonaws.com" \
  -H "Content-Type: ${contentType}" \
  -H "Authorization: AWS ${s3Key}:${signature}" \
  -H "x-amz-security-token:${s3Token}" \
  -H "Date: ${dateValue}" \
  https://${configBucket}.s3.amazonaws.com/${uploadScriptFile}

# make script file executable
chmod a+x upload-registry-certs.sh