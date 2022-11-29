#!/bin/bash

stackname="multinode"
keyfile="ivan-keypair.pem"
instanceami="ami-04b88ad7b25bc74ef"
instancesize="t3.small"
sgroup="sg-099219b43ee588b21"
subnet="subnet-55d8582f"


echo "Name of stack?"
read temp
if [[ $temp != "" ]] ;then
  stackname="$temp"
fi

echo "Key to access cluster?"
read temp
if [[ $temp != "" ]] ;then
  keyfile="$temp"
fi

echo "Instance AMI ID?"
read temp
if [[ $temp != "" ]] ;then
  instanceami="$temp"
fi

echo "Instance Size? "
read temp
if [[ $temp != "" ]] ;then
  instancesize="$temp"
fi

echo "Security Group ID?"
read temp
if [[ $temp != "" ]] ;then
  sgroup="$temp"
fi

echo "Instance Subnet?"
read temp
if [[ $temp != "" ]] ;then
  subnet="$temp"
fi


echo "what to name stack?"
read STACKNAME


echo "Create standalone cluster"
#openstack stack create --template standalone-template.yaml --parameter "key_name=keytest1" --parameter "flavor=m1.small" --parameter "image=Flight Solo 2022.4" "$stackname"

aws cloudformation create-stack --template-body "$(cat aws_standalone.yaml)" --stack-name "$stackname" --parameters "ParameterKey=KeyPair,ParameterValue=ivan-keypair,UsePreviousValue=false" "ParameterKey=InstanceAmi,ParameterValue=$instanceami,UsePreviousValue=false" "ParameterKey=InstanceSize,ParameterValue=$instancesize,UsePreviousValue=false" "ParameterKey=SecurityGroup,ParameterValue=$sgroup,UsePreviousValue=false" "ParameterKey=InstanceSubnet,ParameterValue=$subnet,UsePreviousValue=false"
echo "WORKED?"

aws cloudformation wait stack-create-complete --stack-name $stackname


pubIP=$(aws cloudformation describe-stacks --stack-name $stackname --output text | grep "PublicIp" | grep -Pom 1 '[0-9.]{7,15}')
echo "IP of login node: $pubIP"
privIP=$(aws cloudformation describe-stacks --stack-name $stackname --output text | grep "PrivateIp" | grep -Pom 1 '[0-9.]{7,15}')


# now get value of 
# have to wait for login node to come online
until ssh -i "$keyfile" -o 'StrictHostKeyChecking=no' "flight@$pubIP" 'exit'; do
  echo "failed?"
  sleep 5
done

echo "succeeded?"

contents=$(ssh -i "$keyfile" -o 'StrictHostKeyChecking=no' "flight@$pubIP" "sudo /bin/bash -l -c 'echo -n'; sudo cat /root/.ssh/id_alcescluster.pub")


echo $contents

aws cloudformation create-stack --template-body "$(cat aws_multinode.yaml)" --stack-name "compute$stackname" --parameters "ParameterKey=KeyPair,ParameterValue=ivan-keypair,UsePreviousValue=false" "ParameterKey=InstanceAmi,ParameterValue=$instanceami,UsePreviousValue=false" "ParameterKey=InstanceSize,ParameterValue=$instancesize,UsePreviousValue=false" "ParameterKey=SecurityGroup,ParameterValue=$sgroup,UsePreviousValue=false" "ParameterKey=InstanceSubnet,ParameterValue=$subnet,UsePreviousValue=false" "ParameterKey=IpData,ParameterValue=$privIP,UsePreviousValue=false" "ParameterKey=KeyData,ParameterValue=$contents,UsePreviousValue=false"
