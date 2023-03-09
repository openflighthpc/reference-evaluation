Check that files are being shared
  $ cd ~; touch shareable-file

  $ ssh -n -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' node01 'test -f "shareable-file"'
  Warning: Permanently added 'node01,10.50.0.34' (ECDSA) to the list of known hosts.\r (esc)
  $ cd ~ 
