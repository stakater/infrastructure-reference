aws_region=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}');
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
fileList+=("gocd/scripts/git-cloner.sh")
fileList+=("gocd/scripts/build-admiral-ami.sh")
fileList+=("gocd/scripts/clone-deployment-application-code.sh")
fileList+=("gocd/scripts/clean-up.sh")
fileList+=("gocd/scripts/build-docker-image.sh")
fileList+=("gocd/scripts/deploy-to-cluster.sh")
fileList+=("gocd/scripts/deploy-to-admiral.sh")
fileList+=("gocd/scripts/deploy-to-admiral-ami.sh")
fileList+=("gocd/scripts/deploy-to-prod.sh")
fileList+=("gocd/scripts/destroy-BG-group.sh")
fileList+=("gocd/scripts/docker-cleanup.sh")
fileList+=("gocd/scripts/gocd.parameters.txt")
fileList+=("gocd/scripts/bg.parameters.txt")
fileList+=("gocd/scripts/read-parameter.sh")
fileList+=("gocd/scripts/rollback-deployment.sh")
fileList+=("gocd/scripts/switch-deployment-group.sh")
fileList+=("gocd/scripts/terraform-apply-changes.sh")
fileList+=("gocd/scripts/test-code.sh")
fileList+=("gocd/scripts/update-blue-green-deployment-groups.sh")
fileList+=("gocd/scripts/update-deployment-state.sh")
fileList+=("gocd/scripts/compile-code.sh")
fileList+=("gocd/scripts/delete-ami.sh")
fileList+=("gocd/scripts/write-ami-parameters.sh")
fileList+=("gocd/scripts/write-terraform-variables.sh")
fileList+=("gocd/scripts/sort-and-combine-comma-separated-list.sh")
fileList+=("gocd/scripts/resume-ASG-processes.sh")
fileList+=("gocd/scripts/start-infra.sh")
fileList+=("gocd/scripts/start-instances.sh")
fileList+=("gocd/scripts/stop-infra.sh")
fileList+=("gocd/scripts/stop-instances.sh")
fileList+=("gocd/scripts/suspend-ASG-processes.sh")

# Download all files in the list
for f in "${fileList[@]}"
do
  resource="/${configBucket}/$f"
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
      https://${configBucket}.s3-${aws_region}.amazonaws.com/${f}

    # Extract filename from file path
    filename="${f##*/}"
    if [ -f ${gocdDownloadDir}/${filename} ] ;
    then
      ready=1
    else
      let "retry--"
    fi
  done
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
  mkdir -p ${gocdDataDir}/gocd-passwd
  cp ${gocdDownloadDir}/passwd ${gocdDataDir}/gocd-passwd/passwd
fi
sudo rm -r ${gocdDownloadDir}/passwd ${gocdDownloadDir}/cruise-config.xml ${gocdDownloadDir}/sudoers
# if script files from script folder have been dwnloaded, copy to `gocd-data` directory
gocdScriptsDir="${gocdDataDir}/scripts/"
mkdir -p ${gocdScriptsDir}
cp ${gocdDownloadDir}/* ${gocdScriptsDir}/
chmod +x ${gocdScriptsDir}/*
# Delete temporary downloads folder
rm -rf ${gocdDownloadDir}
