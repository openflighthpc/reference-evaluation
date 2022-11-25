#!/bin/bash

echo "what to name stack?"
read STACKNAME

echo "key used to access cluster?"
read KEYFILE

echo "Create standalone cluster"
#openstack stack create --template standalone-template.yaml --parameter "key_name=keytest1" --parameter "flavor=m1.small" --parameter "image=Flight Solo 2022.4" "$STACKNAME"
aws cloudformation create-stack --template-body "$(cat aws_standalone.yaml)" --stack-name $STACKNAME --parameters "KeyPair=ivan-keypair,InstanceAmi=ami-04b88ad7b25bc74ef,InstanceSize=t3.small,SecurityGroup=sg-099219b43ee588b21,InstanceSubnet=subnet-55d8582f"
echo "WORKED?"

aws cloudformation wait stack-create-complete --stack-name $STACKNAME


pubIP=$(aws cloudformation describe-stacks --stack-name $STACKNAME --output text | grep "PrivateIp" | grep -Pom 1 '[0-9.]{7,15}')
privIP=$(aws cloudformation describe-stacks --stack-name $STACKNAME --output text | grep "PublicIp" | grep -Pom 1 '[0-9.]{7,15}')


# now get value of 
# have to wait for login node to come online
until ssh -i "$KEYFILE" -o 'StrictHostKeyChecking=no' "flight@$pubIP" 'exit'; do
  echo "failed?"
  sleep 5
done

echo "succeeded?"

contents=$(ssh -i "$KEYFILE" -o 'StrictHostKeyChecking=no' "flight@$pubIP" "sudo /bin/bash -l -c 'echo -n'; sudo cat /root/.ssh/id_alcescluster.pub")


echo $contents

aws cloudformation create-stack --template-body "$(cat aws_multinode.yaml)" --stack-name "compute$STACKNAME" --parameters "KeyPair=ivan-keypair,InstanceAmi=ami-04b88ad7b25bc74ef,InstanceSize=t3.small,SecurityGroup=sg-099219b43ee588b21,InstanceSubnet=subnet-55d8582f,IpData=$privIP,Keydata=$contents"
