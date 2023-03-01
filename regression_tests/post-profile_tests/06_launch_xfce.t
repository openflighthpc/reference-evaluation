Check if you can launch xfce

  $ flight desktop start xfce
  Starting a '\x1b[36mxfce\x1b[0m' desktop session: (esc)
  
     > \xe2\x9c\x85 \x1b[38;2;39;148;216mStarting session\x1b[0m (esc)
  
  A '\x1b[36mxfce\x1b[0m' desktop session has been started. (esc)
  Identity\t* (esc) (glob)
  Type\txfce (esc)
  Host IP\t* (esc) (glob)
  Hostname\t* (esc) (glob)
  Port\t* (esc) (glob)
  Display\t:* (esc) (glob)
  Password\t* (esc) (glob)
  State\tActive (esc)
  WebSocket Port\t* (esc) (glob)
  Created At\t* (esc) (glob)
  Last Accessed At\t (esc)
  Screenshot Path\t/home/flight/.cache/flight/desktop/sessions/*/session.png (esc) (glob)
  IPs\t*|* (esc) (glob)
  Name\t (esc)
  Geometry\t1024x768 (esc)
  Job ID\t (esc)
  Available Geometries\t1920x1200|1920x1080|1680x1050|1600x1200|1400x1050|1360x768|1280x1024|1280x960|1280x800|1280x720|1024x768|800x600|640x480 (esc)
  Capabilities\tresizable (esc)



  $ flight desktop list | grep "xfce" | grep "Active"
  *\txfce\t*\t*\t1\t*\t41361\t*\tActive\t*\t*\t/home/flight/.cache/flight/desktop/sessions/*/session.png\t*|*\t\t (esc) (glob)

  $ flight desktop kill "$(flight desktop list | grep "xfce" | cut  -f1)"
  Killing desktop session \x1b[35m*\x1b[0m: (esc) (glob)
  
     > \xe2\x9c\x85 \x1b[38;2;39;148;216mTerminating session\x1b[0m (esc)
  
  Desktop session '\x1b[35m*\x1b[0m' has been terminated. (esc) (glob)
  




