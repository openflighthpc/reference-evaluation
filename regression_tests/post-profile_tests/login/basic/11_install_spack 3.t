Check if you can install spack

  $ unset LS_COLORS; export TERM=vt220; flight env create spack | grep -o "Environment spack@default has been created"
  Environment spack@default has been created
  $ flight env activate spack
  $ flight env deactivate