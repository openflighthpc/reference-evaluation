#!/bin/bash

echo "cluster name?"
read DEPLOYNAME
loginname="$DEPLOYNAME""-chead1"
computename="$DEPLOYNAME""-compute"

echo "standalone? (leave blank for no)"
read STANDALONE

clustype="Standard_DS1_v2"
echo "instance size? (default is Standard_DS1_v2)"
read temp

if [[ $temp != "" ]]; then
  clustype="$temp"
fi
# actual necessary info
logintemplate="standalone_azure.json"
computetemplate="multinode_azure.json"  
srcimage="/subscriptions/a41c5728-46d9-4f9c-aefe-ffd2a83df476/resourceGroups/openflight-images/providers/Microsoft.Compute/images/SOLO2-2022.4-1411221728"
logintype="$clustype"
computetype="$clustype"
computes=2
keyfile="ivan-azure_key.pem"
location="uksouth"
adminkey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDXqGRCY+Rx/cu5qokWOAU5UsH8D8xgbv32sxKZ01Tyuu1arV5be8lG+m4f2can3ZRNbTAx7oUFCncFfy5F5QFMMUCi0QNhCHmn7rnniRikq8Qlb9LgueUk0GaopbakT2w0BEdJv0lmlBh7Vyti2G7MUuuthqDUzU/vKgsgWQ7ImU8r91ecMJ56SoMIOCSqpRxbcx1mEzoedv3JqJeS/pypph2+j9NdrbEipBtZYCjRkAqgqyfWrPgqvg3I+L0YnN5JMlROA5IdRPfWEZnCOi+KV0zRyvdAp4mXYwjyluN2zXckSAYl0x3JAkfiofpce63H3/aNgSxMtXLvvimMWADhdY20aLikRMWRGh+fngogibCfZTNyCuseT2IMuxjI0S+EcBKcO6kDRCPaqVNOcaElgg4cX7xueVKAK8fL2rP6ngpwR7NYEUzy7fhy8eCL1Vpl1PnDLLzttG0p7KrGFWqliTEirmodL5MN/4QzRdp/srqJdqVvvQk9opZvSY7Iqt0= generated-by-azure"
adminname="flight"

# necessary info
resourcegroup="resourceful-ivan"

# Useful info if the setup needs to be slightly changed/ someone else is using these templates
azurekey="ivan-azure_key"


logincloudscript="#cloud-config\nusers:\n  - default\n  - name: flight\n    ssh_authorized_keys:\n    - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDWD9MAHnS5o6LrNaCb5gshU4BIpYfqoE2DCW9T2u3v4xOh04JkaMsIzwGc+BNnCh+NlkSE9sPVyPODCVnLnHdyyNfUkLBIUGCM/h9Ox7CTnsbmhnv3tMp4OD2dnGl+wOXWo/0YrWA0cpcl5UchCpZYMGscR4ohg8+/panBJ0//wmQZmCUZkQ20TLumYlL9HdmFl2SO2vraY+nBQCoHtPC80t4BmbPg5atEnQVMngpsRqSykIoUEQKh49t649cF3rBboZT+AmW+O1GWVYu7qlUxqIsdTRJbqbhZ/W2n3rraQh5CR/hOyYikkdn3xqm7Rom5iURvWd6QBh0LhP1UPRIT\n    "
logindatatrans=$(echo -e "$logincloudscript" | base64 -w0)

az deployment group create  --name "$loginname"  --resource-group "$resourcegroup"  --template-file "$logintemplate" --parameters sourceimage=$srcimage clustername=$DEPLOYNAME cheadinstancetype=$logintype customdatanode="$logindatatrans" ; success=$?

if [[ $STANDALONE != "" ]];then
  echo "standalone node created"
  exit 0
fi

if [[ $success != "0" ]];then
  exit 1
fi


completed="false"
timeout=60

while [[ $completed != "true" ]];do
  vm_status=$(az vm list -d -o yaml --query "[?name=='$loginname']" | grep "provisioningState")
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
privIP=$(az vm list -d -o yaml --query "[?name=='$loginname']" | grep "privateIps" | grep -Pom 1 '[0-9.]{7,15}')
pubIP=$(az vm list -d -o yaml --query "[?name=='$loginname']" | grep "publicIps" | grep -Pom 1 '[0-9.]{7,15}')


# now get value of
# have to wait for login node to come online
until ssh -i "$keyfile" -o 'StrictHostKeyChecking=no' "flight@$pubIP" 'exit'; do
  echo "connecting . . . "
  sleep 5
done

echo "succeeded?"

contents=$(ssh -i "$keyfile" -o 'StrictHostKeyChecking=no' "flight@$pubIP" "sudo /bin/bash -l -c 'echo -n'; sudo cat /root/.ssh/id_alcescluster.pub")

#echo $contents

# so that creates a standalone node, now time to create a multinode thing

ipdata="$privIP"
keydata="$contents"
cloudscript="#cloud-config\nwrite_files:\n  - content: |\n      SERVER=$ipdata\n    path: /opt/flight/cloudinit.in\n    permissions: '0644'\n    owner: root:root\nusers:\n  - default\n  - name: root\n    ssh_authorized_keys:\n    - $keydata\n  - name: flight\n    ssh_authorized_keys:\n    - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDWD9MAHnS5o6LrNaCb5gshU4BIpYfqoE2DCW9T2u3v4xOh04JkaMsIzwGc+BNnCh+NlkSE9sPVyPODCVnLnHdyyNfUkLBIUGCM/h9Ox7CTnsbmhnv3tMp4OD2dnGl+wOXWo/0YrWA0cpcl5UchCpZYMGscR4ohg8+/panBJ0//wmQZmCUZkQ20TLumYlL9HdmFl2SO2vraY+nBQCoHtPC80t4BmbPg5atEnQVMngpsRqSykIoUEQKh49t649cF3rBboZT+AmW+O1GWVYu7qlUxqIsdTRJbqbhZ/W2n3rraQh5CR/hOyYikkdn3xqm7Rom5iURvWd6QBh0LhP1UPRIT\n    "
cloudtranslat=$(echo -e "$cloudscript" | base64 -w0)
az deployment group create --name "$DEPLOYNAME" --debug --resource-group "$resourcegroup" --template-file "$computetemplate" --parameters sourceimage="$srcimage" clustername="$DEPLOYNAME" customdatanode="$cloudtranslat" computeNodesCount=2
#  computeinstancetype="$computetype" adminUsername="$adminname" adminPublicKey="$adminkey"

echo "Complete."
echo "Get started by connecting to:"
echo "$pubIP"

 
