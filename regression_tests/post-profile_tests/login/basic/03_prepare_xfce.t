Check that you can prepare xfce

  $ sudo su -
  * (glob)
  $ unset LS_COLORS; export TERM=vt220; flight desktop prepare xfce | grep -o "Desktop type xfce has been prepared"
  Desktop type xfce has been prepared
  $ exit
  $ flight desktop avail | grep "xfce"
  xfce\tXfce is a lightweight desktop environment for UNIX-like operating systems. It aims to be fast and low on system resources, while still being visually appealing and user friendly.\thttps://xfce.org/\tVerified (esc)
