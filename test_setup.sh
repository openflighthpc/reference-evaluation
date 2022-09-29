#!/bin/bash

# this script should be run as root from the head node

# ok we'll make a script to test if the head node has been setup properly

out=/var/log/setup_test.out

# function to remove items
remove_item () {
  local remove=$1     # first element of arguments is the thing we want to remove
  shift               # remove that first element
  local array=("$@")  # All remaining elements are the array
  local output=()     # Prepare output array

  for e in ${array[@]}; do
    if [[ $e != $remove ]]; then
      output+=($e)
    fi
  done
  echo ${output[@]}
}

echo "Testing Begins Now:"

echo "Node names required, enter name or leave blank if all have been named."

# change this back later, im making it hard coded for faster testing
#echo "Enter HEAD node name: "
# read headname
headname="chead1"

echo "Enter COMPUTE node name (leave blank if all named)"

read cnodename

# get a list of all the compute nodes (cnodes)
cnodeList=()
while [[ $cnodename != ""  ]]
do
	if [[ ! " ${cnodeList[*]} " =~ " ${cnodename} " ]]; then # make duplicate inputs impossible
		cnodeList+=($cnodename)
	fi
	echo "Enter COMPUTE node name (leave blank if all named)"
	read cnodename
done

# ---------------------- Testing Zone -------------------------

#remove_item "cnode02" ${cnodeList[*]} 1

#--------------------------------------------------------------


# print them out to make sure we're doing things right

echo "-----------" >> $out
echo "Head node is: $headname" > $out
echo "-----------" >> $out
echo "All compute nodes are: " >> $out
for c in ${cnodeList[@]}; do
	echo $c >> $out
done
echo "-----------" >> $out


# ---------------------- Testing Zone -------------------------

#temp=$(remove_item "cnode02" ${cnodeList[*]})
#unset cnodeList
#cnodeList=${temp[*]}
#unset temp

#echo "cnodeList now:"
#echo ${cnodeList[*]}

#--------------------------------------------------------------


# now we know what all the compute nodes are we can get onto testing

# Page 1: Node Setup

# Test 1: ping all nodes

for c in ${cnodeList[@]}; do
	ping $c -c 1  >> /dev/null 2>>$out 
	
	pingOut=$?

	if [[ $pingOut != 0 ]]
	then
		echo "($c) ping command failed, check doc page \"Node Setup\"."
		echo "($c) ping failed, no further testing on this node" >> $out

    # remove the ping failer from list of nodes
    temp=$(remove_item $c ${cnodeList[*]})
    unset cnodeList
    cnodeList=${temp[*]}
    unset temp
    # end remove

	else
		echo "($c) ping successful" >> $out
	fi
done

# Test 2: Check SELinux status on this node

selinuxState=$(getenforce)

if [[ $selinuxState = Permissive ]] || [[ $selinuxState = Disabled ]]
then
	if [[ $(grep disabled /etc/selinux/config -c) < 2 ]]
	then
		"($headname) SELinux not disabled in config file, check doc page \"Node Setup\"."
	fi
else
	echo "($headname) SELinux state incorrect, check doc page \"Node Setup\"."
fi

echo "($headname) SELinux state: $selinuxState" >> $out

# Page 2

# Test 1: should be able to ssh into other nodes

sshList=()

for c in ${cnodeList[@]}; do
	ssh $c exit 1>>/dev/null 2>>$out 
  sshOut=$?
	if [[ $sshOut != 0 ]]
	then
		echo "($c) SSH failed, check doc page \"SSH Keys for Root\" "
		echo "($c) SSH failed with exit code ${sshOut}, no more testing on this node." >> $out

    # remove the ssh failer from list of nodes
    temp=$(remove_item $c ${cnodeList[*]})
    unset cnodeList
    cnodeList=${temp[*]}
    unset temp
    # end remove

	fi
done

# Test 2: check the selinux status on every compute node we can ssh to

for c in ${cnodeList[@]}; do
  selinuxState=$(ssh $c "getenforce" exit) # doesn't work with routing the output to other places
  if [[ $selinuxState = Permissive ]] || [[ $selinuxState = Disabled ]]; then
    if [[ $(ssh $c "grep disabled /etc/selinux/config -c") < 2 ]]; then
      echo "($c) SELinux not disabled in config file, check doc page \"Node Setup\"."
    fi
  fi
  echo "($c) SELinux state: $selinuxState" >> $out
done


# Page 3: Install Repositories

packages=(epel-release)

# Test 1: check if the epel repo is installed on the head

for p in ${packages[@]}; do
	dnf list installed $p 1>>/dev/null 2>>$out; result=$?

	if [[ $result != 0 ]]
	then
		echo "($headname) $p package error, check doc page \"Install Repositories\" "
		echo "($headname) $p package error code: $result" >> $out
	fi
done

# Test 2: (SSH) Check if the epel repo is installed on the other nodes

for p in ${packages[@]}; do
	for c in ${cnodeList[@]}; do
    ssh $c "dnf list installed $p" exit 1>>/dev/null 2>>$out ; result=$?

    if [[ $result != 0 ]]; then
      echo "($c) $p package error, check doc page \"Install Repositories\" "
      echo "($c) $p package error code: $result" >> $out
    fi
	done
done

# Page 4: Setup NFS Server




