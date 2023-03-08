Check that slurm has identified all nodes

  $ sinfo --Node | grep -v "NODELIST" | wc -l | grep "$computenodescount"
  * (glob)


