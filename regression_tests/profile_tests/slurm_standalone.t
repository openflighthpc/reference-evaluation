Configure profile for slurm standalone, then apply relevant identities

  $ sudo mkdir /opt/flight/opt/profile/var/answers
  $ echo -e "---\ncluster_name: mycluster1\ndefault_username: flight\ndefault_password: 0penfl1ght\naccess_host: $login_priv_ip" | sudo tee /opt/flight/opt/profile/var/answers/openflight-slurm-standalone.yaml >> /dev/null
  $ echo "cluster_type: openflight-slurm-standalone" | sudo tee -a /opt/flight/opt/profile/etc/config.yml >> /dev/null
  $ flight profile apply node00 all-in-one
  Applying 'all-in-one' to host 'node00'
  The application process has begun. Refer to `flight profile list` or `flight profile view` for more details

  $ flight profile list | grep "node00" | grep "complete"
