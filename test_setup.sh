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

remove_cnode(){
  local remove=$1
  temp=$(remove_item $remove ${cnodeList[*]})
  unset cnodeList
  cnodeList=${temp[*]}
  unset temp
}

# ---------------Testing Zone ------------------------



# ---------------------------------------------------


# function to check for repo

echo "Testing Begins Now:"

echo "Node names required, enter name or leave blank if all have been named."

# change this back later, im making it hard coded for faster testing
#echo "Enter HEAD node name: "
# read headname
headname="chead1"

echo "Enter COMPUTE node name (leave blank if all named)"

read cnodeName

# get a list of all the compute nodes (cnodes)
cnodeList=()
while [[ $cnodeName != ""  ]]
do
	if [[ ! " ${cnodeList[*]} " =~ " ${cnodeName} " ]]; then # make duplicate inputs impossible
		cnodeList+=($cnodeName)
	fi
	echo "Enter COMPUTE node name (leave blank if all named)"
	read cnodeName
done

# ---------------------- Testing Zone -------------------------

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
    remove_cnode $c
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


# Test 3: Check that head node ip address is the same as in /etc/hosts

headIP=$(hostname -I)

if [[ $(awk "/$headname/{ print NR; exit }" /etc/hosts) != $(awk "/$headIP/{ print NR; exit }" /etc/hosts) ]]; then
  echo "($headname) not set to correct IP in hosts file, see documenatation page \"Node Setup\"."
  echo "($headname) IP set incorrectly in /etc/hosts file, should be $headIP"
fi


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
    remove_cnode $c
	fi
done

# Test 2: check the selinux status on every compute node we can ssh to

for c in ${cnodeList[@]}; do
  selinuxState=$(ssh $c "getenforce" exit) # doesn't work with routing the output to other places
  if [[ $selinuxState = Permissive ]] || [[ $selinuxState = Disabled ]]; then
    if [[ $(ssh $c "grep disabled /etc/selinux/config -c") < 2 ]]; then
      echo "($c) SELinux not disabled in config file, see documentation \"Node Setup\"."
    fi
  else
    echo "($c) SELinux is enforcing, see documentation page \"Node Setup\"."
   
  fi
  echo "($c) SELinux state: $selinuxState" >> $out
done


# Test 3: Check that /etc/hosts file is correct on all nodes

allNodes=("$headname")
for c in ${cnodeList[@]}; do
  allNodes+=("$c")
done

ipList=("$(hostname -I)")
for c in ${cnodeList[@]}; do # get every ip address
  ipList+=("$(ssh $c "hostname -I")")
done

for i in ${!allNodes[@]}; do # check headnode hosts file
  if [[ $(awk "/${allNodes[$i]}/{ print NR; exit }" /etc/hosts) != $(awk "/${ipList[$i]}/{ print NR; exit }" /etc/hosts) ]]; then
    echo "($headname) In hosts file, IP error for ${allNodes[$i]}, see documenatation page \"Node Setup\"."
    echo "($headname) In /etc/hosts, ${allNodes[$i]} IP should be ${allNodes[$i]}" >> $out
  fi
done

for c in ${cnodeList[@]}; do # now check compute nodes
  for i in ${!allNodes[@]}; do # check headnode hosts file

    nodeLine=$(ssh $c "awk '/${allNodes[$i]}/{ print NR; exit }' /etc/hosts")
    ipLine=$(ssh $c "awk '/${ipList[$i]}/{ print NR; exit }' /etc/hosts")

    if [[ $nodeLine != $ipLine ]]; then
      echo "($c) In hosts file, IP error for ${allNodes[$i]}, see documenatation page \"Node Setup\"."
      echo "($c) In /etc/hosts, ${allNodes[$i]} IP should be ${ipList[$i]}" >> $out
    fi
  done
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
# this is just for the head node
# should i check to make sure nfs-utils is installed? probably

# Test 0: 

# Test 1: check for necessary directories on the head node
# /opt/{apps,data,service,site} and /export/{apps,data,service,site}

primeDirs=(opt export)
subDirs=(apps data service site)

