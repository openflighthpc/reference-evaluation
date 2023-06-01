#!/bing/bash -l

. setup/Ivan_testing-openrc.sh
source setup/openstack/bin/activate


echo "starting test 1"
echo sleep 1

#bash 0_parent.sh -g -i -b -p "stackname=openstacktest1" -p "cnode_count=0" -p "cluster_type=jupyter" -p "login_instance_size=small" -p "compute_instance_size=small" -p "login_disk_size=20" -p "compute_disk_size=20" -p "platform=openstack" -p "standalone=true" -p "cram_testing=false"


#bash 0_parent.sh -g -i -b -p "stackname=awstest2" -p "cnode_count=0" -p "cluster_type=jupyter" -p "login_instance_size=small" -p "compute_instance_size=small" -p "login_disk_size=20" -p "compute_disk_size=20" -p "platform=aws" -p "standalone=true" -p "cram_testing=false"

#bash 0_parent.sh -g -i -b -p "stackname=azuretest4" -p "cnode_count=0" -p "cluster_type=jupyter" -p "login_instance_size=small" -p "compute_instance_size=small" -p "login_disk_size=20" -p "compute_disk_size=20" -p "platform=azure" -p "standalone=true" -p "cram_testing=false"

# i - no input
# g - generic sizes
# p - parameter


# bash 0_parent.sh -g -i -p 'stackname=#{stack_name}' -p 'cnode_count=#{num_of_compute_nodes}' -p 'cluster_type=#{cluster_type}' -p 'login_instance_size=#{login_size}' -p 'compute_instance_size=#{compute_size}' -p 'login_disk_size=#{login_volume_size}' -p 'compute_disk_size=#{compute_volume_size}' -p 'platform=#{platform}' -p 'standalone=#{standalone}' -p 'cram_testing=#{cram_testing}' -p 'run_basic_tests=#{basic_testing}' -p 'cloud_sharepubkey=#{sharepubkey}' -p 'cloud_autoparsematch=#{autoparsematch}' -p 'delete_on_success=#{delete_on_success}

# All possible tests:

# platform: aws, openstack, azure (azure can't do kube)
# Standalone: Slurm, jupyter
# Multinode slurm, kube
# config: sharepubkey(y/n), autoparsematch(y/n) - (sharepubkey doesn't matter for standalone)
# sizes: small, medium, large, (GPU)
# compute node count
# disk size