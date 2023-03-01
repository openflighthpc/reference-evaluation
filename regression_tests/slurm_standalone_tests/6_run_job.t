Run a job

  $ echo '#!/bin/bash -l
echo "Starting running on host $HOSTNAME"
sleep 2
echo "Finished running - goodbye from $HOSTNAME"' > testjob.sh
  $ sbatch testjob.sh

  $ rm testjob.sh
