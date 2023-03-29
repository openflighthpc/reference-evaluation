#!/bin/bash -l

platform="openstack"
stack_name=default
login_instance_size=small
login_volume_size=20
cluster_type=slurm
cram_testing=false
standalone=false
num_of_compute_nodes=2
compute_instance_size=small
compute_volume_size=20

while [[ $# -gt 0 ]]; do # while there are not 0 args
  case $1 in
    -p|--platform)
      platform="$2"
      shift # past argument
      shift # past value
      ;;
    --stack_name)
      stack_name="$2"
      shift # past argument
      shift # past value
      ;;
    --login_instance_size)
      login_instance_size="$2"
      shift
      shift
      ;;
    --login_volume_size)
      login_volume_size="$2"
      shift
      shift
      ;;
    --cluster_type)
      cluster_type="$2"
      shift
      shift
      ;;
    --cram_testing)
      cram_testing="$2"
      shift
      shift
      ;;
    --standalone)
      standalone="$2"
      shift
      shift
      ;;
    --num_of_compute_nodes)
      num_of_compute_nodes="$2"
      shift
      shift
      ;;
    --compute_instance_size)
      compute_instance_size="$2"
      shift
      shift
      ;;
    --compute_volume_size)
      compute_volume_size="$2"
      shift
      shift
      ;;
    -*|--*)
      echo -e "${RED}Unknown option $1 ${NC}"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

echo "building cluster for $platform"

# ok now do a different launch for each platform
case $platform in 
  openstack)
    cd ./openstack
    . Ivan_testing-openrc.sh
    source openstack/bin/activate
    bash make_multinode_openstack.sh -g --noinput -p "stackname=${stack_name}" -p "loginsize=${login_instance_size}" -p "logindisksize=${login_volume_size}" -p "standaloneonly=${standalone}" -p "computesize=${compute_instance_size}" -p "computedisksize=${compute_volume_size}" 
  ;;
  aws)
    cd ./aws
    bash aws_make_multinode.sh
  ;;
  azure)
    cd ./azure
    bash make_cluster_azure.sh
  ;;
esac
cd ..

