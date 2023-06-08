Check if you can install singularity

  $ unset LS_COLORS; export TERM=vt220; flight env create singularity | grep -o "Environment singularity@default has been created"
  Environment singularity@default has been created
  $ flight env activate singularity
  $ flight env deactivate