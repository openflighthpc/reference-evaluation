#!/bin/bash

echo "deployment name?"
read DEPLOYNAME

echo "options level:"
read OPTLVL

# necessary info
loginname="$DEPLOYNAME""-login"
computename="$DEPLOYNAME""-compute"
keyfile="ivan-azure_key.pem"
resourcegroup="resourceful-ivan"
logintemplate="standalone-test-template.json"
computetemplate="multi-2.json"  #"multinode-template-test.json"
vmachinename="test3"
pubIPname="test3-ip"
netinterface="test3405"
ipconfigname="ipconfig1"

# Useful info if the setup needs to be slightly changed/ someone else is using these templates
azurekey="ivan-azure_key"
netsgid="/subscriptions/a41c5728-46d9-4f9c-aefe-ffd2a83df476/resourceGroups/resourceful-ivan/providers/Microsoft.Network/networkSecurityGroups/ivan-sg2"
vnetid="/subscriptions/a41c5728-46d9-4f9c-aefe-ffd2a83df476/resourceGroups/resourceful-ivan/providers/Microsoft.Network/virtualNetworks/resourceful-ivan-vnet"


# somewhat useful info, should very rarely change
location="uksouth"
subnet="default"
vmachRG="$resourcegroup" # may not need
osdisktype="StandardSSD_LRS"


#auto management parameters
osdiskdelopt="Delete"
autoshut_status="Enabled"
autoshut_time="18:00"
autoshut_timezone="UTC"
autoshut_locale="en"
autoshut_email="ivan.kruse@openflighthpc.org"

# why does azure give me so much customisation?
adminname="flight"

datadisks='[
                {
                    "lun": 0,
                    "createOption": "attach",
                    "deleteOption": "Delete",
                    "caching": "ReadOnly",
                    "writeAcceleratorEnabled": false,
                    "id": null,
                    "name": "test3_DataDisk_0",
                    "storageAccountType": null,
                    "diskSizeGB": null,
                    "diskEncryptionSet": null
                }
            ]'
datadiskresources="[
                {
                    "name": "test3_DataDisk_0",
                    "sku": "Premium_LRS",
                    "properties": {
                        "diskSizeGB": 1024,
                        "creationData": {
                            "createOption": "empty"
                        }
                    }
                }
            ]"

vmsize="Standard_DS1_v2"


# I don't know if these would change, or even what some of them are
pubIPtype="Static"
pubIPsku="Standard"
pipdelopt="Detach"
vmachinecompname="$vmachinename"
nicdelopt="Detach"


# priority level 0 customisation:

#echo "What IP configuration name?"
ipconfigname="$DEPLOYNAME""-ipconfig"

#echo "What public IP address name?"
pubIPname="$DEPLOYNAME""-publicIP"

# priority level 1 customisation:
if [[ $OPTLVL -ge 1 ]]; then

  echo "What resource group?"
  read temp ; if [[ $temp != "" ]] ; then  resourcegroup="$temp" ; fi

  echo "What network interface name?"
  read temp; if [[ $temp != "" ]] ; then  netinterface="$temp"; fi

  echo "What public Ip address name?"

  echo "What subnet name?"
  read temp; if [[ $temp != "" ]] ; then  subnetName="$temp"; fi

  echo "What instance size?"
  read temp; if [[ $temp != "" ]] ; then  virtualMachineSize="$temp"; fi

#  echo "What name for virtual machine?"
# read temp; if [[ $temp != "" ]] ; then  vmachinename="$temp"; fi

# echo "What name for virtual machine computer?"
# read temp; if [[ $temp != "" ]] ; then  vmachinecompname="$temp"; fi

  echo "What virtual network (ID) ?"
  read temp; if [[ $temp != "" ]] ; then  virtualNetworkId="$temp"; fi

  echo "What network security group? (ID)"
  read temp; if [[ $temp != "" ]] ; then  netsgid="$temp"; fi
fi

#priority0="ipConfigurationName=$ipconfigname publicIpAddressName=$pubIPname"
#priority1="virtualMachineRG=$resourcegroup networkInterfaceName=$netinterface networkSecurityGroupId=$netsgid subnetName=$subnet virtualNetworkId=$vnetid virtualMachineName=$vmachinename virtualMachineComputerName=$vmachinecompname virtualMachineSize=$vmsize"
#priority2=" location=$location osDiskType=$osdisktype "
#priority3=" dataDisks=$datadisks dataDiskResources=$datadiskresources "
#priority4=" osDiskDeleteOption=$osdiskdelopt publicIpAddressSku=$pubIPsku publicIpAddressType=$pubIPtype nicDeleteOption=$nicdelopt pipDeleteOption=$pipdelopt adminUsername=$adminname adminPublicKey=$azurekey autoShutdownStatus=$autoshut_status autoShutdownTime=$autoshut_time autoShutdownTimeZone=$autoshut_timezone autoShutdownNotificationStatus=$autoshut_status autoShutdownNotificationLocale=$autoshut_locale autoShutdownNotificationEmail=$autoshut_email "



az deployment group create  --name "$DEPLOYNAME"  --resource-group "$resourcegroup"  --template-file "$logintemplate" --parameters ipConfigurationName=$ipconfigname publicIpAddressName=$pubIPname virtualMachineRG=$resourcegroup networkInterfaceName=$netinterface networkSecurityGroupId=$netsgid subnetName=$subnet virtualNetworkId=$vnetid virtualMachineName=$loginname virtualMachineComputerName=$loginname virtualMachineSize=$vmsize ; success=$?

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
az deployment group create --name "$DEPLOYNAME" --resource-group "$resourcegroup" --template-file "$computetemplate" --parameters ipConfigurationName=$ipconfigname publicIpAddressName=$pubIPname virtualMachineRG=$resourcegroup networkInterfaceName=$netinterface networkSecurityGroupId=$netsgid subnetName=$subnet virtualNetworkId=$vnetid virtualMachineName=$computename virtualMachineComputerName=$computename virtualMachineSize=$vmsize loginKeyData="$keydata" ipData=$ipdata 




