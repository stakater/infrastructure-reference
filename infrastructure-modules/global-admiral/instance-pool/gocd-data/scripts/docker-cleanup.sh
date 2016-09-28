#!/bin/bash
# Delete orphaned docker images with <none> repository and tag
#--------------------------------------------

echo "Delete Empty Docker Images ...";
deleteImage()
{
  images="sudo docker images | grep 'none' | awk '{print $3}' | xargs sudo docker rmi"
  echo "Deleting images..."
  bash -c "$images"
}

cmd="sudo docker images | grep 'none'"
count=$(bash -c "$cmd")
echo $count
if [ -n "$count" ]
then
  deleteImage || true
  echo "Images Deleted Successfully!"
else
  echo "No empty Docker images found."
fi

