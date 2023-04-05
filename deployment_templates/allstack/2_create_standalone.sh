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
    openstack stack create --template "$openstack_login_template" --parameter "key_name=$openstack_key" --parameter "flavor=$openstack_login_size" --parameter "image=$openstack_image"  --parameter "disk_size=$login_disk_size" "$stackname" 

    # wait for it to finish being created
    completed=false
    timeout=120
    while [[ $completed != true ]]; do 
      stack_status=$(openstack stack show "$stackname" -f shell | grep "stack_status=")
      stack_status=${stack_status#*\"} #removes string from start to first "
      stack_status=${stack_status%\"*} #removes string from end to first "

      if [[ "$stack_status" = 'CREATE_COMPLETE' ]];then
        completed=true
        echoplus -c GRN -v 2 -p "$stack_status    "
        echoplus -p "\\n"
      elif [[ $timeout -le 0 ]];then
        echoplus -p "\\n"
        echoplus -c RED -v 0 "stack creation timed out"
        exit 1
      elif [[ "$stack_status" = 'CREATE_FAILED' ]];then
        echoplus -c RED -v 0 -p "$stack_status""$(openstack stack show "$stackname" -f shell | grep "stack_status_reason=")"
        echoplus -p "\\n"
        exit 1
      else
        echoplus -c ORNG -v 2 -p "$stack_status\r"
        let "timeout=timeout-1"
        sleep 1
      fi
    done

    # Get public IP
    login_public_ip=$(openstack stack output show "$stackname" standalone_public_ip -f shell | grep "output_value")
    login_public_ip=${login_public_ip#*\"} #removes stuff upto // from begining
    login_public_ip=${login_public_ip%\"*} #removes stuff from / all the way to end
    # Get private IP
    login_private_ip=$(openstack stack output show "$stackname" standalone_ip -f shell | grep "output_value")
    login_private_ip=${login_private_ip#*\"} #removes stuff upto // from begining
    login_private_ip=${login_private_ip%\"*} #removes stuff from / all the way to end
    ;;

  aws)
    # AWS

    # make the standalone/login node
    aws cloudformation create-stack --template-body "$(cat $aws_login_template)" --stack-name "$stackname" --parameters "ParameterKey=KeyPair,ParameterValue=${aws_key},UsePreviousValue=false" "ParameterKey=InstanceAmi,ParameterValue=${aws_image},UsePreviousValue=false" "ParameterKey=InstanceSize,ParameterValue=${aws_login_size},UsePreviousValue=false" "ParameterKey=SecurityGroup,ParameterValue=${aws_sgroup},UsePreviousValue=false" "ParameterKey=InstanceSubnet,ParameterValue=${aws_subnet},UsePreviousValue=false" "ParameterKey=InstanceDiskSize,ParameterValue=${login_disk_size},UsePreviousValue=false"

    echoplus -v 2 "Checking that stack was created. . ."

    aws cloudformation wait stack-create-complete --stack-name $stackname

    login_public_ip=$(aws cloudformation describe-stacks --stack-name $stackname --output text | grep "PublicIp" | grep -Pom 1 '[0-9.]{7,15}')
    login_private_ip=$(aws cloudformation describe-stacks --stack-name $stackname --output text | grep "PrivateIp" | grep -Pom 1 '[0-9.]{7,15}')
    ;;

  azure) # azure

    az deployment group create  --name "$login_name"  --resource-group "$azure_resourcegroup"  --template-file "$azure_login_template" --parameters sourceimage=$azure_image clustername="$stackname" cheadinstancetype=$azure_login_size customdatanode="$azure_login_based_cloudscript" ; success=$?
    echo "$login_name"

    if [[ $success != "0" ]];then
      exit 1
    fi
    completed="false"
    timeout=60

    while [[ $completed != "true" ]];do
      vm_status=$(az vm list -d -o yaml --query "[?name=='${stackname}-chead1']" | grep "provisioningState")
      if [[ $vm_status = "  provisioningState: Succeeded" ]];then
        echo "true"
        completed="true"
      elif [[ $timeout -le 0 ]]; then
        echo "ERR TIMED OUT"
        exit 1
      fi
      let "timeout-=1"
    done

    # get private and public ips
    login_private_ip=$(az vm list -d -o yaml --query "[?name=='${stackname}-chead1']" | grep "privateIps" | grep -Pom 1 '[0-9.]{7,15}')
    login_public_ip=$(az vm list -d -o yaml --query "[?name=='${stackname}-chead1']" | grep "publicIps" | grep -Pom 1 '[0-9.]{7,15}')
    echo "$login_private_ip"
    echo "$login_public_ip"

  ;;
esac


if [[ $standalone = true ]]; then
  echoplus -v 2 "Created standalone cluster."
else
  echoplus -v 2 "Created login node."
fi

# Wait for login/standalone node to come online
echoplus -v 2 "Trying SSH until connection is available. . ."
echo "keyfile: ${keyfile}"
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