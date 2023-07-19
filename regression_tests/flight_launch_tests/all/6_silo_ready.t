Flight silo has a type and repo

  $ flight silo repo list 2>/dev/null | tr -d '\n' | grep -e 'openflight.*true' 2>&1>/dev/null; echo $?
  0

  $ flight silo type avail 2>/dev/null | tr -d '\n' | grep -e 'aws.*true' 2>&1>/dev/null; echo $?
  0
