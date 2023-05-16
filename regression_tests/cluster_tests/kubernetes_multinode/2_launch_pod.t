Launch a pod

  $ flight silo file pull openflight:kubernetes/pod-launch-test.yaml
  Pulling '/kubernetes/pod-launch-test.yaml' into '/home/flight/git/reference-evaluation/regression_tests'...
  File(s) downloaded to /home/flight/git/reference-evaluation/regression_tests/pod-launch-test.yaml

  $ kubectl apply -f pod-launch-test.yaml
  pod/ubuntu created

  $ kubectl get pods -o wide
  NAME     READY   STATUS    RESTARTS   AGE   IP       NODE     NOMINATED NODE   READINESS GATES
  ubuntu   0/1     Pending   0          1s    <none>   <none>   <none>           <none>
