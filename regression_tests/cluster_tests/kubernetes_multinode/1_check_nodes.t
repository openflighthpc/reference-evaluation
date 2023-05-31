Check that kubernetes nodes are ready

  $ kubectl get nodes | grep "control-plane" | awk '{print $2}'
  Ready

  $ kubectl get nodes | grep "<none>" | awk '{print $2}'
