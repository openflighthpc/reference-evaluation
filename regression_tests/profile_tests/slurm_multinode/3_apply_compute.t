Apply an identity to every compute node in the cluster (depends on hunter)

  $ flight profile apply "$(flight hunter list --plain | grep -v 'node00' | grep -o 'node0.' | sed -z 's/\n/,/g;s/,$/\n/')" compute
  Applying 'compute' to hosts * (glob)
  The application process has begun. Refer to `flight profile list` or `flight profile view` for more details
