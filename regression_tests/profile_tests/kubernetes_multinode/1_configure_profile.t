Trick flight solo into thinking profile is configured
  $ sudo mkdir /opt/flight/opt/profile/var/answers
  $ echo -e "---\ncluster_name: my-cluster\ndefault_username: flight\ndefault_password: 0penfl1ght\nnfs_server: node00\naccess_host:'${login_pub_ip}'\ncompute_ip_range: ${ip_range}\npod_ip_range: ${kube_pod_range}\nhunter_hosts: true" | sudo tee /opt/flight/opt/profile/var/answers/openflight-kubernetes-multinode.yaml >> /dev/null
  $ echo "cluster_type: openflight-kubernetes-multinode" | sudo tee -a /opt/flight/opt/profile/etc/config.yml >> /dev/null
