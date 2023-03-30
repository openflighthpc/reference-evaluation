#!/bin/bash -l



# do all tests on openstack
cd ./openstack
. Ivan_testing-openrc.sh
source openstack/bin/activate

# 1-Stu-rc2-km/w(M)
# multinode: Kube, slurm
platform="o"
testnum=1
cluster_type="sm"
size="S"
bash make_multinode_openstack.sh -d -g --noinput -p "stackname=${platform}${testnum}${cluster_type}${size}" -p "loginsize=small" -p "logindisksize=20" -p "standaloneonly=0" -p "computesize=small" -p "computedisksize=20" 

# Standalone: slurm, jupyter

bash make_multinode_openstack.sh -d -g --noinput -p "stackname=${platform}2ss${size}" -p "loginsize=small" -p "logindisksize=20" -p "standaloneonly=true" 

# return to base directory
cd ..



exit 0 # done for now
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

