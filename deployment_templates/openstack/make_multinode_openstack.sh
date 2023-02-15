#!/bin/bash

nodecount=2
outputlvl=2
varfile="config.in"
config="0"
noinput="0"
#CONSTANTS
RED='\033[0;31m'
GRN='\033[0;32m'
ORNG='\033[0;33m'
NC='\033[0m' # No Color

# take input

while [[ $# -gt 0 ]]; do # while there are not 0 args
  case $1 in
    -n|--nodecount)
      nodecount="$2"
      shift # past argument
      shift # past value
      ;;
    -v|--verbose)
      outputlvl=3
      shift # past argument
      ;;
    -q|--quiet)
      outputlvl=1
      shift # past argument
      ;;
    -c|--config)
      config=1 
      shift # past argument
      ;;
    --noinput)
      noinput=1 
      shift # past argument
      ;;
    -p|--parameter)
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


echoplus -c ORNG -v 3 "WARNING: make sure to source openstack project file!"

# Parameters: STACKNAME, loginsize, logindisksize, standaloneonly, computetemplate, computesize, computedisksize, keyfile, keyname, logintemplate, srcimage

# defaults
#STACKNAME
loginsize="m1.small"
logindisksize="20"
standaloneonly=false
computetemplate="compute-nodes-template.yaml"
computesize="m1.small"
computedisksize="20"


if [[ "$noinput" == "0" && $config == "0" ]]; then

  echoplus -v 0 "What should the stack be named?"
  read STACKNAME

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

  echoplus -v 0 "Create only standalone?"
  read temp
  if [[ $temp != "" ]]; then
    standaloneonly=true
  fi

  echoplus -v 0 "What template to use for compute nodes? (file path)"
  read temp
  if [[ $temp != "" ]]; then
    computetemplate="$temp"
  fi

  if [[ $standaloneonly = false ]]; then
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


keyfile="key1.pem"
keyname="keytest1"
logintemplate="login-node-template.yaml"
srcimage="Flight Solo 2023.1-rc5-03.02.23"
openflightkey='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDWD9MAHnS5o6LrNaCb5gshU4BIpYfqoE2DCW9T2u3v4xOh04JkaMsIzwGc+BNnCh+NlkSE9sPVyPODCVnLnHdyyNfUkLBIUGCM/h9Ox7CTnsbmhnv3tMp4OD2dnGl+wOXWo/0YrWA0cpcl5UchCpZYMGscR4ohg8+/panBJ0//wmQZmCUZkQ20TLumYlL9HdmFl2SO2vraY+nBQCoHtPC80t4BmbPg5atEnQVMngpsRqSykIoUEQKh49t649cF3rBboZT+AmW+O1GWVYu7qlUxqIsdTRJbqbhZ/W2n3rraQh5CR/hOyYikkdn3xqm7Rom5iURvWd6QBh0LhP1UPRIT'
echoplus -v 3 -c ORNG "$srcimage"
standaloneCloudinit="
#cloud-config\nusers:\n  - default\n  - name: flight\n    ssh_authorized_keys:\n    - $openflightkey\n    "
echoplus -v 2 "Creating standalone cluster. . ."

openstack stack create --template "$logintemplate" --parameter "key_name=$keyname" --parameter "flavor=$loginsize" --parameter "image=$srcimage"  --parameter "disk_size=$logindisksize" "$STACKNAME" >> /dev/null


completed=false
timeout=120
while [[ $completed != true ]]; do # just a little loop to not wait an excessive amount of time
  stack_status=$(openstack stack show "$STACKNAME" -f shell | grep "stack_status=")
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
    echoplus -c RED -v 0 -p "$stack_status""$(openstack stack show "$STACKNAME" -f shell | grep "stack_status_reason=")"
    echoplus -p "\\n"
    exit 1
  else
    echoplus -c ORNG -v 2 -p "$stack_status\r"
    let "timeout=timeout-1"
    sleep 1
  fi
done


