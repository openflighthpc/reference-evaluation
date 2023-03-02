Check that you can prepare kde

  $ sudo su -
  * (glob)
  $ flight desktop prepare kde
  Preparing desktop type \x1b[36mkde\x1b[0m: (esc)
  
     > \xe2\x9c\x85 \x1b[38;2;39;148;216mInstalling package group: KDE\x1b[0m (esc)
     > \xe2\x9c\x85 \x1b[38;2;39;148;216mPrequisites met\x1b[0m (esc)
     > \xe2\x9c\x85 \x1b[38;2;39;148;216mRunning post verification script\x1b[0m (esc)
  
  Desktop type \x1b[36mkde\x1b[0m has been prepared. (esc)
  
 
  $ exit
  $ flight desktop avail | grep "kde"
  kde\tKDE Plasma Desktop (KDE 4). Plasma is KDE's desktop environment. Simple by default, powerful when needed.\thttps://kde.org/\tVerified (esc)
