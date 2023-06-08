Check if xfce can be launched

  $ unset LS_COLORS; export TERM=vt220; flight desktop start xfce | grep "A 'xfce' desktop session has been started."
  A 'xfce' desktop session has been started.

  $ flight desktop list | grep "xfce" | grep -o "Active"
  Active

  $ flight desktop kill "$(flight desktop list | grep "xfce" | cut  -f1)" | grep "has been terminated"
  Desktop session '*' has been terminated. (glob)