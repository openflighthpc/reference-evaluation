Check that gather already has data that it can show

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
