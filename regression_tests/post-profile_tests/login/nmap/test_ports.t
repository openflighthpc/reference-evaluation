Test that ports 80 and 443 are accessible

  $ sudo nmap -p 8888,22,80,443 -sU -sS $login_pub_ip
  Starting Nmap * ( https://nmap.org ) at * * GMT (glob)
  Nmap scan report for * (glob)
  Host is up (*s latency). (glob)
  
  PORT     STATE         SERVICE
  22/tcp   open          ssh
  80/tcp   open          http
  443/tcp  open          https
  8888/tcp open          sun-answerbook
  22/udp   open|filtered ssh
  80/udp   open|filtered http
  443/udp  open|filtered https
  8888/udp open|filtered ddi-udp-1
  
  Nmap done: 1 IP address (1 host up) scanned in * seconds (glob)


