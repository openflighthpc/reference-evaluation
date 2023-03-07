Run a job

  $ echo -e '#!/bin/bash -l\necho "Starting running on host $HOSTNAME"\nsleep 1\necho "Finished running - goodbye from $HOSTNAME"' > testjob.sh
  $ sbatch testjob.sh
  Submitted batch job * (glob)
  $ squeue
               JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                   *       all testjob.   flight PD       0:00      1 (None) (glob)
  $ sleep 5
  $ squeue
               JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
  $ rm testjob.sh
