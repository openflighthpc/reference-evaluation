Configure profile for kubernetes multinode, then apply relevant identities
  $ echo "---\ncluster_name: my-cluster\ndefault_username: flight\ndefault_password: 0penfl1ght\nnfs_server: login1\naccess_host:\ncompute_ip_range: $ip_range\npod_ip_range: $kube_pod_range\nhunter_hosts: true" | sudo tee /opt/flight/opt/profile/var/answers/openflight-kubernetes-multinode.yaml >> /dev/null

  $ echo "cluster_type: openflight-kubernetes-multinode" | sudo tee -a /opt/flight/opt/profile/etc/config.yml >> /dev/null
  $ flight profile apply node00 master

  $ flight profile apply "$(flight hunter list --plain | grep -v 'node00' | grep -o 'node0.' | sed -z 's/\n/,/g;s/,$/\n/')" worker
