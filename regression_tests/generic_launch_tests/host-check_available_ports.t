Check that necessary ports are accessible (must be done on the host)

  $ nmap "$self_pub_ip"
  Starting Nmap * ( https://nmap.org ) at * GMT (glob)
  Nmap scan report for * (glob)
  Host is up (*s latency). (glob)
  Not shown: 992 filtered ports
  PORT     STATE  SERVICE
  22/tcp   open   ssh
  80/tcp   closed http
  443/tcp  closed https
  5900/tcp closed vnc
  5901/tcp closed vnc-1
  5902/tcp closed vnc-2
  5903/tcp closed vnc-3
  8888/tcp open   sun-answerbook
  
  Nmap done: 1 IP address (1 host up) scanned in * seconds (glob)
