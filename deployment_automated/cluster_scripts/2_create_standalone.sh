#!/bin/bash -l

if [[ $standalone = true ]]; then
  echoplus -v 2 "Creating standalone cluster . . ."
else
  echoplus -v 2 "Creating login node . . ."
fi

# openstack

case $platform in

  openstack)
    # create standalone/login node on Openstack
    redirect_out openstack stack create --wait --template "$openstack_login_template" --parameter "public_net=$openstack_public_network_name" --parameter "key_name=$openstack_public_key_name" --parameter "flavor=$login_instance_size" --parameter "image=$openstack_image_name"  --parameter "disk_size=$login_disk_size" --parameter "cloud_config=$spaced_login_cloudscript" "$stackname"; result=$?
    image_name=${openstack_image_name}
    if [[ $result != 0 ]]; then
      echoplus -v 0 -c RED "Creation failed. Exiting."
      exit $result
    fi

    # put openflight public key onto standalone node
    ssh -i "$keyfile" -o 'StrictHostKeyChecking=no' "flight@$pubIP" "sudo echo \"$openflightkey\" >> .ssh/authorized_keys"
    # get contents if making a cluster
    #contents=$(ssh -i "$keyfile" -o 'StrictHostKeyChecking=no' "flight@$pubIP" "sudo /bin/bash -l -c 'echo -n'; sudo cat /root/.ssh/id_alcescluster.pub")


    # Get public IP
    login_public_ip=$(openstack stack output show "$stackname" standalone_public_ip -f shell | grep "output_value")
    login_public_ip=${login_public_ip#*\"} 
    login_public_ip=${login_public_ip%\"*} 
    # Get private IP
    login_private_ip=$(openstack stack output show "$stackname" standalone_ip -f shell | grep "output_value")
    login_private_ip=${login_private_ip#*\"} #removes stuff upto // from begining
    login_private_ip=${login_private_ip%\"*} #removes stuff from / all the way to end
    ;;

  aws)
    # AWS

    # make the standalone/login node
    redirect_out aws cloudformation create-stack --template-body "$(cat $aws_login_template)" --stack-name "$stackname" --parameters "ParameterKey=KeyPair,ParameterValue=${aws_public_key_name},UsePreviousValue=false" "ParameterKey=InstanceAmi,ParameterValue=${aws_image_name},UsePreviousValue=false" "ParameterKey=InstanceSize,ParameterValue=${login_instance_size},UsePreviousValue=false" "ParameterKey=InstanceDiskSize,ParameterValue=${login_disk_size},UsePreviousValue=false" "ParameterKey=CloudInit,ParameterValue=${spaced_based_login_cloudscript},UsePreviousValue=false"
    image_name=${aws_image_name}
    echoplus -v 2 "Checking that stack was created. . ."

    redirect_out aws cloudformation wait stack-create-complete --stack-name $stackname

    login_public_ip=$(aws cloudformation describe-stacks --stack-name $stackname --output text | grep "PublicIp" | grep -Pom 1 '[0-9.]{7,15}')
    login_private_ip=$(aws cloudformation describe-stacks --stack-name $stackname --output text | grep "PrivateIp" | grep -Pom 1 '[0-9.]{7,15}')
    aws_security_group=$(aws cloudformation describe-stack-resources --stack-name $stackname --query 'StackResources[?ResourceType==`AWS::EC2::SecurityGroup`]' | grep "PhysicalResourceId" | grep -o '"PhysicalResourceId": "[^"]*"' | grep -o 'sg-[^"]*')
    aws_subnet=$(aws cloudformation describe-stack-resources --stack-name $stackname --query 'StackResources[?ResourceType==`AWS::EC2::Subnet`]' | grep "PhysicalResourceId" | grep -o '"PhysicalResourceId": "[^"]*"' | grep -o 'subnet-[^"]*')

    ;;

  azure) # azure

    redirect_out az deployment group create  --name "$login_name"  --resource-group "$azure_resourcegroup"  --template-file "$azure_login_template" --parameters adminPublicKey="$azure_public_key_data" sourceimage=$azure_image_name clustername="$stackname" cheadinstancetype=$login_instance_size customdatanode="$spaced_based_login_cloudscript"; success=$?
    echoplus -v 3 "$login_name"
    image_name=${azure_image_name}
    if [[ $success != "0" ]];then
      exit 1
    fi
    completed="false"
    timeout=60

    while [[ $completed != "true" ]];do
      vm_status=$(az vm list -d -o yaml --query "[?name=='${stackname}-chead1']" | grep "provisioningState")
      if [[ $vm_status = "  provisioningState: Succeeded" ]];then
        echoplus -v 2 "provisioning completed"
        completed="true"
      elif [[ $timeout -le 0 ]]; then
        echoplus -v 0 -c RED "CREATION TIMED OUT"
        exit 1
      fi
      let "timeout-=1"
    done

    # get private and public ips
    login_private_ip=$(az vm list -d -o yaml --query "[?name=='${stackname}-chead1']" | grep "privateIps" | grep -Pom 1 '[0-9.]{7,15}')
    login_public_ip=$(az vm list -d -o yaml --query "[?name=='${stackname}-chead1']" | grep "publicIps" | grep -Pom 1 '[0-9.]{7,15}')
    echoplus -v 3 "$login_private_ip"
    echoplus -v 3 "$login_public_ip"

  ;;
esac


if [[ $standalone = true ]]; then
  echoplus -v 2 "Created standalone cluster."
else
  echoplus -v 2 "Created login node."
fi

# Wait for login/standalone node to come online
echoplus -v 2 "Trying SSH until connection is available. . ."
echoplus -v 3 "keyfile: ${keyfile}"
timeout=60
until ssh -q -i "$keyfile" -o 'StrictHostKeyChecking=no' "flight@$login_public_ip" 'exit'; do
  echoplus -v 2 -c ORNG -p "failed? \r"
  sleep 1
  let "timeout=timeout-1"
  if [[ $timeout -le 0 ]]; then
    echoplus -p -v 2 "\\n"
    echoplus -v 0 -c RED "SSH connection test timed out."
    exit 1
  fi
done
echoplus -p -v 2 "\\n"
echoplus -v 2 -c GRN "SSH connection succeeded."