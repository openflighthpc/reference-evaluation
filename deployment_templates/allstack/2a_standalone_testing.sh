#!/bin/bash -l

if [[ $cram_testing = false && $run_basic_tests = false ]]; then
  echoplus -v 2 "No tests requested."
  exit 0
fi

test_result=1
#default_kube_range="192.168.0.0/16"
#default_node_range="10.50.0.0/16"
test_env_file="/home/flight/regression_tests/environment_variables.sh"
env_contents="#!/bin/bash\nexport all_nodes_count='1'\nexport computenodescount='0'\nexport ip_range='0'\nexport kube_pod_range='0'\nexport login_priv_ip='${login_private_ip}'\nexport login_pub_ip='${login_public_ip}'\nexport all_nodes_priv_ips=( '${login_private_ip}' )\nexport varlocation='${test_env_file}'"

basic_test_command="cram -v generic_launch_tests/allnode-generic_launch_tests generic_launch_tests/login-check_root_login.t flight_launch_tests/allnode-flight_launch_tests flight_launch_tests/login-hunter_info.t"
cram_extra_tests="pre-profile_tests"
cram_jupyter_standalone_tests="profile_tests/jupyter_standalone cluster_tests/jupyter_standalone"
cram_slurm_standalone_tests="profile_tests/slurm_standalone cluster_tests/slurm_standalone"

# if we're doing testing, then:

# copy across cram tests
scp -i "$keyfile" -r "../../regression_tests" "flight@${login_public_ip}:/home/flight/"
# install necessary tools: cram and nmap
ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$login_public_ip" 'sudo pip3 install cram; sudo yum install -y nmap' 
# write to env file
ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$login_public_ip" "echo -e \"${env_contents}\" > ${test_env_file}" 

if [[ $run_basic_tests = true ]]; then
  # run basic cram tests and get output
  ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$login_public_ip" "cd /home/flight/regression_tests; . environment_variables.sh; bash setup.sh; $basic_test_command > /home/flight/cram_test_\$?.out"; result=$?
  echoplus -v 2 "Basic testing exit code: $result"
else # do cram testing
  cram_command="${basic_test_command} ${cram_extra_tests}"
  echo "$cram_command"
  case $cluster_type in 
    jupyter)
      cram_command+=" $cram_jupyter_standalone_tests"
      ;;
    slurm)
      cram_command=" $cram_slurm_standalone_tests"
      ;;
    *)
      echoplus -v 0 -c RED "error: \"${cluster_type}\" is unsuitable cluster type"
  esac
  # run cram command
  ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$login_public_ip" "cd /home/flight/regression_tests; . environment_variables.sh; bash setup.sh; $cram_command > cram_test_$?.out"; test_result=$?
  echoplus -v 2 "Cram testing exit code: $test_result"
  scp -i "$keyfile" "flight@${login_public_ip}:/home/flight/regression_tests/cram_test_$test_result.out" "../test_output/${stackname}_cram_$test_result.out"
fi


result=0
if [[ $delete_on_success = true && $test_result = 0 ]]; then 
  echo "delete stack"
  case $platform in
    openstack)
      openstack stack delete --wait -y "$stackname"; result=$?
      ;;
    aws)
      echo "aws"
      aws cloudformation delete-stack --stack-name $stackname 
      aws cloudformation wait stack-delete-complete --stack-name $stackname; result=$?
      ;;
    azure)
      echo "azure delete stack (WIP)"
      echo "$stackname"
      ;;
  esac
  if [[ $result != 0 ]]; then
    echoplus -v 0 -c RED "Failed to delete. Exiting with code $result"
  fi
  exit $result
fi

