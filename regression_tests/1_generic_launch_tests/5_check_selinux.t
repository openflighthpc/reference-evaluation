Check that SELinux is set correctly

  $ sestatus
  SELinux status:                 disabled

  $ sudo su - 
  * (glob)
 
  $ ssh -n 10.50.0.29 -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "sestatus"
  Warning: Permanently added '*' (ECDSA) to the list of known hosts.\r (esc) (glob)
  SELinux status:                 disabled

  $ ssh -n 10.50.0.15 -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' "sestatus"
  Warning: Permanently added '*' (ECDSA) to the list of known hosts.\r (esc) (glob)
  SELinux status:                 disabled
