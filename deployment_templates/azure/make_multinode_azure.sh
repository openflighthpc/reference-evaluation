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
computestemplate="template-test.json"
vmachinename="test3"
pubIPname="test3-ip"
netinterface="test3405"

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

# priority level 1 customisation:
if [[ $OPTLVL -ge 1 ]]; then

  echo "What resource group?"
  read temp; if [[ $temp != "" ]]; then ; resourcegroup="$temp"; fi

  echo "What network interface name?"
  read temp; if [[ $temp != "" ]]; then ; netinterface="$temp"; fi

  echo "What public Ip address name?"
  read temp; if [[ $temp != "" ]]; then ; pubIPname="$temp"; fi

  echo "What subnet name?"
  read temp; if [[ $temp != "" ]]; then ; subnetName="$temp"; fi

  echo "What instance size?"
  read temp; if [[ $temp != "" ]]; then ; virtualMachineSize="$temp"; fi

  echo "What name for virtual machine?"
  read temp; if [[ $temp != "" ]]; then ; vmachinename="$temp"; fi

  echo "What name for virtual machine computer?"
  read temp; if [[ $temp != "" ]]; then ; vmachinecompname="$temp"; fi

  echo "What virtual network (ID) ?"
  read temp; if [[ $temp != "" ]]; then ; virtualNetworkId="$temp"; fi

  echo "What network security group? (ID)"
  read temp; if [[ $temp != "" ]]; then ; netsgid="$temp"; fi
fi


priority1=" virtualMachineRG=$resourcegroup networkInterfaceName=$netinterface networkSecurityGroupId=$netsgid subnetName=$subnet virtualNetworkId=$vnetid publicIpAddressName=$pubIPname virtualMachineName=$vmachinename virtualMachineComputerName=$vmachinecompname virtualMachineSize=$vmsize "
priority2=" location=$location osDiskType=$osdisktype "
priority3=" dataDisks=$datadisks dataDiskResources=$datadiskresources "
priority4=" osDiskDeleteOption=$osdiskdelopt publicIpAddressSku=$pubIPsku publicIpAddressType=$pubIPtype nicDeleteOption=$nicdelopt pipDeleteOption=$pipdelopt adminUsername=$adminname adminPublicKey=$azurekey autoShutdownStatus=$autoshut_status autoShutdownTime=$autoshut_time autoShutdownTimeZone=$autoshut_timezone autoShutdownNotificationStatus=$autoshut_status autoShutdownNotificationLocale=$autoshut_locale autoShutdownNotificationEmail=$autoshut_email "



az deployment group create  --name "$DEPLOYNAME"  --resource-group "$resourcegroup"  --template-file "$logintemplate" \
--parameters "$priority1"


