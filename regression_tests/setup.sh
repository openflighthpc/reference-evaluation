#!/bin/bash
for n in $(seq 1 $all_nodes_count); do
  echo '  *\t*\t*\t|\t\t{} (esc) (glob)' >> flight_launch_tests/login/nodes_in_buffer.t
  echo '  *\t*\t*\t|\t*\t{} (esc) (glob)' >> flight_launch_tests/login/nodes_in_parsed.t
  echo "  Pseudo-terminal will not be allocated because stdin is not a terminal.\r (esc)
  Warning: Permanently added '*' (ECDSA) to the list of known hosts.\r (esc) (glob)" >> generic_launch_tests/login/check_root_login.t
  echo "  \xe2\x94\x82 Label  \xe2\x94\x82 node0*                               \xe2\x94\x82 (esc) (glob)" >> pre-profile_tests/1_hunter_parse.t 
  echo "   node0$((n-1)) complete" >> profile_tests/kubernetes_multinode/4_confirm_application.t 
  label="$(flight hunter list --plain | sed -n "$n"p | awk '{print $5}')"
  flight hunter modify-label $label "node0$((n-1))"

done
