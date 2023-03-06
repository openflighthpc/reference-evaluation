Configure profile for kubernetes multinode, then apply relevant identities
  $ echo "---\ncluster_name: my-cluster\ndefault_username: flight\ndefault_password: 0penfl1ght\nnfs_server: login1\naccess_host:\ncompute_ip_range: $ip_range\npod_ip_range: $kube_pod_range\nhunter_hosts: true" > /opt/flight/opt/profile/var/answers/openflight-kubernetes-multinode.yaml 

  $ flight profile apply node00 master

  $ for n in "${allnodePrivIPs[@]}" ; do
  > flight profile apply node0${n} worker
  > done

