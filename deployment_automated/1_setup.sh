#!/bin/bash -l

outputlvl=2

# unique settings (same irregardless of platform)
stackname="default1" # needs to be unique every time
cnode_count=2
cluster_type="slurm" # slurm/jupyter/kubernetes
login_instance_size="0"
compute_instance_size="0"
login_disk_size=20
compute_disk_size=20
platform="openstack" # openstack/aws/azure

standalone=false
input=true
cram_testing=false
delete_on_success=false
run_basic_tests=true
generic_size=false
keyfile="0"


regression_test_dir="../regression_tests/" # location of the regression tests

#defaults (all platforms)
openstack_image="Flight Solo 2023.3"
aws_image="ami-0d2b4bf281f7eefe2" # instance ami
azure_image="/subscriptions/a41c5728-46d9-4f9c-aefe-ffd2a83df476/resourceGroups/openflight-images/providers/Microsoft.Compute/images/Flight-Solo-2023.3-rc3-2804231746-westeurope" # source image link

openstack_keyfile="keys/key1.pem"
aws_keyfile="keys/ivan-keypair.pem"
azure_keyfile="keys/ivan-azure_key.pem"

openstack_key="keytest1"
aws_key="ivan-keypair"
azure_key="ivan-azure_key"

openstack_login_size="m1.medium"
aws_login_size="t3.small"
azure_login_size="Standard_F2s_v2"

openstack_compute_size="m1.medium"
aws_compute_size="t3.small"
azure_compute_size="Standard_F2s_v2"

openstack_login_template="openstack_templates/login-node-template.yaml"
aws_login_template="aws_templates/aws_standalone.yaml"
azure_login_template="azure_templates/standalone_azure.json"

openstack_compute_template="openstack_templates/changestack.yaml"
aws_compute_template="aws_templates/changestack.yaml" 
azure_compute_template="azure_templates/multinode_azure.json" 


# unchanging
openflightkey='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDWD9MAHnS5o6LrNaCb5gshU4BIpYfqoE2DCW9T2u3v4xOh04JkaMsIzwGc+BNnCh+NlkSE9sPVyPODCVnLnHdyyNfUkLBIUGCM/h9Ox7CTnsbmhnv3tMp4OD2dnGl+wOXWo/0YrWA0cpcl5UchCpZYMGscR4ohg8+/panBJ0//wmQZmCUZkQ20TLumYlL9HdmFl2SO2vraY+nBQCoHtPC80t4BmbPg5atEnQVMngpsRqSykIoUEQKh49t649cF3rBboZT+AmW+O1GWVYu7qlUxqIsdTRJbqbhZ/W2n3rraQh5CR/hOyYikkdn3xqm7Rom5iURvWd6QBh0LhP1UPRIT'

# unique to a platform
#aws
aws_sgroup="sg-0f771e548fa4183ab"
aws_subnet="subnet-55d8582f"

#azure
azure_location="westeurope" #"uksouth"
azure_adminkey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDXqGRCY+Rx/cu5qokWOAU5UsH8D8xgbv32sxKZ01Tyuu1arV5be8lG+m4f2can3ZRNbTAx7oUFCncFfy5F5QFMMUCi0QNhCHmn7rnniRikq8Qlb9LgueUk0GaopbakT2w0BEdJv0lmlBh7Vyti2G7MUuuthqDUzU/vKgsgWQ7ImU8r91ecMJ56SoMIOCSqpRxbcx1mEzoedv3JqJeS/pypph2+j9NdrbEipBtZYCjRkAqgqyfWrPgqvg3I+L0YnN5JMlROA5IdRPfWEZnCOi+KV0zRyvdAp4mXYwjyluN2zXckSAYl0x3JAkfiofpce63H3/aNgSxMtXLvvimMWADhdY20aLikRMWRGh+fngogibCfZTNyCuseT2IMuxjI0S+EcBKcO6kDRCPaqVNOcaElgg4cX7xueVKAK8fL2rP6ngpwR7NYEUzy7fhy8eCL1Vpl1PnDLLzttG0p7KrGFWqliTEirmodL5MN/4QzRdp/srqJdqVvvQk9opZvSY7Iqt0= generated-by-azure"
azure_adminname="flight"
azure_resourcegroup="Regression-Testing"

# note for autoparse: 
# aws hostnames are: ip-<private ip address>.eu-west-2.compute.internal
# openstack hostnames are: $clustername-<random alphanumeric code>.novalocal
# azure hostnames are: chead1 for login, cnode0x for compute


# cloud init stuff
cloud_sharepubkey=false
cloud_autoparsematch="" # does empty mean it doesn't do it?



# platform sizes

#openstack
openstack_small="m1.medium" # m1.small
openstack_medium="m1.large"
openstack_large="m1.xlarge"
openstack_gpu="0"
#aws
aws_small="c5.large" #  t3.small
aws_medium="c5.4xlarge"
aws_large="c5d.metal"
aws_gpu="0"
#azure
azure_small="Standard_F2s_v2" 
azure_medium="Standard_DS5_v2"
azure_large="Standard_HC44rs"
azure_gpu="0"


