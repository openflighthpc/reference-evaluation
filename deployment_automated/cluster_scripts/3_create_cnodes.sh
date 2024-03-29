#!/bin/bash -l

compute_stackname="compute-${stackname}"
# shared code
# if cnode_prefix == "" then don't add to user data, other wise add line for that  in
login_root_contents=$(ssh -i "$keyfile" -o 'StrictHostKeyChecking=no' "flight@$login_public_ip" "sudo /bin/bash -l -c 'echo -n'; sudo cat /root/.ssh/id_alcescluster.pub")

userdata="#cloud-config\nwrite_files:\n  - content: |\n      SERVER=${login_private_ip}\n"

echo "$cnode_prefix"
echo "$userdata_broadcast"
if [[ $cnode_prefix != "" ]]; then
  userdata="$userdata      PREFIX=${cnode_prefix}\n"
fi
if [[ $userdata_broadcast != "" ]]; then
  userdata="${userdata}      BROADCAST_ADDRESS=\"$userdata_broadcast\"\n"
fi


if [[ $cloud_sharepubkey = true ]]; then
  end_userdata="    path: /opt/flight/cloudinit.in\n    permissions: '0644'\n    owner: root:root\nusers:\n  - default\n  - name: flight\n    ssh_authorized_keys:\n    - ${openflightkey}\n    "
else
  end_userdata="    path: /opt/flight/cloudinit.in\n    permissions: '0644'\n    owner: root:root\nusers:\n  - default\n  - name: root\n    ssh_authorized_keys:\n    - ${login_root_contents}\n  - name: flight\n    ssh_authorized_keys:\n    - ${openflightkey}\n    "
fi
userdata="$userdata$end_userdata"

openstack_cnode_base_file="openstack_templates/base.yaml"
openstack_computetemplate="log/templates/${stackname}_openstack_cnode_template.yaml"

computetemplate="changestack.yaml" 

aws_cnode_base_file="aws_templates/aws_base.yaml"
aws_compute_template="log/templates/${stackname}_aws_cnode_template.yaml"

azure_compute_template="azure_templates/multinode_azure.json"


spaced_cloudscript=$(echo -e "$userdata")
spaced_based_cloudscript=$(echo -e "$userdata" | base64 -w0) #cloudinit data spaced properly and in base64

# arrays containing ips regardless of platform
cnodes_public_ips=()
cnodes_private_ips=()
all_nodes_private_ip=("$login_private_ip")

