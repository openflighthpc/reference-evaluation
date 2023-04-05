#!/bing/bash -l

. setup/Ivan_testing-openrc.sh
source setup/openstack/bin/activate

bash 0_parent.sh -g -i -b -p "stackname=openstacktest1" -p "cnode_count=0" -p "cluster_type=jupyter" -p "login_instance_size=small" -p "compute_instance_size=small" -p "login_disk_size=20" -p "compute_disk_size=20" -p "platform=openstack" -p "standalone=true" -p "cram_testing=false"


bash 0_parent.sh -g -i -b -p "stackname=awstest2" -p "cnode_count=0" -p "cluster_type=jupyter" -p "login_instance_size=small" -p "compute_instance_size=small" -p "login_disk_size=20" -p "compute_disk_size=20" -p "platform=aws" -p "standalone=true" -p "cram_testing=false"

bash 0_parent.sh -g -i -b -p "stackname=azuretest4" -p "cnode_count=0" -p "cluster_type=jupyter" -p "login_instance_size=small" -p "compute_instance_size=small" -p "login_disk_size=20" -p "compute_disk_size=20" -p "platform=azure" -p "standalone=true" -p "cram_testing=false"