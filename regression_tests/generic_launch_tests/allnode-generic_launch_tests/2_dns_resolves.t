Node should be able to resolve DNS

  $ ping google.com -c 3
  PING google.com (*) 56(84) bytes of data. (glob)
  64 bytes from * (*): icmp_seq=1 ttl=116 time=* ms (glob)
  64 bytes from * (*): icmp_seq=2 ttl=116 time=* ms (glob)
  64 bytes from * (*): icmp_seq=3 ttl=116 time=* ms (glob)
  
  --- google.com ping statistics ---
  3 packets transmitted, 3 received, 0% packet loss, time *ms (glob)
  rtt min/avg/max/mdev = */*/*/* ms (glob)

