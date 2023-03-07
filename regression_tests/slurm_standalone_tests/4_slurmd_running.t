Check that slurm node is running on all compute nodes

  $ sudo systemctl status flight-slurmd | grep -v "batch job"
  * flight-slurmd.service - Slurm node daemon
     Loaded: loaded (/usr/lib/systemd/system/flight-slurmd.service; enabled; vendor preset: disabled)
     Active: active (running) since * *-*-* *:*:* GMT; * ago (glob)
   Main PID: * (slurmd) (glob)
      Tasks: * (glob)
     Memory: *M (glob)
     CGroup: /system.slice/flight-slurmd.service
             `-* /opt/flight/opt/slurm/sbin/slurmd -D -s (glob)
  
  * * *:*:* * systemd[1]: Started Slurm node daemon. (glob)
  * * *:*:* * slurmd[*]: slurmd: slurmd version 22.05.2 started (glob)
  * * *:*:* * slurmd[*]: slurmd: error:  mpi/pmix_v2: init: (null) [0]: mpi_pmix.c:195: pmi/pmix: can not load PMIx library (glob)
  * * *:*:* * slurmd[*]: slurmd: CPUs=* Boards=* Sockets=* Cores=* Threads=* Memory=* TmpDisk=* Uptime=* CPUSpecList=(null) FeaturesAvail=(null) FeaturesActive=(null) (glob)

