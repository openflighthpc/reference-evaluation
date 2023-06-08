Check if you can install conda

  $ unset LS_COLORS; export TERM=vt220; flight env create conda | grep -o "Environment conda@default has been created"
  Environment conda@default has been created
  $ flight env activate conda
  $ flight env deactivate