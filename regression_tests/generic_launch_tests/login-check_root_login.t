(login node only) try connecting to root on other nodes

  $ sudo su -
  * (glob)
  $ ssh -n 10.50.0.41 -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null'
  Pseudo-terminal will not be allocated because stdin is not a terminal.\r (esc)
  Warning: Permanently added '*' (ECDSA) to the list of known hosts.\r (esc) (glob)
  $ exit

