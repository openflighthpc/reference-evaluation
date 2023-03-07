Check that hunter buffer holds info on all the nodes we want to find

  $ . "$varlocation"
  $ echo "$varlocation"
  /home/flight/git/reference-evaluation/regression_tests/environment_variables.sh
  $ for ip in "${all_nodes_priv_ips[@]}" ; do
  > flight hunter list --plain --buffer | grep "$ip"
  > done
