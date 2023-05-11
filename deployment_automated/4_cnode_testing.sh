#!/bin/bash -l


if [[ $cram_testing = false && $run_basic_tests = false ]]; then
  echoplus -v 2 "No tests requested."
  exit 0
fi

#cnodes_public_ips=()
#cnodes_private_ips=()
all_private_ips=("$login_private_ip" "${cnodes_private_ips[@]}")
all_public_ips=("$login_public_ip" "${cnodes_public_ips[@]}")

cnode_exits=()
test_env_file="/home/flight/regression_tests/environment_variables.sh" # maybe define in setup?

default_kube_range="192.168.0.0/16"
default_node_range="10.50.0.0/16"

# will have to change teh default node range for platform
env_contents="#!/bin/bash\nexport all_nodes_count='$((cnode_count+1))'\nexport computenodescount='${cnode_count}'\nexport ip_range='${default_node_range}'\nexport kube_pod_range='${default_kube_range}'\nexport login_priv_ip='${login_private_ip}'\nexport login_pub_ip='${login_public_ip}'\nexport all_nodes_priv_ips=( '${all_private_ips}' )\nexport varlocation='${test_env_file}'"


login_basic_tests="cram -v generic_launch_tests/allnode-generic_launch_tests"  # "cram -v generic_launch_tests/allnode-generic_launch_tests generic_launch_tests/login-check_root_login.t flight_launch_tests/allnode-flight_launch_tests flight_launch_tests/login-hunter_info.t"

compute_basic_tests="cram -v generic_launch_tests/allnode-generic_launch_tests flight_launch_tests/allnode-flight_launch_tests"



# setup each node in cluster for testing
for i in "${all_public_ips[@]}"; do
  # copy across cram tests
  scp -i "$keyfile" -r "$regression_test_dir" "flight@${i}:/home/flight/"
  # install necessary tools: cram and nmap
  ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@${i}" 'sudo pip3 install cram' #; sudo yum install -y nmap' 
  # write to env file
  ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@${i}" "echo -e \"${env_contents}\" > ${test_env_file}" 
done


if [[ $run_basic_tests = true ]]; then 
# run basic cram tests only
  ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$login_public_ip" "cd /home/flight/regression_tests; . environment_variables.sh; bash setup.sh; $login_basic_tests > /home/flight/cram_test_\$?.out"; result=$?
  echoplus -v 2 "[login] Basic testing exit code: $result"

  for x in `seq 1 $cnode_count`; do # run basic tests on compute nodes
    ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@${all_public_ips[$x]}" "cd /home/flight/regression_tests; . environment_variables.sh; bash setup.sh; $compute_basic_tests > /home/flight/cram_test_cnode0${x}_\$?.out"; result=$?
    echoplus -v 2 "[cnode0${x}] Basic testing exit code: $result"
  done

else # do cram testing


  # what test to run?
  login_tests1="pre-profile_tests"
  login_tests3="post-profile_tests/login"
  case $cluster_type in 
    kubernetes)
      login_tests2="profile_tests/kubernetes_multinode"
      login_tests4="cluster_tests/kubernetes_multinode"
      ;;
    slurm)
      login_tests2="profile_tests/slurm_multinode"
      login_tests4="cluster_tests/slurm_multinode/anynode cluster_tests/slurm_multinode/login"
      compute_tests4="cluster_tests/slurm_multinode/anynode cluster_tests/slurm_multinode/compute"
      ;;
    *)
      echoplus -v 0 -c RED "error: \"${cluster_type}\" is unsuitable cluster type"
    ;;
  esac
  # run basic compute tests
  # run basic login tests, login tests 1,2,3,4
  # then compute test 4

  total_test_result=0
  test_result=0
  for x in `seq 1 $cnode_count`; do # get the compute node tests started
    ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@${cnodes_public_ips[(($x-1))]}" "cd /home/flight/regression_tests; . environment_variables.sh; bash setup.sh; ${compute_basic_tests} > cram_test.out"; test_result=$?
    echoplus -v 2 "cnode0${x} basic tests, exit code $test_result"
  done

  echo "with the basic tests"

  if [[ $test_result != 0 ]]; then
    total_test_result=$test_result
  fi

  echo "1 done comparing results: $test_result"

  echo "cram command: ${login_basic_tests} ${login_tests1} ${login_tests2} ${login_tests3} ${login_tests4}"
# doing the basic tests twice for some reason
  ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@$login_public_ip" "cd /home/flight/regression_tests; . environment_variables.sh; bash setup.sh; ${login_basic_tests} > cram_test.out"; test_result=$? #${login_tests1} ${login_tests2} ${login_tests3} ${login_tests4}
  echoplus -v 2 "login tests complete, exit code $test_result"


  if [[ $test_result != 0 ]]; then
    total_test_result=$test_result
  fi

  echo "2 done comparing results: $test_result"

  for x in `seq 1 $cnode_count`; do # get the compute node tests started
    ssh -i "$keyfile" -q -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "flight@${cnodes_public_ips[(($x-1))]}" "cd /home/flight/regression_tests; . environment_variables.sh; bash setup.sh; cram -v ${compute_tests4} >> cram_test.out"; test_result=$?
    echoplus -v 2 "cnode0${x} compute tests 4, exit code $test_result"
  done

  echo "3 done with the rest of the compute tests"

  if [[ $test_result != 0 ]]; then
    total_test_result=$test_result
  fi

  echo "4 done comparing results: $test_result"

  scp -i "$keyfile" "flight@${login_public_ip}:/home/flight/regression_tests/cram_test.out" "log/tests/${stackname}_cram_$test_result.out"

  for x in `seq 1 $cnode_count`; do # get the compute node tests started
    scp -i "$keyfile" "flight@${cnodes_public_ips[(($x-1))]}:/home/flight/regression_tests/cram_test.out" "log/tests/${stackname}_cnode0${x}cram_$test_result.out"
  done

  echoplus -v 2 "cram tests all complete?"
fi




# else do cram tests, get exit codes, array for cnode exit codes

# if deleting on success, then run deletion, make it all or none (i.e. don't delete unless everything passes)



if [[ $delete_on_success = true && $total_test_result = 0 ]]; then 
  echo "delete stack"
  case $platform in
    openstack)
      openstack stack delete --wait -y "$stackname"; result=$? 
      openstack stack delete --wait -y "$compute_stackname"; result=$?
      ;;
    aws)
      aws cloudformation delete-stack --stack-name $stackname 
      aws cloudformation delete-stack --stack-name $compute_stackname
      aws cloudformation wait stack-delete-complete --stack-name $stackname; result=$?
      aws cloudformation wait stack-delete-complete --stack-name $compute_stackname; result=$?

      ;;
    azure)
      az group delete --name $azure_resourcegroup; result=$?
      echo "$stackname"
      ;;
  esac
  if [[ $result != 0 ]]; then
    echoplus -v 0 -c RED "Failed to delete. Exiting with code $result"
  fi
  echo "Deletion appears to have succeeded."
  exit $result
fi