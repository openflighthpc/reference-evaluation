Configure profile for slurm multinode, then apply relevant identities
  $ echo -e "---\ncluster_name: mycluster1\nnfs_server: login1\nslurm_server: login1\ndefault_username: flight\ndefault_password: 0penfl1ght\naccess_host: $login_pub_ip\ncompute_ip_range: ip_range\n"
hunter_hosts: true" > /opt/flight/opt/profile/var/answers/openflight-slurm-multinode.yaml

  $ flight profile apply node00 login

  $ for n in "${allnodePrivIPs[@]}" ; do
  > flight profile apply node0${n} compute
  > done