# process arguments

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
    -d|--delete-on-success)
      delete_on_success=true
      shift # past argument
      ;;
    -b|--only-basic-tests)
      run_basic_tests=true
      shift # past argument
      ;;
    -c|--cram-testing)
      cram_testing=true
      shift # past argument
      ;;
    -g|--generic-size)
      generic_size=true
      shift # past argument
      ;;
    -i|--no-input)
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
      echo "-v, --verbose                               more output"
      echo "-q, --quiet                                 less output"
      echo "-b, --only-basic-tests                      run basic tests."
      echo "-d, --delete-on-success                     delete cluster if it successly passes basic tests. No effect without -b."
      echo "-g, --generic-size                          accept small/medium/large as size inputs."
      echo "-i, --no-input                              don't accept input interactively."
      echo '-p, --parameter "PARAMETERNAME=PARAMETER"   pass a parameter to the program'
      echo "--noinput                                   program won't ask for input"
      exit 2
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

# function to print more interestingly

#COLOUR CONSTANTS (for echoplus)
RED='\033[0;31m'
GRN='\033[0;32m'
ORNG='\033[0;33m'
NC='\033[0m' # No Color

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

# interactively take input
if [[ $input = true ]]; then
  echo "Name of stack?"
  read temp
  if [[ $temp != "" ]] ;then
    stackname="$temp"
  fi

  echo "Platform?"
  read temp
  if [[ $temp != "" ]] ;then
    platform="$temp"
  fi

  echo "Standalone cluster?"
  read temp
  if [[ $temp != "" ]] ;then
    standalone=true
  fi

  echo "Do cram testing?"
  read temp
  if [[ $temp != "" ]] ;then
    cram_testing=true
    echo "Type of cluster? (slurm/kubernetes/jupyter)"
    read temp
    if [[ $temp != "" ]]; then
      cluster_type="$temp"
    fi
  fi

  echo "Login instance Size?"
  read temp
  if [[ $temp != "" ]] ;then
    login_instance_size="$temp"
  else
    login_instance_size='$'$platform"_small"
  fi

  echo "Login disk size?"
  read temp
  if [[ $temp != "" ]] ;then
    login_disk_size="$temp"
  fi

  if [[ $standalone = false ]]; then
    echo "Number of compute nodes"
    read temp
    if [[ $temp != "" ]] ;then
      cnode_count="$temp"
    fi

    echo "Compute instance size?"
    read temp
    if [[ $temp != "" ]] ;then
      compute_instance_size="$temp"
    else
      compute_instance_size='$'$platform"_small"
    fi

    echo "Compute disk size?"
    read temp
    if [[ $temp != "" ]] ;then
      compute_disk_size="$temp"
    fi
  fi
fi

# final processing and adjusting based on interactive and/or argument input


if [[ -z "$cloud_autoparsematch" ]]; then
  bool_autoparsematch=false
else
  bool_autoparsematch=true
fi

echo "sharepubkey? $cloud_sharepubkey"
echo "autoparsematch regex: $cloud_autoparsematch"
echo "do autoparsematch? $bool_autoparsematch"

login_cloudscript="#cloud-config\nwrite_files:\n  - content: |\n      SHAREPUBKEY=${cloud_sharepubkey}\n      AUTOPARSEMATCH=${cloud_autoparsematch}\n    path: /opt/flight/cloudinit.in\n    permissions: '0644'\n    owner: root:root\nusers:\n  - default    \n  - name: flight\n    ssh_authorized_keys:\n      - ${openflightkey}\n"     #"#cloud-config\nusers:\n  - default\n  - name: flight\n    ssh_authorized_keys:\n    - ${openflightkey}\n    "

spaced_login_cloudscript=$(echo -e "$login_cloudscript")
spaced_based_login_cloudscript=$(echo -e "$login_cloudscript" | base64 -w0)

openstack_standalone_cloudinit="#cloud-config\nusers:\n  - default\n  - name: flight\n    ssh_authorized_keys:\n    - $openflightkey\n    "



# in case a compute size isn't put in
if [[ $compute_instance_size = "0" ]]; then
  compute_instance_size="$login_instance_size"
fi

# adjust for generic style input
if [[ $generic_size = true ]]; then
  eval login_instance_size='$'$platform"_"$login_instance_size
  eval compute_instance_size='$'$platform"_"$compute_instance_size
fi

# login name and compute name (currently only used by azure)
login_name="${stackname}-chead1"
compute_name="${stackname}_cnode"

# adjust parameters in case of standalone
if [[ $standalone = true ]]; then
  login_name="${stackname}_standalone"
  cnode_count=0
fi

# set keyfile to be the keyfile for this platform
eval keyfile='$'$platform"_keyfile"


# make a new resource group for each cluster (this should probably be in the azure template)
if [[ "$platform" = "azure" ]]; then
  azure_resourcegroup="${stackname}_resource_group"
  az group create --location "$azure_location" --name "$azure_resourcegroup"
  az group wait --name "$azure_resourcegroup" --created
fi