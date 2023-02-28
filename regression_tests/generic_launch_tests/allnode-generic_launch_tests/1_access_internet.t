Node should be able to ping 8.8.8.8

  $ ping 8.8.8.8 -c 3
  PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
  64 bytes from 8.8.8.8: icmp_seq=1 ttl=116 time=* ms (glob)
  64 bytes from 8.8.8.8: icmp_seq=2 ttl=116 time=* ms (glob)
  64 bytes from 8.8.8.8: icmp_seq=3 ttl=116 time=* ms (glob)
  
  --- 8.8.8.8 ping statistics ---
  3 packets transmitted, 3 received, 0% packet loss, time *ms (glob)
  rtt min/avg/max/mdev = */*/*/* ms (glob)
