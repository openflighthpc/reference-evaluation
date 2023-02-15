#!/bin/bash -l

platform="-"
# take input

while [[ $# -gt 0 ]]; do # while there are not 0 args
  case $1 in
    -o|--openstack)
      platform="openstack"
      shift # past argument
      ;;
    -w|--aws)
      platform="aws"
      shift # past argument
      ;;
    -z|--azure)
      platform="azure"
      shift # past argument
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

# in case no argument is provided
while [[ "$platform" == "-" ]]; do
  echo "Please enter a valid cluster platform to launch on: (openstack/aws/azure)"
  read p
  case ${p,,} in 
    openstack)
    platform="openstack"
    ;;
    aws)
      platform="aws"
    ;;
    azure)
      platform="azure"
    ;;
  esac
done


# ok now do a different launch for each platform
case $platform in 
  openstack)
    cd ./openstack
    . Ivan_testing-openrc.sh
    source openstack/bin/activate
    bash make_multinode_openstack.sh
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

