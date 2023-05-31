#!/bin/bash -l
for n in $(seq 1 $all_nodes_count); do
  echo '  matched' >> flight_launch_tests/login/nodes_in_buffer.t
  echo '  matched' >> flight_launch_tests/login/nodes_in_parsed.t
  echo "  Pseudo-terminal will not be allocated because stdin is not a terminal.\r (esc)
  Warning: Permanently added '*' (ECDSA) to the list of known hosts.\r (esc) (glob)" >> generic_launch_tests/login/check_root_login.t
  echo "   node0$((n-1))" >> pre-profile_tests/1_hunter_parse.t 
  echo "   node0$((n-1)) complete" >> profile_tests/kubernetes_multinode/4_confirm_application.t 
  if [[ $n != 1 ]]; then
    echo "  Ready" >> cluster_tests/kubernetes_multinode/1_check_nodes.t
  fi
done

# get rid of unnecessary tests based on the kind of tests needing to be run

if [[ $autoparsematch == false ]]; then # delete test based on cloud init data
  rm flight_launch_tests/login/nodes_in_parsed.t
else # if autoparsematch is true
  rm flight_launch_tests/login/nodes_in_buffer.t
  rm pre-profile_tests/1_hunter_parse.t
  for n in $(seq 1 $all_nodes_count); do
    label="$(flight hunter list --plain | sed -n "$n"p | awk '{print $5}')"
    flight hunter modify-label $label "node0$((n-1))"
  done
fi

if [[ $sharepubkey == true && "$login_pub_ip" == "$self_pub_ip"  ]] ; then
  sed -i '6s/$/ 1234\/tcp/' generic_launch_tests/all/basic/5_check_firewall.t 
fi