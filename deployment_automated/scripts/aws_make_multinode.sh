#!/bin/bash


# may change, but will always be hard coded in
instanceami="ami-00c0385bab48a6406"

# will probably only change if someone else starts using this template
keyfile="ivan-keypair.pem"
sgroup="sg-0f771e548fa4183ab"
subnet="subnet-55d8582f"
cnodetemplate="changestack.yaml" 

# is easily changeable and will change often
stackname="multinode-101" # ideally needs to be unique every time
loginsize="t3.small"
computesize="t3.small"
logindisksize=20
computedisksize=20
nodecount=2
standalone=false
pytest_testing=false
cluster_type="slurm"

# vars for options
delete_ending=false
only_basic_tests=false
generic_size=false
input=true

#COLOUR CONSTANTS
RED='\033[0;31m'
GRN='\033[0;32m'
ORNG='\033[0;33m'
NC='\033[0m' # No Color
outputlvl=2

# size vars
small="t3.small" #"c5.large" should normally be this size but temp change for cheaper testing
medium="c5.4xlarge"
large="c5d.metal"
gpu="0"

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

# take in non-interactive input
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
    -b|--only-basic-tests)
      only_basic_tests=true
      shift # past argument
      ;;
    -g|--generic-size)
      generic_size=true
      shift # past argument
      ;;
    --noinput)
      input=false
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

# interactively take input
if [[ $input = true ]]; then
  echo "Name of stack?"
  read temp
  if [[ $temp != "" ]] ;then
    stackname="$temp"
  fi

  echo "Standalone cluster?"
  read temp
  if [[ $temp != "" ]] ;then
    standalone=true
  fi

  echo "Do cram testing?"
  read temp
  if [[ $temp != "" ]] ;then
    pytest_testing=true
    echo "Type of cluster? (slurm/kubernetes/jupyter)"
    read temp
    if [[ $temp != "" ]]; then
      cluster_type="$temp"
    fi
  fi

  echo "Login instance Size?"
  read temp
  if [[ $temp != "" ]] ;then
    loginsize="$temp"
  fi

  echo "Login disk size?"
  read temp
  if [[ $temp != "" ]] ;then
    logindisksize="$temp"
  fi

  if [[ $standalone = false ]]; then
    echo "Number of compute nodes"
    read temp
    if [[ $temp != "" ]] ;then
      nodecount="$temp"
    fi

    echo "Compute instance size?"
    read temp
    if [[ $temp != "" ]] ;then
      computesize="$temp"
    fi

    echo "Compute disk size?"
    read temp
    if [[ $temp != "" ]] ;then
      computedisksize="$temp"
    fi
  fi
fi

if [[ $generic_size = true ]]; then
  eval loginsize='$'$loginsize
  eval computesize='$'$computesize
fi

if [[ $standalone = true ]];then
  echoplus -v 2 "Creating standalone cluster. . ."
else
  echoplus -v 2 "Creating login node. . ."
fi

# make the standalone/login node
aws cloudformation create-stack --template-body "$(cat aws_standalone.yaml)" --stack-name "$stackname" --parameters "ParameterKey=KeyPair,ParameterValue=ivan-keypair,UsePreviousValue=false" "ParameterKey=InstanceAmi,ParameterValue=$instanceami,UsePreviousValue=false" "ParameterKey=InstanceSize,ParameterValue=$loginsize,UsePreviousValue=false" "ParameterKey=SecurityGroup,ParameterValue=$sgroup,UsePreviousValue=false" "ParameterKey=InstanceSubnet,ParameterValue=$subnet,UsePreviousValue=false" "ParameterKey=InstanceDiskSize,ParameterValue=$logindisksize,UsePreviousValue=false"
echoplus -v 2 "Checking that stack was created. . ."

aws cloudformation wait stack-create-complete --stack-name $stackname

pubIP=$(aws cloudformation describe-stacks --stack-name $stackname --output text | grep "PublicIp" | grep -Pom 1 '[0-9.]{7,15}')
privIP=$(aws cloudformation describe-stacks --stack-name $stackname --output text | grep "PrivateIp" | grep -Pom 1 '[0-9.]{7,15}')

