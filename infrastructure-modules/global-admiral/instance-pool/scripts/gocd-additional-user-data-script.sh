#######################################################################
# This script is an additional user-data script for GoCD module.
# NOTE: This is not a standalone script and is to be used with
#       combination of the bootstrap-user-data script.
#
# Download and place sudoers file in `/gocd-data/sudoers` to allow
# GoCD to use `sudo` without password
# Dowload and place `cruise-config.xml` to `/gocd-data/conf` to feed
# `cruise-config.xml` to GoCD at startup
#######################################################################
gocdDownloadDir="/gocd-downlaod"
mkdir -m 700 -p ${gocdDownloadDir}
cd ${gocdDownloadDir}

# List of config files to download
# Path relative to bucket
fileList+=()
fileList+=("gocd/conf/sudoers")
fileList+=("gocd/conf/cruise-config.xml")
fileList+=("gocd/conf/passwd")
fileList+=("gocd/scripts/build-ami.sh")
fileList+=("gocd/scripts/build-docker-image.sh")
fileList+=("gocd/scripts/deploy-to-cluster.sh")
fileList+=("gocd/scripts/docker-cleanup.sh")
fileList+=("gocd/scripts/gocd.parameteres.txt")
fileList+=("gocd/scripts/read-parameter.sh")
fileList+=("gocd/scripts/launch-ami.sh")
fileList+=("gocd/scripts/test-code.sh")
fileList+=("gocd/scripts/compile-code.sh")

# Download all files in the list
for f in "${fileList[@]}"
do
  resource="/${configBucket}/$f"
  create_string_to_sign
  signature=$(/bin/echo -n "$stringToSign" | openssl sha1 -hmac ${s3Secret} -binary | base64)
  debug_log
  curl -s -L -O -H "Host: ${configBucket}.s3.amazonaws.com" \
    -H "Content-Type: ${contentType}" \
    -H "Authorization: AWS ${s3Key}:${signature}" \
    -H "x-amz-security-token:${s3Token}" \
    -H "Date: ${dateValue}" \
    https://${configBucket}.s3.amazonaws.com/${f}
done

# Create gocd data directory
gocdDataDir="/gocd-data"
mkdir -p ${gocdDataDir}

# if sudoers file is downloaded and valid, copy to `gocd-data` directory
if [ -f ${gocdDownloadDir}/sudoers ] && grep -q "go" ${gocdDownloadDir}/sudoers ;
then
  sudoersDir="${gocdDataDir}/sudoers/"
  mkdir -p ${sudoersDir}
  cp ${gocdDownloadDir}/sudoers ${sudoersDir}/sudoers
fi

# if cruise-config file is downloaded and valid, copy to `gocd-data` directory
if [ -f ${gocdDownloadDir}/cruise-config.xml ] && grep -q "pipeline" ${gocdDownloadDir}/cruise-config.xml ;
then
  confDir="${gocdDataDir}/conf/"
  mkdir -p ${confDir}
  cp ${gocdDownloadDir}/cruise-config.xml ${confDir}/cruise-config.xml
  # Change permissions of conf directory and all of its contents (wanted by gocd server)
  chown -R 999:999 ${confDir}
fi
# if sudoers file is downloaded and valid, copy to `gocd-data` directory
if [ -f ${gocdDownloadDir}/passwd ]  ;
then
  cp ${gocdDownloadDir}/passwd ${gocdDataDir}/passwd
fi

# if script files from script folder have been dwnloaded, copy to `gocd-data` directory
gocdScriptsDir="${gocdDataDir}/scripts/"
mkdir -p ${gocdScriptsDir}
if [ -f ${gocdDownloadDir}/bake-ami.sh ] ;
then
  cp ${gocdDownloadDir}/bake-ami.sh ${gocdScriptsDir}/bake-ami.sh
fi
if [ -f ${gocdDownloadDir}/build-docker-image.sh ] ;
then
  cp ${gocdDownloadDir}/build-docker-image.sh ${gocdScriptsDir}/build-docker-image.sh
fi
if [ -f ${gocdDownloadDir}/deploy-to-cluster.sh ] ;
then
  cp ${gocdDownloadDir}/deploy-to-cluster.sh ${gocdScriptsDir}/deploy-to-cluster.sh
fi
if [ -f ${gocdDownloadDir}/docker-cleanup.sh ] ;
then
  cp ${gocdDownloadDir}/docker-cleanup.sh ${gocdScriptsDir}/docker-cleanup.sh
fi
if [ -f ${gocdDownloadDir}/gocd.parameters.txt ] ;
then
  cp ${gocdDownloadDir}/gocd.parameters.txt ${gocdScriptsDir}/gocd.parameters.txt
fi
if [ -f ${gocdDownloadDir}/read-parameter.sh ] ;
then
  cp ${gocdDownloadDir}/read-parameter.sh ${gocdScriptsDir}/read-parameter.sh
fi
if [ -f ${gocdDownloadDir}/launch-ami.sh ] ;
then
  cp ${gocdDownloadDir}/launch-ami.sh ${gocdScriptsDir}/launch-ami.sh
fi
if [ -f ${gocdDownloadDir}/test-code.sh ] ;
then
  cp ${gocdDownloadDir}/test-code.sh ${gocdScriptsDir}/test-code.sh
fi
if [ -f ${gocdDownloadDir}/compile-code.sh ] ;
then
  cp ${gocdDownloadDir}/compile-code.sh ${gocdScriptsDir}/compile-code.sh
fi

# Delete temporary downloads folder
rm -rf ${gocdDownloadDir}