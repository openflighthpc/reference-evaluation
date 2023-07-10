#!/bin/bash -l

if [[ $cram_testing = false && $run_basic_tests = false ]]; then
  echoplus -v 2 "No tests requested."
  return 0
fi

test_result=1
#default_kube_range="192.168.0.0/16"
#default_node_range="10.50.0.0/16"
test_location="/home/flight/regression_tests/"
test_env_file="/home/flight/regression_tests/environment_variables.sh"

env_contents="#!/bin/bash\nexport dirlocation='${test_location}'\nexport varlocation='${test_env_file}'\nexport all_nodes_count='1'\nexport computenodescount='0'\nexport ip_range='0'\nexport kube_pod_range='0'\nexport login_priv_ip='${login_private_ip}'\nexport login_pub_ip='${login_public_ip}'\nexport all_nodes_priv_ips=( '${login_private_ip}' )\nexport autoparsematch='${bool_autoparsematch}'\nexport sharepubkey='${cloud_sharepubkey}'\nexport self_pub_ip='${login_public_ip}'\nexport self_label=''\nexport self_prefix=''"

basic_test_command="cram -v generic_launch_tests/all flight_launch_tests/"

cram_extra_tests="pre-profile_tests" # OR if auto-parse then flight_launch_tests/all
cram_jupyter_standalone_tests="profile_tests/jupyter_standalone cluster_tests/jupyter_standalone post-profile_tests" # post-profile_tests
cram_slurm_standalone_tests="profile_tests/slurm_standalone cluster_tests/slurm_standalone post-profile_tests" # post-profile_tests

# if we're doing testing, then:

# copy across cram tests
redirect_out scp -i "$keyfile" -r "$regression_test_dir" "flight@${login_public_ip}:/home/flight/"
# install necessary tools: cram and nmap, write to env file, run setup script
redirect_out ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$login_public_ip" "sudo pip3 install cram; sudo yum install -y nmap; echo -e \"${env_contents}\" > ${test_env_file}; sleep 60; cd $test_location; . environment_variables.sh; bash setup.sh" 

if [[ $run_basic_tests = true ]]; then
  # run basic cram tests and get output
  redirect_out ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$login_public_ip" "cd /home/flight/regression_tests; . environment_variables.sh; $basic_test_command > /home/flight/cram_test_\$?.out"; test_result=$?
  echoplus -v 1 "Basic testing exit code: $test_result"
else # do cram testing
  cram_command="${basic_test_command} ${cram_extra_tests}"
  echoplus -v 3 "cram tests to run are: $cram_command"
  case $cluster_type in 
    jupyter)
      cram_command+=" $cram_jupyter_standalone_tests"
      ;;
    slurm)
      cram_command+=" $cram_slurm_standalone_tests"
      ;;
    *)
      echoplus -v 0 -c RED "error: \"${cluster_type}\" is unsuitable standalone cluster type"
    ;;
  esac
  echoplus -v 3 "cram tests to run (with cluster type added) are: $cram_command"
  # run cram command
  redirect_out ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$login_public_ip" "cd /home/flight/regression_tests; . environment_variables.sh; $cram_command > /home/flight/cram_test.out"; test_result=$?
  echoplus -v 1 "Cram testing exit code: $test_result"
  redirect_out scp -i "$keyfile" "flight@${login_public_ip}:/home/flight/cram_test.out" "log/tests/${stackname}_cram_$test_result.out"
fi
echoplus -v 1 "exit code for the tests was: $test_result"

result=0
if [[ $delete_on_success = true && $test_result = 0 ]]; then 
  echoplus -v 2 "deleting stack"
  case $platform in
    openstack)
      redirect_out openstack stack delete --wait -y "$stackname"; result=$?
      ;;
    aws)
      redirect_out aws cloudformation delete-stack --stack-name $stackname 
      redirect_out aws cloudformation wait stack-delete-complete --stack-name $stackname; result=$?
      ;;
    azure)
      redirect_out az group delete --yes --name $azure_resourcegroup; result=$?
      echoplus -v 3 "$stackname"
      ;;
  esac
  if [[ $result != 0 ]]; then
    echoplus -v 0 -c RED "Failed to delete. Exiting with code $result"
  fi
  echoplus -v 2 "Delete successful."
  exit $result
fi