Configure profile for slurm standalone

  $ sudo mkdir /opt/flight/opt/profile/var/answers
  $ echo -e "---\ncluster_name: mycluster1\ndefault_username: flight\ndefault_password: 0penfl1ght\naccess_host: $login_priv_ip" | sudo tee /opt/flight/opt/profile/var/answers/openflight-slurm-standalone.yaml >> /dev/null
  $ echo "cluster_type: openflight-slurm-standalone" | sudo tee -a /opt/flight/opt/profile/etc/config.yml >> /dev/null
