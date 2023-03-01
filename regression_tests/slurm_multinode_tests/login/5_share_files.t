Check that files are being shared

  $ touch sharable-file

  $ ssh node01

  $ test -f "sharable-file"
