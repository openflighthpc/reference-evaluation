Configure profile for kubernetes multinode, then apply relevant identities
  $ sudo mkdir /opt/flight/opt/profile/var/answers
  $ echo "---\ncluster_name: my-cluster\ndefault_username: flight\ndefault_password: 0penfl1ght\nnfs_server: node00\naccess_host:'${login_pub_ip}'\ncompute_ip_range: ${ip_range}\npod_ip_range: ${kube_pod_range}\nhunter_hosts: true" | sudo tee /opt/flight/opt/profile/var/answers/openflight-kubernetes-multinode.yaml >> /dev/null
  $ echo "cluster_type: openflight-kubernetes-multinode" | sudo tee -a /opt/flight/opt/profile/etc/config.yml >> /dev/null
  $ flight profile apply node00 master
  Applying 'master' to host 'node00'
  The application process has begun. Refer to `flight profile list` or `flight profile view` for more details

  $ flight profile apply "$(flight hunter list --plain | grep -v 'node00' | grep -o 'node0.' | sed -z 's/\n/,/g;s/,$/\n/')" worker
  Applying 'worker' to hosts * (glob)
  The application process has begun. Refer to `flight profile list` or `flight profile view` for more details
