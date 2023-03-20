Check that files are being shared
  $ cd ~; touch shareable-file

  $ ssh -n -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' node01 'test -f "shareable-file"'
  Warning: Permanently added '*' (ECDSA) to the list of known hosts.\r (esc) (glob)
  $ cd ~ 
