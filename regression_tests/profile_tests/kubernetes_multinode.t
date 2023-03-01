Configure profile for kubernetes multinode, then apply relevant identities
  $ echo "---
cluster_name: my-cluster
default_username: flight
default_password: 0penfl1ght
nfs_server: login1
access_host:
compute_ip_range: 10.10.0.0/16
pod_ip_range: 192.168.0.0/16
hunter_hosts: true
" > /opt/flight/opt/profile/var/answers/openflight-kubernetes-multinode.yaml 

  $ flight profile apply node00 master

  $flight profile apply node01,node02 worker
