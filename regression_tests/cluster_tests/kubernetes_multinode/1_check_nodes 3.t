Check that kubernetes nodes are ready

  $ for i in {0..120}; do sleep 1; if [[ $(kubectl get nodes | grep -ow "Ready" | wc -l) == "$all_nodes_count" ]]; then echo "ready"; break; fi; done;
  ready

  $ kubectl get nodes | grep "control-plane" | awk '{print $2}'
  Ready

  $ kubectl get nodes | grep "<none>" | awk '{print $2}'
