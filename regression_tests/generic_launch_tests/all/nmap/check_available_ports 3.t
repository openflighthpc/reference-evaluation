Check that necessary ports are accessible (must be done on the host)

  $ sudo nmap -p 8888,22 -sUS $self_pub_ip | grep -v "Nmap"
  Host is up (* latency). (glob)
  
  PORT     STATE         SERVICE
  22/tcp   open          ssh
  8888/tcp open          sun-answerbook
  22/udp   open|filtered ssh
  8888/udp open|filtered ddi-udp-1
  
