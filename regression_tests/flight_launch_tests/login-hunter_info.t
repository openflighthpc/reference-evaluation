Check that hunter buffer holds info on all the nodes we want to find

  $ . "$varlocation"
  $ for ip in "${all_nodes_priv_ips[@]}" ; do
  > flight hunter list --plain --buffer | grep "$ip"
  > done
