Download and run the Busybox test
  $ cd $dirlocation

  $ flight silo file pull openflight:kubernetes/busybox-wget.yaml
  Pulling '/kubernetes/busybox-wget.yaml' into '*'... (glob)
  File(s) downloaded to */busybox-wget.yaml (glob)

  $ kubectl apply -f busybox-wget.yaml
  pod/busybox-wget created

  $ for i in {0..120}; do sleep 1; if [[ $(kubectl get pods busybox-wget | grep "Completed") ]]; then echo "completed"; break; fi; done;
  completed