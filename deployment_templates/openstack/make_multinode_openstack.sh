#!/bin/bash

outputlvl=2
varfile="config.in"
config="0"
noinput="0"
#CONSTANTS
RED='\033[0;31m'
GRN='\033[0;32m'
ORNG='\033[0;33m'
NC='\033[0m' # No Color


# Parameters: stackname, loginsize, logindisksize, standalone, computetemplate, computesize, computedisksize, keyfile, keyname, logintemplate, srcimage

# defaults
srcimage="Flight Solo 2023.2"
loginsize="m1.medium"
logindisksize="20"
standalone=false
computetemplate="compute-nodes-template.yaml"
computesize="m1.medium"
computedisksize="20"
cluster_type="slurm"
nodecount=2
cram_testing=false # do cram testing
generic_size="small"
small="m1.medium"
medium="m1.large"
large="m1.xlarge"
gpu="0"
delete_ending=false
only_basic_tests=false

while [[ $# -gt 0 ]]; do # while there are not 0 args
  case $1 in
    -v|--verbose)
      outputlvl=3
      shift # past argument
      ;;
    -q|--quiet)
      outputlvl=1
      shift # past argument
      ;;
    -d|--delete-on-end)
      delete_ending=true
      shift # past argument
      ;;
    --only-basic-tests)
      only_basic_tests=true
      shift # past argument
      ;;
    -g|--generic-size)
      generic_size=0
      shift # past argument
      ;;
    --noinput)
      noinput=1 
      shift # past argument
      ;;
    -p|--parameter) # -p var_name=value
      in="$2"
      var=${in%=*}
      val=${in#*=}
      declare "${var}"="$val"
      shift # past argument
      shift # past value
      ;;
    -h|--help)
      echo "-n, --nodecount NUM                         number of compute nodes"
      echo "-v, --verbose                               more output"
      echo "-q, --quiet                                 less output"
      echo "-c, --config                                use config file instead of manual input"
      echo '-p, --parameter "PARAMETERNAME=PARAMETER"   pass a parameter to the program'
      echo "--noinput                                   program won't ask for input"
      exit 0
      shift # past argument
      ;;
    -*|--*)
      echo -e "${RED}Unknown option $1 ${NC}"
      echo "Try '--help' for more information."
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

echoplus(){
  text=()
  verbosity="$outputlvl"
  colour="NC"
  print=false
  while [[ $# -gt 0 ]]; do # while there are not 0 args
    case $1 in
      -v|--verbosity)
        verbosity="$2"
        shift # past argument
        shift # past value
        ;;
      -c|--colour)
        colour="$2"
        shift # past argument
        shift # past value
        ;;
      -p|--print)
        print=true
        shift # past argument
        ;;
      -*|--*)
        echo -e "${RED}Unknown option $1 ${NC}"
        exit 1
        ;;
      *)
        text+=("$1") # save positional arg
        shift # past argument
        ;;
    esac
  done
  if [[ "$verbosity" -le "$outputlvl" ]];then
    if [[ "$colour" = "NC" ]];then
      if [[ $print = true ]];then printf "${text[*]}"; else echo "${text[*]}"; fi
    else
      if [[ $print = true ]];then printf "${!colour}""${text[*]}""${NC}"; else echo -e "${!colour}""${text[*]}""${NC}"; fi
    fi
  fi
}

# option that disables input requests (without affecting other output)

#verbose all output
#normal no source openstack message, no extra ip output, ssh/stack create progress, errors, ip output
#quiet no warnings, only errors and ip output

echo "test"
echoplus -c ORNG -v 3 "WARNING: make sure to source openstack project file!"



if [[ "$noinput" == "0" && $config == "0" ]]; then

  echoplus -v 0 "What should the stack be named?"
  read stackname

  echoplus -v 0 "Create only standalone?"
  read temp
  if [[ $temp != "" ]]; then
    standalone=true
  fi

  echoplus -v 0 "Perform cram testing?"
  read temp
  if [[ temp != "" ]]; then
    cram_testing=true
  fi

  if [[ $cram_testing = true ]]; then
    echoplus -v 0 "What cluster type? (slurm/jupyter/kube)"
    read temp
    if [[ temp != "" ]]; then
      cluster_type="$temp"
    fi
  fi

  echoplus -v 0 "What is the instance size of the login node?"
  read temp
  if [[ $temp != "" ]]; then
    loginsize="$temp"
  fi

  echoplus -v 0 "What is the volume size of the login node?"
  read temp
  if [[ $temp != "" ]]; then
    logindisksize="$temp"
  fi

  

  if [[ $standalone = false ]]; then
   echoplus -v 0 "How many compute nodes to use?"
   read temp
   if [[ $temp != "" ]]; then
      nodecount="$temp"
    fi

    echoplus -v 0 "What is the instance size of the compute nodes?"
    read temp
    if [[ $temp != "" ]]; then
      computesize="$temp"
    fi

    echoplus -v 0 "What is the volume size of the compute nodes?"
    read temp
    if [[ $temp != "" ]]; then
      computedisksize="$temp"
    fi
  fi