# Wait for login/standalone node to come online
echoplus -v 2 "Trying SSH until connection is available. . ."
timeout=360
until ssh -q -i "$keyfile" -o 'StrictHostKeyChecking=no' "flight@$pubIP" 'exit'; do
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


if [[ $standalone = true ]];then
  echoplus -v 0 "login_public_ip=$pubIP"
  echoplus -v 0 "login_private_ip=$privIP"
  if [[ $only_basic_tests = true ]]; then
    # setup cram testing
    scp -i "$keyfile" -r "../../regression_tests" "flight@${pubIP}:/home/flight/" &>/dev/null
    # i copied them
    ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" 'sudo pip3 install cram; sudo yum install -y nmap' &>/dev/null
    ## i installed
    default_kube_range="192.168.0.0/16";default_node_range="10.50.0.0/16" 
    test_env_file="/home/flight/regression_tests/environment_variables.sh"
    env_contents="#!/bin/bash\nexport all_nodes_count='1'\nexport computenodescount='0'\nexport ip_range='${default_node_range}'\nexport kube_pod_range='${default_kube_range}'\nexport login_priv_ip='${privIP}'\nexport login_pub_ip='${pubIP}'\nexport all_nodes_priv_ips=( '${privIP}' )\nexport varlocation='${test_env_file}'" 
    ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" "echo -e \"${env_contents}\" > ${test_env_file}" &>/dev/null
    # setup env
    cram_command="cram -v generic_launch_tests/allnode-generic_launch_tests generic_launch_tests/login-check_root_login.t flight_launch_tests/allnode-flight_launch_tests flight_launch_tests/login-hunter_info.t"
    ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" "cd /home/flight/regression_tests; . environment_variables.sh; bash setup.sh; $cram_command > /home/flight/cram_test_\$?.out"
    exit 0
  elif [[ $pytest_testing = false ]]; then
    exit 0
  fi
  # setup cram testing
  scp -i "$keyfile" -r "../../regression_tests" "flight@${pubIP}:/home/flight/" &>/dev/null
  ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" 'sudo pip3 install cram; sudo yum install -y nmap' &>/dev/null
  default_kube_range="192.168.0.0/16";default_node_range="10.50.0.0/16" # these are unimportant, but here so vars aren't empty
  test_env_file="/home/flight/regression_tests/environment_variables.sh"
  env_contents="#!/bin/bash\nexport all_nodes_count='1'\nexport computenodescount='0'\nexport ip_range='${default_node_range}'\nexport kube_pod_range='${default_kube_range}'\nexport login_priv_ip='${privIP}'\nexport login_pub_ip='${pubIP}'\nexport all_nodes_priv_ips=( '${privIP}' )\nexport varlocation='${test_env_file}'" 
  ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" "echo -e \"${env_contents}\" > ${test_env_file}" &>/dev/null
  cram_command="cram -v generic_launch_tests/allnode-generic_launch_tests generic_launch_tests/login-check_root_login.t flight_launch_tests/allnode-flight_launch_tests flight_launch_tests/login-hunter_info.t pre-profile_tests"
  case $cluster_type in 
    jupyter)
      cram_command="$cram_command profile_tests/jupyter_standalone cluster_tests/jupyter_standalone"
      ;;
    slurm)
      cram_command="$cram_command profile_tests/slurm_standalone cluster_tests/slurm_standalone"
      ;;
  esac
  ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" "cd /home/flight/regression_tests; . environment_variables.sh; bash setup.sh; $cram_command > cram_test.out"

  scp -i "$keyfile" "flight@${pubIP}:/home/flight/regression_tests/cram_test.out" "../test_output/${stackname}_cram_test.out"

  # if you want to delete then go for it
  if [[ $delete_ending = true ]]; then 
    # delete the stack and associated instances
    echo "delete"
  fi
  exit 0
fi


contents=$(ssh -i "$keyfile" -o 'StrictHostKeyChecking=no' "flight@$pubIP" "sudo /bin/bash -l -c 'echo -n'; sudo cat /root/.ssh/id_alcescluster.pub")

# create template
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
              " >> $cnodetemplate # add an instance to template for every node
