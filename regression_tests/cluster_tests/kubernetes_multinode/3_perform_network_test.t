Peform a network test as in the documentation
  $ cd $dirlocation

  $ flight silo file pull openflight:kubernetes/php-apache.yaml
  Pulling '/kubernetes/php-apache.yaml' into '*'... (glob)
  File(s) downloaded to */php-apache.yaml (glob)
  $ kubectl apply -f php-apache.yaml
  deployment.apps/php-apache created
  service/php-apache created

  $ for i in {0..60}; do sleep 1; if [[ $(kubectl get pods | grep "php-apache" | awk '{print $3}') == "Running" ]]; then echo "running"; break; fi; done;
  running
  $ flight silo file pull openflight:kubernetes/busybox-wget.yaml
  Pulling '/kubernetes/busybox-wget.yaml' into '*'... (glob)
  File(s) downloaded to */busybox-wget.yaml (glob)

  $ kubectl apply -f busybox-wget.yaml
  pod/busybox-wget created

  $ for i in {0..60}; do sleep 1; if [[ $(kubectl get pods busybox-wget | awk '{print $3}' | grep -v "STATUS") == "Completed" ]]; then echo "completed"; break; fi; done;
  completed

  $ kubectl logs busybox-wget
  OK! (no-eol)
