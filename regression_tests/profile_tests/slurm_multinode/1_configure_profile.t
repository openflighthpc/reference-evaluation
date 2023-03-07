Trick Flight Solo into thinking profile is configured
  $ sudo mkdir /opt/flight/opt/profile/var/answers

  $ echo -e "---\ncluster_name: mycluster1\nnfs_server: node00\nslurm_server: node00\ndefault_username: flight\ndefault_password: 0penfl1ght\naccess_host: '${login_pub_ip}'\ncompute_ip_range: ${ip_range}\nhunter_hosts: true" | sudo tee /opt/flight/opt/profile/var/answers/openflight-slurm-multinode.yaml >> /dev/null

  $ echo "cluster_type: openflight-slurm-multinode" | sudo tee -a /opt/flight/opt/profile/etc/config.yml >> /dev/null
