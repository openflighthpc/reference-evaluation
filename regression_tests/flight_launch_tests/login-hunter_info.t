Check that hunter buffer holds info on all the nodes we want to find

  $ . "$varlocation"
  $ echo "$varlocation"
  /home/flight/git/reference-evaluation/regression_tests/environment_variables.sh
  $ for ip in "${allnodePrivIPs[@]}" ; do
  > flight hunter list --plain --buffer | grep "$ip"
  > done
  *\t*\t*\t|\t\t{} (esc) (glob)
