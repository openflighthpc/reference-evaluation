Check that everything applied successfully

  $ . "$varlocation"
  $ for n in `seq 0 $computenodescount`; do
  > flight profile list | grep "node0${n}" | grep "complete" | sed 's/│//g ; s/master//g ; s/worker//g ; s/      / /g'
  > done
