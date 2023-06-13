#!/bin/bash -l

. setup/Ivan_testing-openrc.sh
source setup/openstack/bin/activate



# unchanging
cram_testing=true
basic_testing=false
num_of_compute_nodes=2
node_volume_size=20
delete_on_success=true


# vary every time
stack_name="name1"

# vary sometimes
node_size="small"
cluster_type="slurm"
platform="openstack"
standalone=false
sharepubkey=false
autoparsematch=""


# this is the command every time, just need to change the variables

runTest() {
  bash 0_parent.sh -g -i -p "stackname=${stack_name}" -p "cnode_count=${num_of_compute_nodes}" -p "cluster_type=${cluster_type}" -p "login_instance_size=${node_size}" -p "compute_instance_size=${node_size}" -p "login_disk_size=${node_volume_size}" -p "compute_disk_size=${node_volume_size}" -p "platform=${platform}" -p "standalone=${standalone}" -p "cram_testing=${cram_testing}" -p "run_basic_tests=${basic_testing}" -p "cloud_sharepubkey=${sharepubkey}" -p "cloud_autoparsematch=${autoparsematch}" -p "delete_on_success=${delete_on_success}" | sed  "s/^/[$stack_name] /"
}

tests=("ss-w-S-T-ip" ) # all the tests we want to run # "js-w-M-F-" "sm-w-M-T-ip" "km-w-L-F-" "ss-o-L-T-o" "js-o-S-F-" "sm-o-S-T-o" "km-o-M-F-" "ss-z-M-T-c" "js-z-L-F-" "sm-z-L-T-c" "km-z-S-F-"
counter=1
prefix="t3" 
for t in "${tests[@]}"; do
  echo "starting test $t"

  stack_name="$prefix-${t}"
  # example: "sm-o-S-T-ip"
  # take everything before "-"
  # which is "sm" at this point
  # s means slurm and m means multinode
  # could just have a case for each situation
  # o is openstack (platform letter)
  # S is Small
  # T is True for sharepubip

  # ip is the regex to use for autoparsemat


  type=${t%%-*} # grab everything up the the first hyphen
  echo "type=$type"
  if [[ $type == *s ]]; then # check if its standalone
    standalone=true
    echo "Standalone"
  fi
  echo "standalone=$standalone"
  case $type in # set the correct cluster type
    s*)
      cluster_type="slurm"
      ;;
    j*)
      cluster_type="jupyter"
      ;;
    k*)
      cluster_type="kubernetes"
      ;;
  esac
  t=${t#*-} # continue with the rest of the information


  platform_letter=${t%%-*}
  case $platform_letter in # set the correct cluster type
    o)
      platform="openstack"
      ;;
    w)
      platform="aws"
      ;;
    z)
      platform="azure"
      ;;
  esac
  t=${t#*-} # continue with the rest of the information


  size_letter=${t%%-*}
  case $size_letter in
    S)
      node_size="small"
      ;;
    M)
      node_size="medium"
      ;;
    L)
      node_size="large"
      ;;
    G)
      node_size="gpu"
      ;;
  esac
  t=${t#*-} # continue with the rest of the information


  sharepubkey_bool=${t%%-*}
  if [[ $sharepubkey_bool == "T" ]]; then 
    sharepubkey=true
  fi # its set to false by default
  t=${t#*-} # continue with the rest of the information
  
  autoparsematch=${t%%-*} # no more processing needed for this one
  echo "type: $type -> cluster type: $cluster_type"
  echo "platform letter $platform_letter -> platform: $platform"
  echo "size letter: $size_letter -> size: $node_size"
  echo "sharepubkey boolean: $sharepubkey_bool -> sharepubkey is $sharepubkey"
  echo "starting test $t"
  runTest &
done

wait
jobs
echo "all tests finished"


# i - no input
# g - generic sizes
# p - parameter


# All possible tests:

# platform: aws, openstack, azure (azure can't do kube)
# Standalone: Slurm, jupyter
# Multinode slurm, kube
# config: sharepubkey(y/n), autoparsematch(y/n) - (sharepubkey doesn't matter for standalone)
# sizes: small, medium, large, (GPU)
# compute node count
# disk size