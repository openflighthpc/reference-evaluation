Configure profile for slurm multinode, then apply relevant identities
  $ sudo mkdir /opt/flight/opt/profile/var/answers

  $ echo -e "---\ncluster_name: mycluster1\nnfs_server: login1\nslurm_server: login1\ndefault_username: flight\ndefault_password: 0penfl1ght\naccess_host: '${login_pub_ip}'\ncompute_ip_range: ${ip_range}\nhunter_hosts: true" | sudo tee /opt/flight/opt/profile/var/answers/openflight-slurm-multinode.yaml >> /dev/null

  $ echo "cluster_type: openflight-slurm-multinode" | sudo tee -a /opt/flight/opt/profile/etc/config.yml >> /dev/null

  $ flight profile apply node00 login
  Applying 'login' to host 'node00'
  The application process has begun. Refer to `flight profile list` or `flight profile view` for more details

  $ flight profile apply "$(flight hunter list --plain | grep -v 'node00' | grep -o 'node0.' | sed -z 's/\n/,/g;s/,$/\n/')" compute
  Applying 'compute' to hosts * (glob)
  The application process has begun. Refer to `flight profile list` or `flight profile view` for more details

