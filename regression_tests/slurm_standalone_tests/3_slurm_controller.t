Check that the slurm controller is running

  $ sudo systemctl status flight-slurmctld | grep -v "slurmctld:"
  * flight-slurmctld.service - Slurm controller daemon
     Loaded: loaded (/usr/lib/systemd/system/flight-slurmctld.service; enabled; vendor preset: disabled)
     Active: active (running) since * * * GMT; * ago (glob)
   Main PID: * (slurmctld) (glob)
      Tasks: * (glob)
     Memory: * (glob)
     CGroup: /system.slice/flight-slurmctld.service
             |-* /opt/flight/opt/slurm/sbin/slurmctld -D -s (glob)
  