for p in ${primeDirs[@]}; do
  for s in ${subDirs[@]}; do
    if [[ ! -d "/$p/$s/" ]]; then
      echo "($headname) Directory \""/$p/$s/"\" does not exist, see documentation page \"Setup NFS Server\""
      echo "($headname) Directory \""/$p/$s/"\" does not exist." >> $out
    elif [[ $p = export ]]; then
      perm=$(stat -c %a /$p/$s)
      if [[ ! $perm = 775 ]];then # Test 2: Check that /export/ has the permissions 775
        echo "($headname) Directory \""/$p/$s/"\" has incorrect permissions, see documentation page \"Setup NFS Server\""
        echo "($headname) Directory \""/$p/$s/"\" has permissions $perm - should be 775" >> $out
      fi
    fi
  done
done
unset primeDirs

#Test 3: /etc/exports contains the correct information
# idea: go through every line until all the content has been found?
#Test 4: /etc/fstab contains the correct information

#Test 5: systemctl status nfs-server.service is active with no errors
systemctl status nfs-server.service 1>>/dev/null 2>>$out; result=$?
if [[ $result != 0 ]]; then
  echo "($headname) nfs-server.service error, see documentation page \"Setup NFS Server\""
  echo "($headname) nfs-server.service error, system status exit code $result" >> $out
fi

# Test 6: the correct stuff has been exported showmount --exports
# Test 6: check if $(showmount --exports --no-header) is the same output as $(showmount -e chead1 --no-header)

headExport=$(showmount --exports --no-header)

for c in ${cnodeList[@]};do
  nodeExport=$(ssh $c "showmount -e $headname --no-header")
  if [[ $headExport != $nodeExport ]]; then
    echo "($headname/$c) Mismatched mount points, see documentation pages: \"Setup NFS Server\" and \"Setup NFS Clients\""
    echo "($headname/$c) Mismatched mount points: " >> $out
    echo "$headname export:" >> $out
    echo "$headExport" >> $out
    echo "$c export:" >> $out
    echo "$nodeExport" >> $out
  fi
done

# Test 7: check that all compute nodes are mounted

mounted=($(showmount --no-header))

for c in ${cnodeList[@]};do
  nodeIP=$(ssh $c "hostname -I")
  found=false
  for m in ${mounted[@]};do
    if [[ "$m " == "$nodeIP" ]];then
      found=true
      break
    fi
  done
  if [[ $found = "false" ]]; then
    echo "($c) Node is not detectably mounted, see documentation pages: \"Setup NFS Server\" and \"Setup NFS Clients\""
    echo "($c) NFS issue, node is not detectably mounted." >> $out
  fi
done

# Page 5: Setup NFS Clients

# Test 1: check that /opt/ exists

# "opt"
subDirs=(apps data service site)

for c in ${cnodeList[@]}; do
  for s in ${subDirs[@]}; do
    outDir=$(ssh $c '[ -d /opt/'"$s"'/ ] ; echo $?')
   
    
    if [[ $outDir != 0 ]]; then
      echo "($c) Directory \""/opt/$s/"\" does not exist, see documentation page \"Setup NFS Clients\""
      echo "($c) Directory \""/opt/$s/"\" does not exist." >> $out
    fi
  done
done
unset outDir

# Test 2: check that $(df -t nfs) shows what we're expecting

