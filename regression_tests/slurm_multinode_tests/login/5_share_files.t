Check that files are being shared
  $ cd ~; touch shareable-file

  $ ssh node01 'test -f "shareable-file"'
  $ cd ~ 
