(login node only) try connecting to root on other nodes

  $ . "$varlocation"
  $ for ip in "${all_nodes_priv_ips[@]}" ; do
  > sudo runuser -l root  -c "ssh -n  $ip -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null'"
  > done