fi

if [[ "$generic_size" = "0" ]]; then
  eval loginsize='$'$loginsize
  eval computesize='$'$computesize
fi

keyfile="key1.pem"
keyname="keytest1"
logintemplate="login-node-template.yaml"
openflightkey='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDWD9MAHnS5o6LrNaCb5gshU4BIpYfqoE2DCW9T2u3v4xOh04JkaMsIzwGc+BNnCh+NlkSE9sPVyPODCVnLnHdyyNfUkLBIUGCM/h9Ox7CTnsbmhnv3tMp4OD2dnGl+wOXWo/0YrWA0cpcl5UchCpZYMGscR4ohg8+/panBJ0//wmQZmCUZkQ20TLumYlL9HdmFl2SO2vraY+nBQCoHtPC80t4BmbPg5atEnQVMngpsRqSykIoUEQKh49t649cF3rBboZT+AmW+O1GWVYu7qlUxqIsdTRJbqbhZ/W2n3rraQh5CR/hOyYikkdn3xqm7Rom5iURvWd6QBh0LhP1UPRIT'
echoplus -v 3 -c ORNG "$srcimage"
standaloneCloudinit="
#cloud-config\nusers:\n  - default\n  - name: flight\n    ssh_authorized_keys:\n    - $openflightkey\n    "
echoplus -v 2 "Creating standalone cluster. . ."

openstack stack create --template "$logintemplate" --parameter "key_name=$keyname" --parameter "flavor=$loginsize" --parameter "image=$srcimage"  --parameter "disk_size=$logindisksize" "$stackname" >> /dev/null


completed=false
timeout=120
while [[ $completed != true ]]; do # just a little loop to not wait an excessive amount of time
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

