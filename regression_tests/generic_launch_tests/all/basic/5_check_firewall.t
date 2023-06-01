Check that the firewall is set correctly

  $ sudo firewall-cmd --list-all --zone public | grep -e "interfaces" -e "ports:" -e "services"
    interfaces: eth0
    services: cockpit dhcpv6-client http https ssh
    ports: 5900-6000/tcp 8888/tcp 8888/udp
    forward-ports: 
    source-ports: 
  $ sudo firewall-cmd --list-all --zone trusted | grep -e "interfaces" -e "ports:" -e "services"
    interfaces: 
    services: 
    ports: 
    forward-ports: 
    source-ports: 
