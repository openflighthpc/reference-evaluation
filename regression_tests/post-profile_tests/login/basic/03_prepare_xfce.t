Check that you can prepare xfce

  $ sudo su -
  * (glob)
  $ flight desktop prepare xfce
  Preparing desktop type \x1b[36mxfce\x1b[0m: (esc)
  
     > \xe2\x9c\x85 \x1b[38;2;39;148;216mInstalling package group: Xfce\x1b[0m (esc)
     > \xe2\x9c\x85 \x1b[38;2;39;148;216mPrequisites met\x1b[0m (esc)
     > \xe2\x9c\x85 \x1b[38;2;39;148;216mRunning post verification script\x1b[0m (esc)
  
  Desktop type \x1b[36mxfce\x1b[0m has been prepared. (esc)
  
  $ exit
  $ flight desktop avail | grep "xfce"
  xfce\tXfce is a lightweight desktop environment for UNIX-like operating systems. It aims to be fast and low on system resources, while still being visually appealing and user friendly.\thttps://xfce.org/\tVerified (esc)
