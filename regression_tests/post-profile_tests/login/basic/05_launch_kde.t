Check if kde can be launched

  $ unset LS_COLORS; export TERM=vt220; flight desktop start kde | grep "A 'kde' desktop session has been started."
  A 'kde' desktop session has been started.

  $ flight desktop list | grep "kde" | grep -o "Active"
  Active

  $ flight desktop kill "$(flight desktop list | grep "kde" | cut  -f1)" | grep "has been terminated"
  Desktop session '*' has been terminated. (glob)