echoplus -v 3 "public ip:"
pubIP=$(openstack stack output show "$stackname" standalone_public_ip -f shell | grep "output_value")
pubIP=${pubIP#*\"} #removes stuff upto // from begining
pubIP=${pubIP%\"*} #removes stuff from / all the way to end
echoplus -v 3 "$pubIP"

echoplus -v 3 "private ip:"
privIP=$(openstack stack output show "$stackname" standalone_ip -f shell | grep "output_value")
privIP=${privIP#*\"} #removes stuff upto // from begining
privIP=${privIP%\"*} #removes stuff from / all the way to end
echoplus -v 3 "$privIP"

# now get value of 
# have to wait for login node to come online
echoplus -v 2 "Trying SSH until connection is available. . ."
timeout=360
until ssh -q -i "$keyfile" -o 'StrictHostKeyChecking=no' "flight@$pubIP" 'exit'; do
  echoplus -v 2 -p "failed? \r"
  #sleep 5
done
echoplus -p -v 2 "\\n"
echoplus -v 2 -c GRN "SSH connection succeeded."

ssh -i "$keyfile" -o 'StrictHostKeyChecking=no' "flight@$pubIP" "sudo echo \"$openflightkey\" >> .ssh/authorized_keys"

contents=$(ssh -i "$keyfile" -o 'StrictHostKeyChecking=no' "flight@$pubIP" "sudo /bin/bash -l -c 'echo -n'; sudo cat /root/.ssh/id_alcescluster.pub")

if [[ $standalone = true ]];then
  echoplus -v 0 "login_public_ip=$pubIP"
  echoplus -v 0 "login_private_ip=$privIP"
  if [[ $only_basic_tests = true ]]; then
    # setup cram testing
    scp -r "../../regression_tests" "flight@${pubIP}:/home/flight/" &>/dev/null
    ssh -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" 'sudo pip3 install cram; sudo yum install -y nmap' &>/dev/null
    default_kube_range="192.168.0.0/16"
    default_node_range="10.50.0.0/16"
    test_env_file="/home/flight/regression_tests/environment_variables.sh"
    env_contents="#!/bin/bash\nexport all_nodes_count='1'\nexport computenodescount='0'\nexport ip_range='${default_node_range}'\nexport kube_pod_range='${default_kube_range}'\nexport login_priv_ip='${privIP}'\nexport login_pub_ip='${pubIP}'\nexport all_nodes_priv_ips=( '${privIP}' )\nexport varlocation='${test_env_file}'" 
    ssh -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" "echo -e \"${env_contents}\" > ${test_env_file}" &>/dev/null
    cram_command="cram -v generic_launch_tests/allnode-generic_launch_tests generic_launch_tests/login-check_root_login.t flight_launch_tests/allnode-flight_launch_tests flight_launch_tests/login-hunter_info.t"
    ssh -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" "cd /home/flight/regression_tests; . environment_variables.sh; bash setup.sh; $cram_command > /home/flight/cram_test_\$?.out"
    exit
  elif [[ $cram_testing = false ]]; then
    exit
  fi
  # setup cram testing
  scp -r "../../regression_tests" "flight@${pubIP}:/home/flight/" &>/dev/null
  ssh -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" 'sudo pip3 install cram; sudo yum install -y nmap' &>/dev/null
  default_kube_range="192.168.0.0/16"
  default_node_range="10.50.0.0/16"
  test_env_file="/home/flight/regression_tests/environment_variables.sh"
  env_contents="#!/bin/bash\nexport all_nodes_count='1'\nexport computenodescount='0'\nexport ip_range='${default_node_range}'\nexport kube_pod_range='${default_kube_range}'\nexport login_priv_ip='${privIP}'\nexport login_pub_ip='${pubIP}'\nexport all_nodes_priv_ips=( '${privIP}' )\nexport varlocation='${test_env_file}'" 
  ssh -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" "echo -e \"${env_contents}\" > ${test_env_file}" &>/dev/null
  cram_command="cram -v generic_launch_tests/allnode-generic_launch_tests generic_launch_tests/login-check_root_login.t flight_launch_tests/allnode-flight_launch_tests flight_launch_tests/login-hunter_info.t pre-profile_tests"
  case $cluster_type in 
    jupyter)
      cram_command="$cram_command profile_tests/jupyter_standalone cluster_tests/jupyter_standalone"
      ;;
    slurm)
      cram_command="$cram_command profile_tests/slurm_standalone cluster_tests/slurm_standalone"
      ;;
  esac
  ssh -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" "cd /home/flight/regression_tests; . environment_variables.sh; bash setup.sh; $cram_command > cram_test.out"

  scp -i "$keyfile" "flight@${pubIP}:/home/flight/regression_tests/cram_test.out" "../test_output/${stackname}_cram_test.out"

  # if you want to delete then go for it
  if [[ $delete_ending = true ]]; then 
    openstack stack delete -y "$stackname"
    timeout=60
    deleted=false
    while [[ $deleted = false ]]; do # just a little loop to not wait an excessive amount of time
      if ! [[ $(openstack stack show "$stackname" -f shell | grep "Stack not found:") ]]; then
        exit 0
      elif [[ $timeout -le 0 ]];then
        echoplus -p "\\n"
        echoplus -c RED -v 0 "stack deletion timed out"
        exit 1
      else
        echoplus -c ORNG -v 2 -p "$stack_status\r"
        let "timeout=timeout-1"
        sleep 1
      fi
    done
  fi

  exit
fi


echoplus -v 3 $contents

cloudscript="#cloud-config\nwrite_files:\n  - content: |\n      SERVER=$privIP\n    path: /opt/flight/cloudinit.in\n    permissions: '0644'\n    owner: root:root\nusers:\n  - default\n  - name: root\n    ssh_authorized_keys:\n    - $contents\n  - name: flight\n    ssh_authorized_keys:\n    - $openflightkey\n    "
cloudtranslat=$(echo -e "$cloudscript" | base64 -w0)
cloudinit=$(echo -e "$cloudscript")


computetemplate="changestack.yaml"
cat base.yaml > "$computetemplate"

for x in `seq 1 $nodecount`; do
echo "
  node_port${x}:
    properties:
      network: { get_param: network }
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
    type: OS::Nova::Server" >> "$computetemplate"
done

echo "
outputs:" >> "$computetemplate"
for x in `seq 1 $nodecount`; do
  echo "
  node${x}_ip:
    description: The private IP address of node1
    value: { get_attr: [node${x}, first_address] }
  node${x}_public_ip:
    description: Floating IP address of node1
    value: { get_attr: [ node${x}_floating_ip, floating_ip_address ] }" >> "$computetemplate"
done

openstack stack create --template "$computetemplate" --parameter "key_name=$keyname" --parameter "flavor=$computesize" --parameter "image=$srcimage" --parameter "login_node_ip=$privIP" --parameter "login_node_key=$contents" "compute-$stackname" --parameter "custom_data=$cloudinit" --parameter "disk_size=$computedisksize" >> /dev/null

completed=false
timeout=120
while [[ $completed != true ]]; do # just a little loop to not wait an excessive amount of time
  stack_status=$(openstack stack show "compute-$stackname" -f shell | grep "stack_status=")
  stack_status=${stack_status#*\"} 
  stack_status=${stack_status%\"*} 

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

echoplus -v 2 "Attempting to connect with SSH to compute nodes."
for x in `seq 1 $nodecount`; do
  nodepubIP=$(openstack stack output show "compute-$stackname" "node${x}_public_ip" -f shell | grep "output_value")
  nodepubIP=${nodepubIP#*\"} #removes stuff upto // from begining
  nodepubIP=${nodepubIP%\"*} #removes stuff from / all the way to end
  until ssh -q -i "$keyfile" -o 'StrictHostKeyChecking=no' "flight@$nodepubIP" 'exit'; do
    echoplus -c ORNG -v 2 -p "[node${x}] connecting. . . \r"
  done
  echoplus -c GRN -v 2 "[node${x}] connected.     \r"
  echoplus -v 2 -p "\\n"
done


echoplus -v 0 "login_public_ip=$pubIP"
echoplus -v 0 "login_private_ip=$privIP"

all_nodes_privIP=( "$privIP" )
for x in `seq 1 $nodecount`; do
  nodepubIP=$(openstack stack output show "compute-$stackname" "node${x}_public_ip" -f shell | grep "output_value")
  nodepubIP=${nodepubIP#*\"} #removes stuff upto // from begining
  nodepubIP=${nodepubIP%\"*} #removes stuff from / all the way to end

  nodeprivIP=$(openstack stack output show "compute-$stackname" "node${x}_ip" -f shell | grep "output_value")
  nodeprivIP=${nodeprivIP#*\"} #removes stuff upto // from begining
  nodeprivIP=${nodeprivIP%\"*} #removes stuff from / all the way to end

  echoplus -v 0 "node${x}_public_ip=$nodepubIP"
  echoplus -v 0 "node${x}_private_ip=$nodeprivIP"
  all_nodes_privIP+=("$nodeprivIP")
done

if [[ $only_basic_tests = true ]]; then
  # setup cram testing
  scp -r "../../regression_tests" "flight@${pubIP}:/home/flight/" &>/dev/null
  ssh -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" 'sudo pip3 install cram; sudo yum install -y nmap' &>/dev/null
  default_kube_range="192.168.0.0/16"
  default_node_range="10.50.0.0/16"
  test_env_file="/home/flight/regression_tests/environment_variables.sh"
  env_contents="#!/bin/bash\nexport all_nodes_count='1'\nexport computenodescount='0'\nexport ip_range='${default_node_range}'\nexport kube_pod_range='${default_kube_range}'\nexport login_priv_ip='${privIP}'\nexport login_pub_ip='${pubIP}'\nexport all_nodes_priv_ips=( '${privIP}' )\nexport varlocation='${test_env_file}'" 
  ssh -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" "echo -e \"${env_contents}\" > ${test_env_file}" &>/dev/null
  cram_command="cram -v generic_launch_tests/allnode-generic_launch_tests generic_launch_tests/login-check_root_login.t flight_launch_tests/allnode-flight_launch_tests flight_launch_tests/login-hunter_info.t"
  ssh -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" "cd /home/flight/regression_tests; . environment_variables.sh; bash setup.sh; $cram_command > /home/flight/cram_test_\$?.out"

  # compute tests
  compute_cram_command="cram -v generic_launch_tests/allnode-generic_launch_tests flight_launch_tests/allnode-flight_launch_tests"
  for x in `seq 1 $nodecount`; do
    nodepubIP=$(openstack stack output show "compute-$stackname" "node${x}_public_ip" -f shell | grep "output_value")
    nodepubIP=${nodepubIP#*\"} #removes stuff upto // from begining
    nodepubIP=${nodepubIP%\"*} #removes stuff from / all the way to end

    scp -i "$keyfile" -r "../../regression_tests" "flight@${nodepubIP}:/home/flight/" &>/dev/null
    ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$nodepubIP" 'sudo pip3 install cram; sudo yum install -y nmap' &>/dev/null
    ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$nodepubIP" "cd /home/flight/regression_tests; . environment_variables.sh; bash setup.sh; $compute_cram_command > /home/flight/cram_test_\$?.out" &>/dev/null
  done
  exit
elif [[ $cram_testing = false ]]; then
  exit
fi

# setup cram testing
# login node
scp -i "$keyfile" -r "../../regression_tests" "flight@${pubIP}:/home/flight/"
ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" 'sudo pip3 install cram; sudo yum install -y nmap'
default_kube_range="192.168.0.0/16"
default_node_range="10.50.0.0/16"
test_env_file="/home/flight/regression_tests/environment_variables.sh"
cram_ips="export all_nodes_priv_ips=("
for i in "${all_nodes_privIP[@]}"; do
  cram_ips="$cram_ips \"$i\""
done
cram_ips="$cram_ips )"
env_contents="#!/bin/bash\nexport all_nodes_count='$((nodecount+1))'\nexport computenodescount='${nodecount}'\nexport ip_range='${default_node_range}'\nexport kube_pod_range='${default_kube_range}'\nexport login_priv_ip='${privIP}'\nexport login_pub_ip='${pubIP}'\n${cram_ips}\nexport varlocation='${test_env_file}'"
ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" "echo -e \"${env_contents}\" > ${test_env_file}" &>/dev/null

login_cram_command="cram -v generic_launch_tests/allnode-generic_launch_tests generic_launch_tests/login-check_root_login.t flight_launch_tests/allnode-flight_launch_tests flight_launch_tests/login-hunter_info.t pre-profile_tests"

case $cluster_type in
  kube)
    cram_command="$cram_command profile_tests/kubernetes_multinode cluster_tests/kubernetes_multinode"
    ;;
  slurm)
    cram_command="$cram_command profile_tests/slurm_multinode cluster_tests/slurm_multinode"
    ;;
esac
ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" "cd /home/flight/regression_tests; . environment_variables.sh; bash setup.sh; $login_cram_command > cram_test.out" &>/dev/null
scp -i "$keyfile" "flight@${pubIP}:/home/flight/regression_tests/cram_test.out" "../test_output/${stackname}_cram_test.out"


compute_cram_command="cram -v generic_launch_tests/allnode-generic_launch_tests flight_launch_tests/allnode-flight_launch_tests"
for x in `seq 1 $nodecount`; do
  nodepubIP=$(openstack stack output show "compute-$stackname" "node${x}_public_ip" -f shell | grep "output_value")
  nodepubIP=${nodepubIP#*\"} #removes stuff upto // from begining
  nodepubIP=${nodepubIP%\"*} #removes stuff from / all the way to end

  scp -i "$keyfile" -r "../../regression_tests" "flight@${nodepubIP}:/home/flight/" &>/dev/null
  ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$nodepubIP" 'sudo pip3 install cram; sudo yum install -y nmap' &>/dev/null
  ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$nodepubIP" "cd /home/flight/regression_tests; . environment_variables.sh; bash setup.sh; $compute_cram_command > cram_test.out" &>/dev/null

  scp -i "$keyfile" "flight@${nodepubIP}:/home/flight/regression_tests/cram_test.out" "../test_output/cnode0${x}${stackname}_cram_test.out"

done

# now that we're done testing delete the stack to make way for more tests

if [[ $delete_ending = true ]]; then 
  openstack stack delete -y "$stackname"
  openstack stack delete -y "compute-$stackname"

  timeout=60
  deleted=false
  while [[ $deleted = false ]]; do # just a little loop to not wait an excessive amount of time
    if ! [[ $(openstack stack show "$stackname" -f shell | grep "Stack not found:") ]]; then
      if ! [[ $(openstack stack show "compute-$stackname" -f shell | grep "Stack not found:") ]]; then
        exit 0
      fi
    elif [[ $timeout -le 0 ]];then
      echoplus -p "\\n"
      echoplus -c RED -v 0 "stack deletion timed out"
      exit 1
    else
      echoplus -c ORNG -v 2 -p "$stack_status\r"
      let "timeout=timeout-1"
      sleep 1
    fi
  done
fi