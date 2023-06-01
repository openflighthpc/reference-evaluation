Check that gather can collect data successfully

  $ flight gather collect 
  Beginning data gather...
  Gathering physical data...
  Gathering logical data...
  Data gathered and written to /opt/flight/opt/gather/var/data.yml

  $ flight gather show | grep -v '  '
  ---
  :primaryGroup: 
  :secondaryGroups: 
  :model: * (glob)
  :bios: * (glob)
  :serial: * (glob)
  :ram: * (glob)
  :cpus:
  :network:
  :sysuuid: 
  :bootif: 
  :disks:
  :gpus:
  :platform: * (glob)
