Check if DNS resolves

  $ ping google.com -c 3
  PING google.com (142.250.187.238) 56(84) bytes of data.
  64 bytes from lhr25s34-in-f14.1e100.net (142.250.187.238): icmp_seq=1 ttl=116 time=* ms (glob)
  64 bytes from lhr25s34-in-f14.1e100.net (142.250.187.238): icmp_seq=2 ttl=116 time=* ms (glob)
  64 bytes from lhr25s34-in-f14.1e100.net (142.250.187.238): icmp_seq=3 ttl=116 time=* ms (glob)
  
  --- google.com ping statistics ---
  3 packets transmitted, 3 received, 0% packet loss, time *ms (glob)
  rtt min/avg/max/mdev = */*/*/* ms (glob)

  $ sudo su -

  $ ssh -n 10.50.0.29 -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "ping google.com -c 3"

  $ ssh -n 10.50.0.15 -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "ping google.com -c 3"
