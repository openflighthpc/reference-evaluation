Download and run Apache
  $ cd $dirlocation

  $ flight silo file pull openflight:kubernetes/php-apache.yaml
  Pulling '/kubernetes/php-apache.yaml' into '*'... (glob)
  File(s) downloaded to */php-apache.yaml (glob)
  $ kubectl apply -f php-apache.yaml
  deployment.apps/php-apache created
  service/php-apache created
  $ for i in {0..300}; do sleep 1; if [[ $(kubectl get pods | grep "php-apache" | grep "Running") ]]; then echo "running"; break; fi; done;
  running