case $platform in
  openstack)

    # openstack make compute node template
    cat $openstack_cnode_base_file > "$openstack_computetemplate"
    for x in `seq 1 $cnode_count`; do
    echo "
      node_port${x}:
        properties:
          network: ${stackname}-network
          security_groups:
            - ${stackname}-sg
        type: OS::Neutron::Port

      node${x}_floating_ip:
        type: OS::Neutron::FloatingIP
        properties:
          floating_network_id: { get_param: public_net }
          port_id: { get_resource: node_port${x} }

      node${x}_volume:
        type: OS::Cinder::Volume
        properties:
          size: { get_param: disk_size }
          image: { get_param: image }
      node${x}:
        properties:
          flavor: { get_param: flavor }
          image: { get_param: image }
          key_name: { get_param: key_name }
          networks:
          - port:
              get_resource: node_port${x}
          user_data_format: RAW
          user_data: { get_param: custom_data }
          block_device_mapping:
            - device_name: vda
              volume_id: { get_resource: node${x}_volume }
              delete_on_termination: true
        type: OS::Nova::Server" >> "$openstack_computetemplate"
    done
    echo "outputs:" >> "$openstack_computetemplate"
    for x in `seq 1 $cnode_count`; do
      echo "
      node${x}_ip:
        description: The private IP address of node1
        value: { get_attr: [node${x}, first_address] }
      node${x}_public_ip:
        description: Floating IP address of node1
        value: { get_attr: [ node${x}_floating_ip, floating_ip_address ] }" >> "$openstack_computetemplate"
    done
    # openstack compute template made

    # make a stack with the compute nodes
    redirect_out openstack stack create --wait --template "$openstack_computetemplate" --parameter "key_name=$openstack_public_key_name" --parameter "flavor=$openstack_compute_size" --parameter "image=$openstack_image_name" --parameter "login_node_ip=$login_private_ip" --parameter "login_node_key=$login_root_contents" "$compute_stackname" --parameter "custom_data=$spaced_cloudscript" --parameter "public_net=$openstack_public_network_name"  --parameter "disk_size=$compute_disk_size"; result=$?

    # confirm that cluster created successfully
    if [[ $result != 0 ]]; then
      echoplus -v 0 -c RED "Cnode stack creation failed. Exit code $result"
      exit $result
    fi

    echoplus -v 0 "login_public_ip=$login_public_ip"
    echoplus -v 0 "login_private_ip=$login_private_ip"

    # grab the ips and store them
    for x in `seq 1 $cnode_count`; do

      node_public_ip=$(openstack stack output show "$compute_stackname" "node${x}_public_ip" -f shell | grep "output_value") # output_value="10.151.15.235"
      node_public_ip=${node_public_ip#*\"} # 10.151.15.235"
      node_public_ip=${node_public_ip%\"*} # 10.151.15.235

      node_private_ip=$(openstack stack output show "$compute_stackname" "node${x}_ip" -f shell | grep "output_value")
      node_private_ip=${node_private_ip#*\"} 
      node_private_ip=${node_private_ip%\"*} 

      echoplus -v 0 "node${x}_public_ip=$node_public_ip"
      echoplus -v 0 "node${x}_private_ip=$node_private_ip"

      cnodes_private_ips+=("$node_private_ip")
      cnodes_public_ips+=("$node_public_ip")
    done
    ;;

  aws)
    # create template
    cat "$aws_cnode_base_file" > $aws_compute_template
    for x in `seq 1 $cnode_count`; do
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
            - $aws_security_group
          SubnetId: $aws_subnet
          BlockDeviceMappings:
            - DeviceName: /dev/sda1
              Ebs:
                VolumeType: gp2
                VolumeSize: 
                  Ref: InstanceDiskSize
                DeleteOnTermination: 'true'
                Encrypted: 'true'
          UserData: 
            Ref: UserData
                  " >> $aws_compute_template # add an instance to template for every node
    done
    echo "Outputs:" >> $aws_compute_template
    for x in `seq 1 $cnode_count`; do
      echo "
      PrivateIpNode${x}:
        Description: The private IP address of the standalone node
        Value: { Fn::GetAtt: [ Node${x}, PrivateIp] }

      PublicIpNode${x}:
        Description: Floating IP address of standalone node
        Value: { Fn::GetAtt: [ Node${x}, PublicIp ] }
        " >> $aws_compute_template # add an output to template for every node
    done

    # create stack
    redirect_out aws cloudformation create-stack --template-body "$(cat "$aws_compute_template")" --stack-name "$compute_stackname" --parameters "ParameterKey=KeyPair,ParameterValue=${aws_public_key_name},UsePreviousValue=false" "ParameterKey=InstanceAmi,ParameterValue=$aws_image_name,UsePreviousValue=false" "ParameterKey=InstanceSize,ParameterValue=$compute_instance_size,UsePreviousValue=false" "ParameterKey=SecurityGroup,ParameterValue=$aws_sgroup,UsePreviousValue=false" "ParameterKey=InstanceSubnet,ParameterValue=$aws_subnet,UsePreviousValue=false" "ParameterKey=IpData,ParameterValue=$login_private_ip,UsePreviousValue=false" "ParameterKey=KeyData,ParameterValue=$login_root_contents,UsePreviousValue=false" "ParameterKey=UserData,ParameterValue=$spaced_based_cloudscript,UsePreviousValue=false" "ParameterKey=InstanceDiskSize,ParameterValue=$compute_disk_size"

    redirect_out aws cloudformation wait stack-create-complete --stack-name "$compute_stackname"

    # get public and private ips
    for x in `seq 1 $cnode_count`; do
      cnodes_public_ips+=("$(aws cloudformation describe-stacks --stack-name "$compute_stackname" --output text | grep "PublicIpNode${x}" | grep -Pom 1 '[0-9.]{7,15}')")
      cnodes_private_ips+=("$(aws cloudformation describe-stacks --stack-name "$compute_stackname" --output text | grep "PrivateIpNode${x}" | grep -Pom 1 '[0-9.]{7,15}')")
    done
    ;;

  azure)

    # azure

    # azure make stack with compute nodes
    
    redirect_out az deployment group create --name "$compute_stackname" --debug --resource-group "$azure_resourcegroup" --template-file "$azure_compute_template" --parameters adminPublicKey="$azure_public_key_data" sourceimage="$azure_image_name" clustername="$stackname" customdatanode="$spaced_based_cloudscript" computeNodesCount="$cnode_count" computeinstancetype="$compute_instance_size" computedisksize="$compute_disk_size"

    #  computeinstancetype="$computetype" adminUsername="$adminname" adminPublicKey="$adminkey"

    echoplus -v 0 "login_public_ip=$login_public_ip"
    echoplus -v 0 "login_private_ip=$login_private_ip"

    # get public and private ips

    for x in `seq 1 $cnode_count`; do
      cnodes_public_ips+=("$(az vm list -d -o yaml --query "[?name=='${stackname}-cnode0${x}']" | grep "publicIps" | grep -Pom 1 '[0-9.]{7,15}')")
      cnodes_private_ips+=("$(az vm list -d -o yaml --query "[?name=='${stackname}-cnode0${x}']" | grep "privateIps" | grep -Pom 1 '[0-9.]{7,15}')")
    done
  ;;
esac

echoplus -v 3 "${cnodes_public_ips[*]}"
echoplus -v 3 "${cnodes_private_ips[*]}"
echoplus -v 3 "${all_nodes_private_ip[*]}"
# the same for all platforms

# Wait for compute nodes to be sshable\
for n in "${cnodes_public_ips[@]}"; do
  echoplus -v 2 "[$n] Trying SSH until connection is available. . ."
  timeout=360
  until ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' "flight@$n" 'exit'; do
    echoplus -v 2 -c ORNG -p "[$n] failed? \r"
    sleep 1
    let "timeout=timeout-1"
    if [[ $timeout -le 0 ]]; then
      echoplus -p -v 2 "\\n"
      echoplus -v 0 -c RED "[$n] SSH connection test timed out."
      exit 1
    fi
  done
  echoplus -p -v 2 "\\n"
  echoplus -v 2 -c GRN "[$n] SSH connection succeeded."
done

echoplus -v 2 "Finished testing ssh connection to compute nodes"
