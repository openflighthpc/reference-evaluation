Apply identities to worker nodes.
  $ flight profile apply "$(flight hunter list --plain | grep -v 'node00' | grep -o 'node0.' | sed -z 's/\n/,/g;s/,$/\n/')" worker
  Applying 'worker' to hosts * (glob)
  The application process has begun. Refer to `flight profile list` or `flight profile view` for more details
