Check that the firewall is set correctly

  $ sudo firewall-cmd --list-all --zone public
  public (active)
    * (glob)
    * (glob)
    interfaces: eth0
    * (glob)
    services: * http https ssh (glob)
    ports: 5900-6000/tcp 8888/tcp
    * (glob)
    * (glob)
    * (glob)
    * (glob)
    * (glob)
    * (glob)
    * (glob)

  $ sudo firewall-cmd --list-all --zone trusted
  trusted (active)
    * (glob)
    * (glob)
    interfaces: 
    * (glob)
    services: 
    ports: 
    * (glob)
    * (glob)
    * (glob)
    * (glob)
    * (glob)
    * (glob)
    * (glob)
