#!/bin/bash -l

# setup variables, handle input
source "./etc/regression.conf"; result=$?

if [[ $result != 0 ]];then
  exit $result
fi

source "./cluster_scripts/1_setup.sh" "$@"; result=$? # run the setup script with all the parameters that this script gets

case $result in

  1)
    echo "setup failed"
    exit 1
    ;;
  2)
    exit 0 # exit on help message
    ;;
esac

# create standalone/login, confirm creation, get IP

source "./cluster_scripts/2_create_standalone.sh"; result=$?

if [[ $result != 0 ]];then
  exit $result
fi

if [[ $standalone = true ]];then
  source "./cluster_scripts/2a_standalone_testing.sh"; result=$?
  echoplus -v 0 "Login public IP: $login_public_ip"
  echoplus -v 0 "Login private IP: $login_private_ip"
  exit $result
fi

source "./cluster_scripts/3_create_cnodes.sh"; result=$?
echo "compute node deployment: $result"
source "./cluster_scripts/4_cnode_testing.sh"; result=$?

echoplus -v 0 "login_public_ip=${login_public_ip}"
echoplus -v 0 "login_private_ip=${login_private_ip}"

count=1
for i in ${cnodes_public_ips[@]}; do
  echoplus -v 0 "cnode0${count}_public_ip=${i}"
  let count+=1
done
count=1
for i in ${cnodes_private_ips[@]}; do
  echoplus -v 0 "cnode0${count}_private_ip=${i}"
  let count+=1
done

# get exit code and output it to console and log file during creation
# use success/failure to determine if should auto delete
# bulk create
# 
# Additional?
# azure support
# combine platforms into one process use export
# 
# source child scripts
