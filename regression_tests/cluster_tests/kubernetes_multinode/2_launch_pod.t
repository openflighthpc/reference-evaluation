Launch a pod

  $ flight silo file pull openflight:kubernetes/pod-launch-test.yaml
  Pulling '/kubernetes/pod-launch-test.yaml' into '*'... (glob)
  File(s) downloaded to */pod-launch-test.yaml (glob)

  $ kubectl apply -f pod-launch-test.yaml
  pod/ubuntu created

  $ for i in {0..60}; do sleep 1; if [[ $(kubectl get pods ubuntu | awk '{print $3}' | grep -v "STATUS") == "Running" ]]; then echo "running"; break; fi; done;
  running