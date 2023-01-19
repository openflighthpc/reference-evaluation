#!/bin/bash

echo "WARNING: make sure to source openstack project file!"


echo "What should the stack be named?"
read STACKNAME

keyfile="key1.pem"
echo "What is the key file used to access cluster?"
read temp
if [[ $temp != "" ]]; then
  keyfile="$temp"
fi

keyname="keytest1"
echo "What is the key name used to create the cluster?"
read temp
if [[ $temp != "" ]]; then
  keyname="$temp"
fi

loginsize="m1.small"
echo "What is the instance size of the login node?"
read temp
if [[ $temp != "" ]]; then
  loginsize="$temp"
fi

computesize="m1.small"
echo "What is the instance size of the compute nodes?"
read temp
if [[ $temp != "" ]]; then
  computesize="$temp"
fi

logindisksize="20"
echo "What is the volume size of the login node?"
read temp
if [[ $temp != "" ]]; then
  logindisksize="$temp"
fi

computedisksize="20"
echo "What is the volume size of the compute nodes?"
read temp
if [[ $temp != "" ]]; then
  computedisksize="$temp"
fi

loginimage="Flight Solo 2023.1-1701231900"
computeimage="Flight Solo 2023.1-1701231900"

echo "Creating standalone cluster. . ."
openstack stack create --template standalone-template.yaml --parameter "key_name=$keyname" --parameter "flavor=$loginsize" --parameter "image=$loginimage" --parameter "disk_size=$logindisksize" "$STACKNAME"

completed=false
timeout=120
while [[ $completed != true ]]; do # just a little loop to not wait an excessive amount of time
  stack_status=$(openstack stack show "$STACKNAME" -f shell | grep "stack_status")
  stack_status=${stack_status#*\"} #removes stuff upto // from begining
  stack_status=${stack_status%\"*} #removes stuff from / all the way to end
  stack_status=${stack_status%\"*} 
  stack_status=${stack_status%\"*}

  echo $stack_status
  if [[ "$stack_status" = 'CREATE_COMPLETE' ]];then
    completed=true
  elif [[ $timeout -le 0 ]];then
    echo "stack creation timed out"
    exit 1 
  else
    let "timeout=timeout-1"
    sleep 1
  fi
done


echo "public ip:"
pubIP=$(openstack stack output show "$STACKNAME" standalone_public_ip -f shell | grep "output_value")
pubIP=${pubIP#*\"} #removes stuff upto // from begining
pubIP=${pubIP%\"*} #removes stuff from / all the way to end
echo $pubIP

echo "private ip:"
privIP=$(openstack stack output show "$STACKNAME" standalone_ip -f shell | grep "output_value")
privIP=${privIP#*\"} #removes stuff upto // from begining
privIP=${privIP%\"*} #removes stuff from / all the way to end
echo $privIP

# now get value of 
# have to wait for login node to come online
until ssh -i "$keyfile" -o 'StrictHostKeyChecking=no' "flight@$pubIP" 'exit'; do
  echo "failed?"
  sleep 5
done

echo "succeeded?"

contents=$(ssh -i "$keyfile" -o 'StrictHostKeyChecking=no' "flight@$pubIP" "sudo /bin/bash -l -c 'echo -n'; sudo cat /root/.ssh/id_alcescluster.pub")


echo $contents

cloudscript="#cloud-config\nwrite_files:\n  - content: |\n      SERVER=$privIP\n    path: /opt/flight/cloudinit.in\n    permissions: '0644'\n    owner: root:root\nusers:\n  - default\n  - name: root\n    ssh_authorized_keys:\n    - $contents\n"
cloudtranslat=$(echo -e "$cloudscript" | base64 -w0)
cloudinit=$(echo -e "$cloudscript")

openstack stack create --template passwordless-nodes-template.yaml --parameter "key_name=$keyname" --parameter "flavor=$computesize" --parameter "image=$computeimage" --parameter "login_node_ip=$privIP" --parameter "login_node_key=$contents" "compute$STACKNAME" --parameter "custom_data=$cloudinit" --parameter "disk_size=$computedisksize"
