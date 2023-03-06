#!/bin/bash
for n in $(seq 1 $allnodescount); do
  echo '  *\t*\t*\t|\t\t{} (esc) (glob)' >> flight_launch_tests/login-hunter_info.t 
  echo "  Pseudo-terminal will not be allocated because stdin is not a terminal.\r (esc)
  Warning: Permanently added '*' (ECDSA) to the list of known hosts.\r (esc) (glob)" >> generic_launch_tests/login-check_root_login.t
done
