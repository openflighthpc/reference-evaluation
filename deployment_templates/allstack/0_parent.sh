#!/bin/bash -l

# setup variables, handle input
source "./1_setup.sh" "$@"; result=$? # run the setup script with all the parameters that this script gets

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

source "./2_create_standalone.sh"; result=$?

if [[ $result != 0 ]];then
  exit $result
fi

if [[ $standalone = true ]];then
  source "./2a_standalone_testing.sh"; result=$?
  echoplus -v 0 "Login public IP: $login_public_ip"
  echoplus -v 0 "Login private IP: $login_private_ip"
  exit $result
fi

source "./3_create_cnodes.sh"; result=$?

# get exit code and output it to console and log file during creation
# use success/failure to determin if should auto delete
# bulk create
# 
# Additional?
# azure support
# combine platforms into one process use export
# 
# source child scripts
