Peform a network test as in the documentation

  $ flight silo file pull openflight:kubernetes/php-apache.yaml
  Pulling '/kubernetes/php-apache.yaml' into '/tmp/*/3_perform_network_test.t'... (glob)
  File(s) downloaded to /tmp/*/3_perform_network_test.t/php-apache.yaml (glob)
  $ kubectl apply -f php-apache.yaml
  deployment.apps/php-apache created
  service/php-apache created

  $ flight silo file pull openflight:kubernetes/busybox-wget.yaml
  Pulling '/kubernetes/busybox-wget.yaml' into '/tmp/*/3_perform_network_test.t'... (glob)
  File(s) downloaded to /tmp/*/3_perform_network_test.t/busybox-wget.yaml (glob)

  $ kubectl apply -f busybox-wget.yaml
  pod/busybox-wget created

  $ kubectl logs busybox-wget
  OK!