for c in ${cnodeList[@]};do
  unset result

  result=($(ssh $c 'df -t nfs' 2>>$out))

  if [[ ${#result[@]} -eq 0 ]]; then
    echo "($c) No directories mounted, see documentation page \"Setup NFS Clients\""
    echo "($c) No directories mounted. " >> $out
    break
  fi

  remotes=()
  locals=()
  for r in ${result[@]};do
    if [[ $r == *'/'* ]]; then
      if [[ $r == *"$headname"* ]];then
        cut="$( echo "$r" | sed 's/'"$headname"'://g')"
        remotes+=("$( echo "$cut" | sed 's/\/export//g')")
      else
        locals+=("$( echo "$r" | sed 's/opt\///g')")
      fi
    fi
  done
  unset cut

  if [[ $remotes != $locals ]];then
    echo "($c) Directories not mounted properly, see documentation page \"Setup NFS Clients\""
    echo "($c) Directories not mounted properly. Remote: $remotes || $ Local: $locals" >> $out
  fi

done

# Page 6: Install Flight
# perform all tests on the head node
# perform all tests on compute nodes


# Test 1: check if the repos are enabled

repos=(openflight powertools)

repolist=$(dnf repolist)
for r in ${repos[@]};do
  echo $repolist | grep $r 1>>/dev/null 2>>$out ; result=$?
  if [[ $result != 0 ]]; then
    echo "($headname) [EXIT] repository $r not found, see documentation page \"Install Flight\""
    echo "($headname) [EXIT] repository $r not found" >> $out
    exit 1
  fi
done
unset result
unset repolist

# now compute node

for c in ${cnodeList[@]}; do
  repolist=$(ssh $c "dnf repolist")
  for r in ${repos[@]};do
    echo $repolist | grep $r 1>>/dev/null 2>>$out ; result=$?
    if [[ $result != 0 ]]; then
      echo "($c) [END] repository $r not found, see documentation page \"Install Flight\""
      echo "($c) [END] repository $r not found" >> $out
      remove_cnode $c
    fi
  done
done
unset result
unset repolist

# Test 2: make sure packages are installed

unset packages
packages=(flight-user-suite flight-plugin-system-systemd-service)

for p in ${packages[@]};do
  dnf list installed $p 1>>/dev/null 2>>$out ; result=$?
  if [[ $result != 0 ]]; then
    echo "($headname) [EXIT] package $p not installed, see documentation page \"Install Flight\""
    echo "($headname) [EXIT] package $p not installed, system status exit code $result" >> $out
    exit 1
  fi
done
unset result

# now compute node
for c in ${cnodeList[@]};do
  for p in ${packages[@]};do
    ssh $c "dnf list installed $p" exit 1>>/dev/null 2>>$out ; result=$?
    if [[ $result != 0 ]]; then
      echo "($c) [END] package $p not installed, see documentation page \"Install Flight\""
      echo "($c) [END] package $p not installed, system status exit code $result" >> $out
      remove_cnode $c
    fi
  done
done

# Test 3: make sure flight-service is started

systemctl status flight-service 1>>/dev/null 2>>$out; result=$?

if [[ $result != 0 ]];then
  echo "($headname) [EXIT] flight-service error, see documentation page \"Install Flight\""
  echo "($headname) [EXIT] flight-service error, system status exit code $result" >>$out
  exit 1
fi

# now compute nodes

for c in ${cnodeList[@]};do
  ssh $c "systemctl status flight-service"  1>> /dev/null 2>>$out; result=$?
  if [[ $result != 0 ]];then
    echo "($c) [END] flight-service error, see documentation page \"Install Flight\""
    echo "($c) [END] flight-service error, system status exit code $result" >>$out
    remove_cnode $c
  fi
done

# Test 4: make sure flight has been started (exit/drop node if not)

flout=$(flight)

#echo $flout

echo $(flight) | grep "not currently active" 1>>/dev/null 2>>$out; result=$?
if [[ $result = 0 ]];then
  echo   
fi
flight start 1>>/dev/null 2>>$out; result=$?

if [[ $result != 0 ]]; then # this trips if the user hasn't logged out and back in
  echo "($headname) [EXIT] flight path not set, see documentation page \"Install Flight\""
  echo "($headname) [EXIT] flight path not set, system status exit code $result" >>$out
  exit 1
else # if the user has done that
  echo $(flight) | grep "not currently active" 1>>/dev/null 2>>$out; result=$?
  if [[ $result = 0 ]];then
    echo "($headname) [EXIT] flight not started, see documentation page \"Install Flight\""
    echo "($headname) [EXIT] flight not started, system status exit code $result" >>$out
    exit 1
  fi
fi

# Test 5: make sure that the cluster has the correct name

clustername=$(flight config get cluster.name)

if [[ $name = "your cluster" ]];then
  echo "($headname) cluster name not set, see documentation page \"Install Flight\""
  echo "($headname) cluster name not set" >>$out
fi



