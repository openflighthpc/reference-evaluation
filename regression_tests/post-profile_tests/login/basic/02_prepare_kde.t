Check that you can prepare kde

  $ sudo su -
  * (glob)
  $ unset LS_COLORS; export TERM=vt220; flight desktop prepare kde | grep "Desktop type kde has been prepared"
  Desktop type kde has been prepared.
  $ exit
  $ flight desktop avail | grep "kde"
  kde\tKDE Plasma Desktop (KDE 4). Plasma is KDE's desktop environment. Simple by default, powerful when needed.\thttps://kde.org/\tVerified (esc)