echoplus -v 3 "public ip:"
pubIP=$(openstack stack output show "$STACKNAME" standalone_public_ip -f shell | grep "output_value")
pubIP=${pubIP#*\"} #removes stuff upto // from begining
pubIP=${pubIP%\"*} #removes stuff from / all the way to end
echoplus -v 3 "$pubIP"

echoplus -v 3 "private ip:"
privIP=$(openstack stack output show "$STACKNAME" standalone_ip -f shell | grep "output_value")
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

if [[ $standaloneonly = true ]];then
  echoplus -v 0 "login_public_ip=$pubIP"
  echoplus -v 0 "login_private_ip=$privIP"
  exit
fi


echoplus -v 3 $contents

cloudscript="#cloud-config\nwrite_files:\n  - content: |\n      SERVER=$privIP\n    path: /opt/flight/cloudinit.in\n    permissions: '0644'\n    owner: root:root\nusers:\n  - default\n  - name: root\n    ssh_authorized_keys:\n    - $contents\n  - name: flight\n    ssh_authorized_keys:\n    - $openflightkey\n    "
cloudtranslat=$(echo -e "$cloudscript" | base64 -w0)
cloudinit=$(echo -e "$cloudscript")

openstack stack create --template "$computetemplate" --parameter "key_name=$keyname" --parameter "flavor=$computesize" --parameter "image=$srcimage" --parameter "login_node_ip=$privIP" --parameter "login_node_key=$contents" "compute-$STACKNAME" --parameter "custom_data=$cloudinit" --parameter "disk_size=$computedisksize" >> /dev/null




completed=false
timeout=120
while [[ $completed != true ]]; do # just a little loop to not wait an excessive amount of time
  stack_status=$(openstack stack show "compute-$STACKNAME" -f shell | grep "stack_status=")
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
    echoplus -c RED -v 0 -p "$stack_status""$(openstack stack show "$STACKNAME" -f shell | grep "stack_status_reason=")"
    echoplus -p "\\n"
    exit 1
  else
    echoplus -c ORNG -v 2 -p "$stack_status\r"
    let "timeout=timeout-1"
    sleep 1
  fi
done

echoplus -v 3 "node01 public ip:"
node01pubIP=$(openstack stack output show "compute-$STACKNAME" node01_public_ip -f shell | grep "output_value")
node01pubIP=${node01pubIP#*\"} #removes stuff upto // from begining
node01pubIP=${node01pubIP%\"*} #removes stuff from / all the way to end
echoplus -v 3 $node01pubIP

echoplus -v 3 "node01 private ip:"
node01privIP=$(openstack stack output show "compute-$STACKNAME" node01_ip -f shell | grep "output_value")
node01privIP=${node01privIP#*\"} #removes stuff upto // from begining
node01privIP=${node01privIP%\"*} #removes stuff from / all the way to end
echoplus -v 3 $node01privIP

echoplus -v 3 "node02 public ip:"
node02pubIP=$(openstack stack output show "compute-$STACKNAME" node02_public_ip -f shell | grep "output_value")
node02pubIP=${node02pubIP#*\"} #removes stuff upto // from begining
node02pubIP=${node02pubIP%\"*} #removes stuff from / all the way to end
echoplus -v 3 $node02pubIP

echoplus -v 3 "node02 private ip:"
node02privIP=$(openstack stack output show "compute-$STACKNAME" node02_ip -f shell | grep "output_value")
node02privIP=${node02privIP#*\"} #removes stuff upto // from begining
node02privIP=${node02privIP%\"*} #removes stuff from / all the way to end
echoplus -v 3 $node02privIP


# can you login to node01?
echoplus -v 2 "Attempting to connect with SSH to compute nodes."
until ssh -q -i "$keyfile" -o 'StrictHostKeyChecking=no' "flight@$node01pubIP" 'exit'; do
  echoplus -c ORNG -v 2 -p "[node01] connecting. . . \r"
done
echoplus -c GRN -v 2 "[node01] connected.     \r"
echoplus -v 2 -p "\\n"

# can you login to node02?
until ssh -q -i "$keyfile" -o 'StrictHostKeyChecking=no' "flight@$node02pubIP" 'exit'; do
  echoplus -c ORNG -v 2 -p "[node02] connecting. . . \r"
done
echoplus -c GRN -v 2 "[node01] connected.     \r"
echoplus -p -v 1 "\\n"


echoplus -v 1 "public IPs:"
echoplus -v 1 "$pubIP"
echoplus -v 1 "$node01pubIP"
echoplus -v 1 "$node02pubIP"
echoplus -v 1 ""
echoplus -v 1 "Private IPs:"
echoplus -v 1 "$privIP"
echoplus -v 1 "$node01privIP"
echoplus -v 1 "$node02privIP"


echoplus -v 0 "login_public_ip=$pubIP"
echoplus -v 0 "login_private_ip=$pubIP"
