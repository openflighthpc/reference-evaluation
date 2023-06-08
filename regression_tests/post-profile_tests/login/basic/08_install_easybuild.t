Check if you can install easybuild

  $ unset LS_COLORS; export TERM=vt220; flight env create easybuild | grep -o "Environment easybuild@default has been created"
  Environment easybuild@default has been created
  $ flight env activate easybuild
  $ flight env deactivate