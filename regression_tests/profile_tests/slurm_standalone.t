Configure profile for slurm standalone, then apply relevant identities

  $ echo "---
cluster_name: mycluster1
default_username: flight
default_password: 0penfl1ght
access_host: 10.151.15.116" > /opt/flight/opt/profile/var/answers/openflight-slurm-standalone.yaml

  $ flight profile apply node00 login


