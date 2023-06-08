Check if you can install modules

  $ unset LS_COLORS; export TERM=vt220; flight env create modules | grep -o "Environment modules@default has been created"
  Environment modules@default has been created
  $ flight env activate modules
  $ flight env deactivate