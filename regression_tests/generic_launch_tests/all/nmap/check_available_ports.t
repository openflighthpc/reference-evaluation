Check that necessary ports are accessible (must be done on the host)

  $ sudo nmap -p 8888,22 -sUS $self_pub_ip
  Starting Nmap * ( https://nmap.org ) at * * GMT (glob)
  Nmap scan report for * (*) (glob)
  Host is up (*s latency). (glob)
  
  PORT     STATE         SERVICE
  22/tcp   open          ssh
  8888/tcp open          sun-answerbook
  22/udp   open|filtered ssh
  8888/udp open|filtered ddi-udp-1
  
  Nmap done: 1 IP address (1 host up) scanned in * seconds (glob)
