#!/bin/bash
export all_nodes_count="3"
export computenodescount="2"
export ip_range="10.50.0.0/16"
export kube_pod_range="192.168.0.0/16"
export login_priv_ip="10.50.0.47"
export login_pub_ip="10.151.15.229"
export self_pub_ip="10.151.15.229"
export all_nodes_priv_ips=( "10.50.0.47" "10.50.0.37" "10.50.0.33" )
export dirlocation="/home/flight/git/reference-evaluation/regression_tests/"
export varlocation="${dirlocation}environment_variables.sh"
export autoparsematch="false"
export self_label=""
export self_prefix=""