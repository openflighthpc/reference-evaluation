Check that necessary ports are accessible (must be done on the host)

  $ nmap 10.151.15.116
  Starting Nmap 7.93 ( https://nmap.org ) at 2023-02-28 12:15 GMT
  Nmap scan report for 10.151.15.116
  Host is up (0.67s latency).
  Not shown: 899 filtered tcp ports (no-response), 68 filtered tcp ports (host-unreach)
  PORT     STATE  SERVICE
  21/tcp   open   ftp
  22/tcp   open   ssh
  80/tcp   open   http
  443/tcp  open   https
  554/tcp  open   rtsp
  5900/tcp closed vnc
  5901/tcp open   vnc-1
  5902/tcp closed vnc-2
  5903/tcp closed vnc-3
  5904/tcp closed ag-swim
  5906/tcp closed rpas-c2
  5907/tcp closed dsd
  5910/tcp closed cm
  5911/tcp closed cpdlc
  5915/tcp closed unknown
  5922/tcp closed unknown
  5925/tcp closed unknown
  5950/tcp closed unknown
  5952/tcp closed unknown
  5959/tcp closed unknown
  5960/tcp closed unknown
  5961/tcp closed unknown
  5962/tcp closed unknown
  5963/tcp closed indy
  5987/tcp closed wbem-rmi
  5988/tcp closed wbem-http
  5989/tcp closed wbem-https
  5998/tcp closed ncd-diag
  5999/tcp closed ncd-conf
  6000/tcp closed X11
  7070/tcp open   realserver
  8888/tcp open   sun-answerbook
  9090/tcp closed zeus-admin
  
  Nmap done: 1 IP address (1 host up) scanned in 66.76 seconds
