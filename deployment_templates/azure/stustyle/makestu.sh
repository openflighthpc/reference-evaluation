#!/bin/bash

echo "cluster name?"
read DEPLOYNAME
loginname="$DEPLOYNAME""-chead1"
computename="$DEPLOYNAME""-compute"


# actual necessary info
logintemplate="standalonestu.json"
computetemplate="computestu.json"  
srcimage="/subscriptions/a41c5728-46d9-4f9c-aefe-ffd2a83df476/resourceGroups/openflight-images/providers/Microsoft.Compute/images/SOLO2-2022.4-1411221728"
logintype="Standard_DS1_v2"
computetype="Standard_DS1_v2"
computes="2"
keyfile="../ivan-azure_key.pem"
location="uksouth"

# necessary info
resourcegroup="resourceful-ivan"

# Useful info if the setup needs to be slightly changed/ someone else is using these templates
azurekey="ivan-azure_key"



# priority level 0 customisation:

ipconfigname="$DEPLOYNAME""-ipconfig"
pubIPname="$DEPLOYNAME""-publicIP"



az deployment group create  --name "$loginname"  --resource-group "$resourcegroup"  --template-file "$logintemplate" --parameters sourceimage=$srcimage clustername=$DEPLOYNAME cheadinstancetype=$logintype ; success=$?


if [[ $success != "0" ]];then
  exit 1
fi

completed="false"
timeout=120

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

echo $contents


# so that creates a standalone node, now time to create a multinode thing

ipdata="$privIP"
keydata="$contents"
cloudscript="#cloud-config\nwrite_files:\n  - content: |\n      SERVER=$ipdata\n    path: /opt/flight/cloudinit.in\n    permissions: '0644'\n    owner: root:root\nusers:\n  - name: root\n    ssh_authorized_keys:\n      -$keydata\n"

cloudtranslat=$(echo "$cloudscript" | base64 -w0)
#az deployment group create --name "$DEPLOYNAME" --resource-group "$resourcegroup" --template-file "$computetemplate" --parameters ipConfigurationName=$ipconfigname publicIpAddressName=$pubIPname virtualMachineRG=$resourcegroup networkInterfaceName=$netinterface networkSecurityGroupId=$netsgid subnetName=$subnet virtualNetworkId=$vnetid virtualMachineName=$computename virtualMachineComputerName=$computename virtualMachineSize=$vmsize loginKeyData="$keydata" ipData=$ipdata 


echo "done"

