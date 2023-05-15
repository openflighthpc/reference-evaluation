Test that ports 80 and 443 are accessible

  $ nmap "$login_pub_ip"
  Starting Nmap * ( https://nmap.org ) at * * GMT (glob)
  Nmap scan report for * (*) (glob)
  Host is up (*s latency). (glob)
  Not shown: 993 filtered ports
  PORT     STATE  SERVICE
  22/tcp   open   ssh
  80/tcp   open   http
  443/tcp  open   https
  5900/tcp closed vnc
  5901/tcp closed vnc-1
  5902/tcp closed vnc-2
  5903/tcp closed vnc-3
  
  Nmap done: 1 IP address (1 host up) scanned in * seconds (glob)