done
echo "Outputs:" >> $cnodetemplate
for x in `seq 1 $nodecount`; do
  echo "
  PrivateIpNode${x}:
    Description: The private IP address of the standalone node
    Value: { Fn::GetAtt: [ Node${x}, PrivateIp] }

  PublicIpNode${x}:
    Description: Floating IP address of standalone node
    Value: { Fn::GetAtt: [ Node${x}, PublicIp ] }
    " >> $cnodetemplate # add an output to template for every node
done

# create stack
aws cloudformation create-stack --template-body "$(cat "$cnodetemplate")" --stack-name "compute$stackname" --parameters "ParameterKey=KeyPair,ParameterValue=ivan-keypair,UsePreviousValue=false" "ParameterKey=InstanceAmi,ParameterValue=$instanceami,UsePreviousValue=false" "ParameterKey=InstanceSize,ParameterValue=$loginsize,UsePreviousValue=false" "ParameterKey=SecurityGroup,ParameterValue=$sgroup,UsePreviousValue=false" "ParameterKey=InstanceSubnet,ParameterValue=$subnet,UsePreviousValue=false" "ParameterKey=IpData,ParameterValue=$privIP,UsePreviousValue=false" "ParameterKey=KeyData,ParameterValue=$contents,UsePreviousValue=false"

aws cloudformation wait stack-create-complete --stack-name "compute$stackname"

# get public and private ips
cnodepubips=()
cnodeprivateips=()
all_nodes_privIP=("$privIP")
for x in `seq 1 $nodecount`; do
  cnodepubips+=("$(aws cloudformation describe-stacks --stack-name "compute$stackname" --output text | grep "PublicIpNode${x}" | grep -Pom 1 '[0-9.]{7,15}')")
  cnodeprivIP="$(aws cloudformation describe-stacks --stack-name "compute$stackname" --output text | grep "PrivateIpNode${x}" | grep -Pom 1 '[0-9.]{7,15}')"
  cnodeprivateips+=("$cnodeprivIP")
  all_nodes_privIP+=("$cnodeprivIP")
done
# i know, i know, you could do the above and below steps in the same loop, but since you have to wait for the nodes to come online anyway there is no point imo - im incorrect if aws brings them online faster than i think it does

# Wait for compute nodes to come online
for n in "${cnodepubips[@]}"; do
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



# cram and basic tests section

default_kube_range="192.168.0.0/16"
default_node_range="172.31.0.0/16"


if [[ $only_basic_tests = true && $pytest_testing = false ]]; then
  # setup cram testing
  scp -i "$keyfile" -r "../../regression_tests" "flight@${pubIP}:/home/flight/" &>/dev/null
  ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" 'sudo pip3 install cram; sudo yum install -y nmap' &>/dev/null

  test_env_file="/home/flight/regression_tests/environment_variables.sh"
  env_contents="#!/bin/bash\nexport all_nodes_count='1'\nexport computenodescount='0'\nexport ip_range='${default_node_range}'\nexport kube_pod_range='${default_kube_range}'\nexport login_priv_ip='${privIP}'\nexport login_pub_ip='${pubIP}'\nexport all_nodes_priv_ips=( '${privIP}' )\nexport varlocation='${test_env_file}'" 
  ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" "echo -e \"${env_contents}\" > ${test_env_file}" &>/dev/null
  cram_command="cram -v generic_launch_tests/allnode-generic_launch_tests generic_launch_tests/login-check_root_login.t flight_launch_tests/allnode-flight_launch_tests flight_launch_tests/login-hunter_info.t"
  ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" "cd /home/flight/regression_tests; . environment_variables.sh; bash setup.sh; $cram_command > /home/flight/cram_test_\$?.out"

  # compute tests
  compute_cram_command="cram -v generic_launch_tests/allnode-generic_launch_tests flight_launch_tests/allnode-flight_launch_tests"

  for n in "${cnodepubips[@]}"; do
    scp -i "$keyfile" -r "../../regression_tests" "flight@${n}:/home/flight/" >/dev/null
    ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$n" 'sudo pip3 install cram; sudo yum install -y nmap' >/dev/null
    ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$n" "cd /home/flight/regression_tests; . environment_variables.sh; bash setup.sh; $compute_cram_command > /home/flight/cram_test_\$?.out" >/dev/null
  done

  # print out ips
  echoplus -v 0 "login_public_ip=$pubIP"
  echoplus -v 0 "login_private_ip=$privIP"
  for x in `seq 1 $nodecount`; do
    echo "node0${x}_public_ip: ${cnodepubips[$x-1]}"
    echo "node0${x}_private_ip: ${cnodeprivateips[$x-1]}"
  done
  exit
