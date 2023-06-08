Check if gnome can be launched

  $ unset LS_COLORS; export TERM=vt220; flight desktop start gnome | grep "A 'gnome' desktop session has been started."
  A 'gnome' desktop session has been started.

  $ flight desktop kill "$(flight desktop list | grep "gnome" | cut  -f1)" | grep "has been terminated"
  Desktop session '*' has been terminated. (glob)