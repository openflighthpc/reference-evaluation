Configure profile for slurm multinode, then apply relevant identities
  $ echo "---
cluster_name: mycluster1
nfs_server: login1
slurm_server: login1
default_username: flight
default_password: 0penfl1ght
access_host: 10.151.15.116
compute_ip_range: 10.50.0.0/16
hunter_hosts: true" > /opt/flight/opt/profile/var/answers/openflight-slurm-multinode.yaml

  $ flight profile apply node00 login

  $ flight profile apply node01,node02 comput
