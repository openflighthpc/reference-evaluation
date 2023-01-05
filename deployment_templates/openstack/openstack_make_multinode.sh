#!/bin/bash

echo "make sure to source openstack project file!"


echo "What should the stack be named?"
read STACKNAME

echo "What is the key used to access cluster?"
read KEYFILE



echo "Creating standalone cluster. . ."
openstack stack create --template standalone-template.yaml --parameter "key_name=keytest1" --parameter "flavor=m1.small" --parameter "image=Flight Solo 2022.4" "$STACKNAME"

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



pubIP=$(openstack stack output show "$STACKNAME" standalone_public_ip -f shell | grep "output_value")
pubIP=${pubIP#*\"} #removes stuff upto // from begining
pubIP=${pubIP%\"*} #removes stuff from / all the way to end
echo $pubIP


privIP=$(openstack stack output show "$STACKNAME" standalone_ip -f shell | grep "output_value")
privIP=${privIP#*\"} #removes stuff upto // from begining
privIP=${privIP%\"*} #removes stuff from / all the way to end
echo $privIP

# now get value of 
# have to wait for login node to come online
until ssh -i "$KEYFILE" -o 'StrictHostKeyChecking=no' "flight@$pubIP" 'exit'; do
  echo "failed?"
  sleep 5
done

echo "succeeded?"

contents=$(ssh -i "$KEYFILE" -o 'StrictHostKeyChecking=no' "flight@$pubIP" "sudo /bin/bash -l -c 'echo -n'; sudo cat /root/.ssh/id_alcescluster.pub")


echo $contents

cloudscript="#cloud-config\nwrite_files:\n  - content: |\n      SERVER=$privIP\n    path: /opt/flight/cloudinit.in\n    permissions: '0644'\n    owner: root:root\nusers:\n  - default\n  - name: root\n    ssh_authorized_keys:\n    - $contents\n"
cloudtranslat=$(echo -e "$cloudscript" | base64 -w0)
cloudinit=$(echo -e "$cloudscript")

openstack stack create --template passwordless-nodes-template.yaml --parameter "key_name=keytest1" --parameter "flavor=m1.small" --parameter "image=Flight Solo 2022.4" --parameter "login_node_ip=$privIP" --parameter "login_node_key=$contents" "compute$STACKNAME" --parameter "custom_data=$cloudinit"
