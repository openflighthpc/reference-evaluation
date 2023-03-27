#!/bin/bash

stackname="multinode-101"
keyfile="ivan-keypair.pem"
instanceami="ami-00c0385bab48a6406"
instancesize="t3.small"
sgroup="sg-0f771e548fa4183ab"
subnet="subnet-55d8582f"
cnodetemplate="changestack.yaml" 
logindisk=20
nodecount=2


input=0

if [[ $input = 0 ]]; then
  echo "Name of stack?"
  read temp
  if [[ $temp != "" ]] ;then
    stackname="$temp"
  fi

  echo "Login disk size?"
  read temp
  if [[ $temp != "" ]] ;then
    logindisk="$temp"
  fi

  echo "Instance Size?"
  read temp
  if [[ $temp != "" ]] ;then
    instancesize="$temp"
  fi

#  echo "multisize template? "
#  read temp
#  if [[ $temp != "" ]] ;then
#    cnodetemplate="aws_multinode_multisize.yaml"
#  fi

  echo "Number of compute nodes"
  read temp
  if [[ $temp != "" ]] ;then
    nodecount="$temp"
  fi
fi

#echo "validate template"
#aws cloudformation validate-template --template-body "$(cat aws_standalone.yaml)"
#echo "finished validating"

echo "Create login node"

aws cloudformation create-stack --template-body "$(cat aws_standalone.yaml)" --stack-name "$stackname" --parameters "ParameterKey=KeyPair,ParameterValue=ivan-keypair,UsePreviousValue=false" "ParameterKey=InstanceAmi,ParameterValue=$instanceami,UsePreviousValue=false" "ParameterKey=InstanceSize,ParameterValue=$instancesize,UsePreviousValue=false" "ParameterKey=SecurityGroup,ParameterValue=$sgroup,UsePreviousValue=false" "ParameterKey=InstanceSubnet,ParameterValue=$subnet,UsePreviousValue=false" "ParameterKey=InstanceDiskSize,ParameterValue=$logindisk,UsePreviousValue=false"
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


#echo $contents

cat aws_base.yaml > $cnodetemplate
for x in `seq 1 $nodecount`; do
  echo "
  Node${x}:
    Type: AWS::EC2::Instance
    Properties: 
      ImageId: 
        Ref: InstanceAmi
      InstanceType: 
        Ref: InstanceSize
      KeyName: 
        Ref: KeyPair 
      SecurityGroupIds: 
        - sg-099219b43ee588b21
      SubnetId: subnet-55d8582f
      BlockDeviceMappings:
        - DeviceName: /dev/sda1
          Ebs:
            VolumeType: gp2
            VolumeSize: 
              Ref: InstanceDiskSize
            DeleteOnTermination: 'true'
            Encrypted: 'true'
      UserData: !Base64 
          Fn::Join:
            - ''
            - - \"#cloud-config\n\"
              - \"write_files:\n\"
              - \"  - content: |\n\"
              - \"      SERVER=\"
              - Ref: IpData
              - \"\n\"
              - \"    path: /opt/flight/cloudinit.in\n\"
              - \"    permissions: '0644'\n\"
              - \"    owner: root:root\n\"
              - \"users:\n\"
              - \"  - default\n\"
              - \"  - name: root\n\"
              - \"    ssh_authorized_keys:\n\"
              - \"      - \"
              - Ref: KeyData
              - \"\n\"
              - \"  - name: flight\n\"
              - \"    ssh_authorized_keys:\n\"
              - \"      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDWD9MAHnS5o6LrNaCb5gshU4BIpYfqoE2DCW9T2u3v4xOh04JkaMsIzwGc+BNnCh+NlkSE9sPVyPODCVnLnHdyyNfUkLBIUGCM/h9Ox7CTnsbmhnv3tMp4OD2dnGl+wOXWo/0YrWA0cpcl5UchCpZYMGscR4ohg8+/panBJ0//wmQZmCUZkQ20TLumYlL9HdmFl2SO2vraY+nBQCoHtPC80t4BmbPg5atEnQVMngpsRqSykIoUEQKh49t649cF3rBboZT+AmW+O1GWVYu7qlUxqIsdTRJbqbhZ/W2n3rraQh5CR/hOyYikkdn3xqm7Rom5iURvWd6QBh0LhP1UPRIT\"
              - \"\n\"
              " >> $cnodetemplate
done


aws cloudformation create-stack --template-body "$(cat "$cnodetemplate")" --stack-name "compute$stackname" --parameters "ParameterKey=KeyPair,ParameterValue=ivan-keypair,UsePreviousValue=false" "ParameterKey=InstanceAmi,ParameterValue=$instanceami,UsePreviousValue=false" "ParameterKey=InstanceSize,ParameterValue=$instancesize,UsePreviousValue=false" "ParameterKey=SecurityGroup,ParameterValue=$sgroup,UsePreviousValue=false" "ParameterKey=InstanceSubnet,ParameterValue=$subnet,UsePreviousValue=false" "ParameterKey=IpData,ParameterValue=$privIP,UsePreviousValue=false" "ParameterKey=KeyData,ParameterValue=$contents,UsePreviousValue=false"