elif [[ $pytest_testing = false ]]; then
    # print out ips
    echoplus -v 0 "login_public_ip=$pubIP"
    echoplus -v 0 "login_private_ip=$privIP"
    for x in `seq 1 $nodecount`; do
      echo "node0${x}_public_ip: ${cnodepubips[$x-1]}"
      echo "node0${x}_private_ip: ${cnodeprivateips[$x-1]}"
    done
  exit
fi

# setup cram testing
# login node
scp -i "$keyfile" -r "../../regression_tests" "flight@${pubIP}:/home/flight/"
ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" 'sudo pip3 install cram; sudo yum install -y nmap'
test_env_file="/home/flight/regression_tests/environment_variables.sh"
cram_ips="export all_nodes_priv_ips=("
for i in "${all_nodes_privIP[@]}"; do
  cram_ips="$cram_ips \"$i\""
done
cram_ips="$cram_ips )"
env_contents="#!/bin/bash\nexport all_nodes_count='$((nodecount+1))'\nexport computenodescount='${nodecount}'\nexport ip_range='${default_node_range}'\nexport kube_pod_range='${default_kube_range}'\nexport login_priv_ip='${privIP}'\nexport login_pub_ip='${pubIP}'\n${cram_ips}\nexport varlocation='${test_env_file}'"
ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" "echo -e \"${env_contents}\" > ${test_env_file}" &>/dev/null

login_cram_command="cram -v generic_launch_tests/allnode-generic_launch_tests generic_launch_tests/login-check_root_login.t flight_launch_tests/allnode-flight_launch_tests flight_launch_tests/login-hunter_info.t pre-profile_tests"
echo "$cluster_type"
case $cluster_type in
  kubernetes)
    echo "made it fine kube"
    login_cram_command+=" profile_tests/kubernetes_multinode cluster_tests/kubernetes_multinode"
    ;;
  slurm)
    echo "made it fine slurm"
    login_cram_command+=" profile_tests/slurm_multinode cluster_tests/slurm_multinode"
    ;;
esac
ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$pubIP" "cd /home/flight/regression_tests; . environment_variables.sh; bash setup.sh; $login_cram_command > cram_test.out" &>/dev/null
scp -i "$keyfile" "flight@${pubIP}:/home/flight/regression_tests/cram_test.out" "../test_output/${stackname}_cram_test.out"


compute_cram_command="cram -v generic_launch_tests/allnode-generic_launch_tests flight_launch_tests/allnode-flight_launch_tests"
for x in `seq 1 $nodecount`; do
  scp -i "$keyfile" -r "../../regression_tests" "flight@${cnodepubips[$x-1]}:/home/flight/" &>/dev/null
  ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@${cnodepubips[$x-1]}" 'sudo pip3 install cram; sudo yum install -y nmap' &>/dev/null
  ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@${cnodepubips[$x-1]}" "cd /home/flight/regression_tests; . environment_variables.sh; bash setup.sh; $compute_cram_command > cram_test.out" &>/dev/null

  scp -i "$keyfile" "flight@${cnodepubips[$x-1]}:/home/flight/regression_tests/cram_test.out" "../test_output/${stackname}_cnode0${x}_cram_test.out"

done

# now that we're done testing delete the stack to make way for more tests

if [[ $delete_ending = true ]]; then 
  echo "delete stack?"
fi

# print out ips
echoplus -v 0 "login_public_ip=$pubIP"
echoplus -v 0 "login_private_ip=$privIP"
for x in `seq 1 $nodecount`; do
  echo "node0${x}_public_ip: ${cnodepubips[$x-1]}"
  echo "node0${x}_private_ip: ${cnodeprivateips[$x-1]}"
done