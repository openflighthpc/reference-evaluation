Check that gather can collect data successfully

  $ flight gather collect --force
  invalid option: --force
  [1]

  $ flight gather show
  ---
  :primaryGroup: 
  :secondaryGroups: 
  :model: OpenStack Nova
  :bios: 1.16.0-1.module_el8.7.0+1140+ff0772f9
  :serial: ca3ceb03-6585-4b77-9f5c-f09e2bde981d
  :ram: '2888124'
  :cpus:
    CPU0:
      :socket: CPU 0
      :id: C1 06 03 00 FF FB 8B 0F
      :model: RHEL 7.6.0 PC (i440FX + PIIX, 1996)
      :cores: 1
      :hyperthreading: false
    CPU1:
      :socket: CPU 1
      :id: C1 06 03 00 FF FB 8B 0F
      :model: RHEL 7.6.0 PC (i440FX + PIIX, 1996)
      :cores: 1
      :hyperthreading: false
  :network:
    eth0:
      :mac: FA:16:3E:A4:84:96
      :speed: Unknown!
      :ip: 10.50.0.34/24
    virbr0:
      :mac: 52:54:00:64:D0:BB
      :speed: Unknown!
      :ip: 192.168.124.1/24
  :sysuuid: 
  :bootif: 
  :disks:
    vda:
      :size: 20G
  :gpus:
    GPU0:
      :name: Virtio GPU
      :slot: PCI:0000:00:02.0
  :platform: OpenStack
