#!/bin/bash -l

# these lines turn the input option into just the first non dash character
outputStyle=$1 #options include: -v/--verbose -q/--quiet -e/--error
temp=$(echo "$outputStyle" | sed -e 's/-//g')
outputStyle=$(echo $temp |  cut -c 1)

case $outputStyle in
  "v" )
    outputStyle=3;;
  "q" )
    outputStyle=1;;
  "e" ) 
    outputStyle=0;;
  * )
    outputStyle=2;;
esac

# this script should be run as root from the head node

# ok we'll make a script to test if the head node has been setup properly

out=/var/log/setup_test.out

# ----------------Function Zone---------------------

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


echoplus() { # adds options to echo like verbose etc
  local verbosity=$1
  shift
  local text=("$@")
  if [[ "$verbosity" -le "$outputStyle" ]];then
    echo "${text[*]}"
  fi     
}

# Function to check if stuff is installed

check_installed () {
  local docPage=$1 # the relevant doc page for use in the error message
  local node=$2 # the node this check should be done on
  shift; shift
  local installs=("$@") # the installs that need to be checked
  badinstall=false

  for i in ${installs[@]};do
    if [[ "$node" = "$headname" ]];then
      dnf list installed $i 1>>/dev/null 2>>$out ; result=$?
    else
      ssh $node "dnf list installed $i" 1>>/dev/null 2>>$out ; result=$?
    fi
    # error messages are the same regardless of node
    if [[ "$result" != "0" ]]; then
        echoplus 0 "($node) $i is not installed, see documentation page \"$docpage\""
        echoplus 0 "($node) $i is not installed, exit code $result" >> $out
        badinstall=true
      fi
  done

  if [[ "$badinstall" = true ]];then
    echo "($node) no further testing possible on this node"
    if [[ "$node" = "$headname" ]];then
      echo "[EXIT]"
      exit 1
    else
      remove_cnode $node
    fi
  else
    echoplus 3 "($node) All necessary packages are installed"
  fi
}

# -----------------END------------------------------


# function to check for repo

echoplus 0 "Node names required, enter name or leave blank if all have been named."

# change this back later, im making it hard coded for faster testing
echoplus 0 "Enter HEAD node name: "
read headname

echoplus 0 "Enter COMPUTE node name (leave blank if all named)"

read cnodeName

# get a list of all the compute nodes (cnodes)
cnodeList=()
while [[ $cnodeName != ""  ]]
do
	if [[ ! " ${cnodeList[*]} " =~ " ${cnodeName} " ]]; then # make duplicate inputs impossible
		cnodeList+=($cnodeName)
	fi
	echoplus 0 "Enter COMPUTE node name (leave blank if all named)"
	read cnodeName
done

# ---------------------- Testing Zone -------------------------
  

#--------------------------------------------------------------


# print them out to make sure we're doing things right

echoplus 0 "-----------" >> $out
echoplus 0 "Head node is: $headname" > $out
echoplus 0 "-----------" >> $out
echoplus 0 "All compute nodes are: " >> $out
for c in ${cnodeList[@]}; do
	echo $c >> $out
done
echoplus 0 "-----------" >> $out


# ---------------------- Testing Zone -------------------------
#--------------------------------------------------------------


# now we know what all the compute nodes are we can get onto testing
echoplus 2 ""
# Page 1: Node Setup
echoplus 1 "Performing tests for Node Setup."

# Test 1: ping all nodes
echoplus 2 "Test 1: Test ping all nodes"
for c in ${cnodeList[@]}; do
	ping $c -c 1  >> /dev/null 2>>$out 
	
	pingOut=$?

	if [[ $pingOut != 0 ]]
	then
		echoplus 0 "($c) ping command failed, check doc page \"Node Setup\"."
		echoplus 0 "($c) ping failed, no further testing on this node" >> $out
    remove_cnode $c
	else
    echoplus 3 "($c) ping successful" 
		echoplus 0 "($c) ping successful" >> $out
	fi
done

# Test 2: Check SELinux status on this node
echoplus 2 "Test 2: Check SELinux status on $headname" 

selinuxState=$(getenforce)

if [[ $selinuxState = Permissive ]] || [[ $selinuxState = Disabled ]]
then
	if [[ $(grep disabled /etc/selinux/config -c) < 2 ]]; then
		echoplus 0 "($headname) SELinux not disabled in config file, check doc page \"Node Setup\"."
	fi
else
	echoplus 0 "($headname) SELinux state incorrect, check doc page \"Node Setup\"."
fi
echoplus 3 "($headname) SELinux state: $selinuxState"
echoplus 0 "($headname) SELinux state: $selinuxState" >> $out

# Test 3: Check that head node ip address is the same as in /etc/hosts
echoplus 2 "Test 3: Check that $headname ip address is the same as in /etc/hosts"

headIP=$(hostname -I)

if [[ $(awk "/$headname/{ print NR; exit }" /etc/hosts) != $(awk "/$headIP/{ print NR; exit }" /etc/hosts) ]]; then
  echoplus 0 "($headname) not set to correct IP in hosts file, see documenatation page \"Node Setup\"."
  echoplus 0 "($headname) IP set incorrectly in /etc/hosts file, should be $headIP"
fi
echoplus 3 "($headname) IP in /etc/hosts is the same as node IP"

echoplus 2 ""
# Page 2: SSH Keys for root
echoplus 1 "Performing tests for SSH Keys for Root"

# Test 1: should be able to ssh into other nodes
echoplus 2 "Test 1: should be able to ssh into other nodes"

sshList=()

for c in ${cnodeList[@]}; do
	ssh $c exit 1>>/dev/null 2>>$out 
  sshOut=$?
	if [[ $sshOut != 0 ]]; then
		echoplus 0 "($c) SSH failed, check doc page \"SSH Keys for Root\" "
		echoplus 0 "($c) SSH failed with exit code ${sshOut}, no more testing on this node." >> $out
    remove_cnode $c
  else
    echoplus 3 "($c) SSH successful"
	fi

done

# Test 2: check the selinux status on every compute node we can ssh to
echoplus 2 "Test 2: Check the SELinux status on every compute node"

for c in ${cnodeList[@]}; do
  selinuxState=$(ssh $c "getenforce" exit) # doesn't work with routing the output to other places
  if [[ $selinuxState = Permissive ]] || [[ $selinuxState = Disabled ]]; then
    if [[ $(ssh $c "grep disabled /etc/selinux/config -c") < 2 ]]; then
      echoplus 0 "($c) SELinux not disabled in config file, see documentation \"Node Setup\"."
    fi
  else
    echoplus 0 "($c) SELinux is enforcing, see documentation page \"Node Setup\"."
  fi
  echoplus 3 "($c) SELinux state: $selinuxState"
  echoplus 0 "($c) SELinux state: $selinuxState" >> $out
done


# Test 3: Check that /etc/hosts file is correct on all nodes
echoplus 2 "Test 3: Check that the /etc/hosts file is consistent across nodes"

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
    echoplus 0 "($headname) In hosts file, IP error for ${allNodes[$i]}, see documenatation page \"Node Setup\"."
    echoplus 0 "($headname) In /etc/hosts, ${allNodes[$i]} IP should be ${allNodes[$i]}" >> $out
  fi
done

for c in ${cnodeList[@]}; do # now check compute nodes
  for i in ${!allNodes[@]}; do # check headnode hosts file

    nodeLine=$(ssh $c "awk '/${allNodes[$i]}/{ print NR; exit }' /etc/hosts")
    ipLine=$(ssh $c "awk '/${ipList[$i]}/{ print NR; exit }' /etc/hosts")

    if [[ $nodeLine != $ipLine ]]; then
      echoplus 0 "($c) In hosts file, IP error for ${allNodes[$i]}, see documenatation page \"Node Setup\"."
      echoplus 0 "($c) In /etc/hosts, ${allNodes[$i]} IP should be ${ipList[$i]}" >> $out
    fi
  done
done


# Page 3: Install Repositories
echoplus 2 ""
echoplus 1 "Performing tests for Install Repositories"

# Test 1: check if the epel repo is installed on the head
echoplus 2 "Test 1: Check if epel-release is installed on $headname"

packages=(epel-release)
check_installed 'Install Repositories' "$headname" "${packages[*]}"

# Test 2: (SSH) Check if the epel repo is installed on the other nodes
echoplus 2 "Test 2: Check if epel-release is installed on compute nodes"

for c in ${cnodeList[@]};do
  check_installed 'Install Repositories' "$c" "${packages[*]}"
done
unset packages


echoplus 2 ""
# Page 4: Setup NFS Server
echoplus 1 "Performing tests for Setup NFS Server"
# this is just for the head node
# should i check to make sure nfs-utils is installed? probably

# Test 1: make sure nfs-utils is installed

echoplus 2 "Test 1: Check if nfs-utils is installed"

packages=(nfs-utils)
check_installed 'Setup NFS Server' "$headname" "${packages[*]}"


# Test 2: check for necessary directories on the head node
echoplus 2 "Test 2: Check existence of directories for nfs"

# /opt/{apps,data,service,site} and /export/{apps,data,service,site}

primeDirs=(opt export)
subDirs=(apps data service site)

for p in ${primeDirs[@]}; do
  for s in ${subDirs[@]}; do
    if [[ ! -d "/$p/$s/" ]]; then
      echoplus 0 "($headname) Directory \""/$p/$s/"\" does not exist, see documentation page \"Setup NFS Server\""
      echoplus 0 "($headname) Directory \""/$p/$s/"\" does not exist." >> $out
    elif [[ $p = export ]]; then
      perm=$(stat -c %a /$p/$s)
      if [[ ! $perm = 775 ]];then # Test 2: Check that /export/ has the permissions 775
        echoplus 0 "($headname) Directory \""/$p/$s/"\" has incorrect permissions, see documentation page \"Setup NFS Server\""
        echoplus 0 "($headname) Directory \""/$p/$s/"\" has permissions $perm - should be 775" >> $out
      else
        echoplus 3 "($headname) Directory /$p/$s/ has correct permissions."
      fi
    else
      echoplus 3 "($headname) Directory /$p/$s/ exists."
    fi
  done
done
unset primeDirs

#Test 3: /etc/exports contains the correct information
# idea: go through every line until all the content has been found?
#Test 4: /etc/fstab contains the correct information

#Test 3: systemctl status nfs-server.service is active with no errors
echoplus 2 "Test 3: Check status of nfs-server.service"

systemctl status nfs-server.service 1>>/dev/null 2>>$out; result=$?
if [[ $result != 0 ]]; then
  echoplus 0 "($headname) nfs-server.service error, see documentation page \"Setup NFS Server\""
  echoplus 0 "($headname) nfs-server.service error, system status exit code $result" >> $out
else
  echoplus 3 "($headname) nfs-server.service running as expected"
fi

# Test 4: the correct stuff has been exported showmount --exports
# Test 4: check if $(showmount --exports --no-header) is the same output as $(showmount -e chead1 --no-header)
echoplus 2 "Test 4: Confirm nfs exports"

headExport=$(showmount --exports --no-header)

for c in ${cnodeList[@]};do
  nodeExport=$(ssh $c "showmount -e $headname --no-header")
  if [[ $headExport != $nodeExport ]]; then
    echoplus 0 "($headname/$c) Mismatched mount points, see documentation pages: \"Setup NFS Server\" and \"Setup NFS Clients\""
    echoplus 0 "($headname/$c) Mismatched mount points: " >> $out
    echoplus 0 "$headname export:" >> $out
    echoplus 0 "$headExport" >> $out
    echoplus 0 "$c export:" >> $out
    echoplus 0 "$nodeExport" >> $out
  else
    echoplus 3 "($headname/$c) Mount points appear to be correct"
  fi
done

# Test 7: check that all compute nodes are mounted
echoplus 2 "Test 5: Check that compute nodes are mounted"


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
    echoplus 0 "($c) Node is not detectably mounted, see documentation pages: \"Setup NFS Server\" and \"Setup NFS Clients\""
    echoplus 0 "($c) NFS issue, node is not detectably mounted." >> $out
  fi
done

echoplus 2 ""
# Page 5: Setup NFS Clients
echoplus 1 "Performing tests for Setup NFS Clients"

echoplus 2 "Test 1: Check nfs installation"

for c in ${cnodeList[@]};do
  check_installed 'Setup NFS Clients' "$c" "${packages[*]}"
done
unset packages

# Test 1: check that /opt/ exists
echoplus 2 "Test 2: Check existence of /opt"

subDirs=(apps data service site)

for c in ${cnodeList[@]}; do
  for s in ${subDirs[@]}; do
    outDir=$(ssh $c '[ -d /opt/'"$s"'/ ] ; echo $?')
       
    if [[ $outDir != 0 ]]; then
      echoplus 0 "($c) Directory \""/opt/$s/"\" does not exist, see documentation page \"Setup NFS Clients\""
      echoplus 0 "($c) Directory \""/opt/$s/"\" does not exist." >> $out
    else
      echoplus 3 "($c) Directory \""/opt/$s/"\" exists."
    fi
  done
done
unset outDir

# Test 2: check that $(df -t nfs) shows what we're expecting
echoplus 2 "Test 3: Confirm mount points"

for c in ${cnodeList[@]};do
  unset result

  result=($(ssh $c 'df -t nfs' 2>>$out))

  if [[ ${#result[@]} -eq 0 ]]; then
    echoplus 0 "($c) No directories mounted, see documentation page \"Setup NFS Clients\""
    echoplus 0 "($c) No directories mounted. " >> $out
    break
  fi

  remotes=()
  locals=()
  for r in ${result[@]};do
    if [[ $r == *'/'* ]]; then
      if [[ $r == *"$headname"* ]];then
        cut="$(echo "$r" | sed 's/'"$headname"'://g')"
        remotes+=("$(echo "$cut" | sed 's/\/export//g')")
      else
        locals+=("$(echo "$r" | sed 's/opt\///g')")
      fi
    fi
  done
  unset cut

  if [[ $remotes != $locals ]];then
    echoplus 0 "($c) Directories not mounted properly, see documentation page \"Setup NFS Clients\""
    echoplus 0 "($c) Directories not mounted properly. Remote: $remotes || $ Local: $locals" >> $out
  else
    echoplus 3 "($c) Directories appear to be mounted."
  fi

done

echoplus 2 ""
# Page 6: Install Flight
echoplus 1 "Performing tests for Install Flight"

# Test 1: check if the repos are enabled
echoplus 2 "Test 1: Check if repositories are enabled"

repos=(openflight powertools)

repolist=$(dnf repolist)
for r in ${repos[@]};do
  echo $repolist | grep $r 1>>/dev/null 2>>$out ; result=$?
  if [[ $result != 0 ]]; then
    echoplus 0 "($headname) repository $r not found, see documentation page \"Install Flight\""
    echoplus 0 "($headname) repository $r not found" >> $out
    exit 1
  else
    echoplus 3 "($headname) reposity $r is enabled."
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
      echoplus 0 "($c) repository $r not found, see documentation page \"Install Flight\""
      echoplus 0 "($c) repository $r not found" >> $out
      remove_cnode $c
    else
      echoplus 3 "($c) reposity $r is enabled"
    fi
  done
done
unset result
unset repolist

# Test 2: make sure packages are installed
echoplus 2 "Test 2: Check that necessary packages are installed"

unset packages
packages=(flight-user-suite flight-plugin-system-systemd-service)

check_installed 'Install Flight' "$headname" "${packages[*]}"
for c in ${cnodeList[@]};do
  check_installed 'Install Flight' "$c" "${packages[*]}"
done
unset packages


# Test 3: make sure flight-service is started
echoplus 2 "Test 3: Check if flight-service has started"

systemctl status flight-service 1>>/dev/null 2>>$out; result=$?

if [[ $result != 0 ]];then
  echoplus 0 "($headname) flight-service error, see documentation page \"Install Flight\""
  echoplus 0 "($headname) flight-service error, system status exit code $result" >>$out
  exit 1
else
  echoplus 3 "($headname) flight-service functions without errors."
fi

# now compute nodes

for c in ${cnodeList[@]};do
  ssh $c "systemctl status flight-service"  1>> /dev/null 2>>$out; result=$?
  if [[ $result != 0 ]];then
    echoplus 0 "($c) flight-service error, see documentation page \"Install Flight\""
    echoplus 0 "($c) flight-service error, system status exit code $result" >>$out
    remove_cnode $c
  else
    echoplus 3 "($c) flight-service functions without errors"
  fi
done

# Test 4: make sure flight has been started (exit/drop node if not)
echoplus 2 "Test 4: Check if Flight has been started"
flight 1>>/dev/null 2>>$out; result=$?
if [[ $result = 127 ]];then
  echoplus 0 "($headname) flight path not set, see documentation page \"Install Flight\""
  echoplus 0 "($headname) flight path not set, system status exit code $result" >>$out
  exit 1
else
  flight | grep -q  "not currently active" 2>>$out; result=$?
  if [[ $result = 0 ]];then
    echoplus 0 "($headname) flight not started, see documentation page \"Install Flight\""
    echoplus 0 "($headname) flight not started" >>$out
    exit 1
  elif [[ $result = 1 ]]; then
    echoplus 3 "($headname) Flight running without errors"
    echoplus 0 "($headname) Flight running successfully" >>$out
  fi
fi

# now compute nodes

for c in ${cnodeList[@]};do
  ssh $c "flight" 1>>/dev/null 2>>$out; result=$?
  #echoplus 0 "($c) flight exit code is: $result"
  if [[ $result = 127 ]];then
    echoplus 0 "($c) flight path not set, see documentation page \"Install Flight\""
    echoplus 0 "($c) flight path not set, system status exit code $result" >>$out
    remove_cnode $c
  else
    
    ssh $c 'flight | grep -q "not currently active"' ; result=$?

    if [[ $result = 0 ]];then
      echoplus 0 "($c) flight not started or not set to always on, see documentation page \"Install Flight\""
      echoplus 0 "($c) flight not started or not set to always on" >>$out
      remove_cnode $c
    elif [[ $result = 1 ]];then
      echoplus 3 "($c) Flight running without errors"
      echoplus 0 "($c) Flight running successfully" >>$out
    fi
  fi
done



# Test 5: make sure that the cluster has the correct name
echoplus 2 "Test 5: check that cluster has the correct name"
clustername=$(flight config get cluster.name)

if [[ $name = "your cluster" ]];then
  echoplus 0 "($headname) cluster name not set, see documentation page \"Install Flight\""
  echoplus 0 "($headname) cluster name not set" >>$out
else
  echoplus 3 "($headname) cluster name has been set"
fi

for c in ${cnodeList[@]};do
  clustername=$(ssh $c 'flight config get cluster.name')
  if [[ $clustername = "your cluster" ]];then
    echoplus 0 "($c) cluster name not set, see documentation page \"Install Flight\""
    echoplus 0 "($c) cluster name not set" >>$out
  else
    echoplus 3 "($c) cluster name has been set"
  fi
done
# check that clustername is consistent across nodes

echoplus 2 ""
# Page 7: Install Flight Web Suite
echoplus 1 "Performing tests for Install Flight Web Suite"

# head only

# Test 1: is flight web suite installed?
echoplus 2 "Test 1: Check if Flight Web Suite has been installed"

unset packages
packages=(flight-web-suite)
check_installed 'Install Flight Web Suite' "$headname" "${packages[*]}" 
unset packages

# Test 2: check that the domain is correct
echoplus 2 "Test 2: Check that the domain is correct"

domain=$(flight web-suite get-domain)
echoplus 0 "($headname) the domain name for web-suite is $domain, if this is incorrect see documentation page \"Install Flight Web Suite\""
echoplus 0 "($headname) web-suite domain name is $domain" >> $out
unset domain

# Test 3: check that services have been started
echoplus 2 "Test 3: check that flight services have been started"

services=(console-api desktop-restapi file-manager-api job-script-api login-api www)
list=$(flight service list)

for s in ${services[@]};do
  echo $list | grep -q $s; result=$?
  if [[ $result != 0 ]]; then
    echoplus 0 "($headname) Flight Web-Suite service $s not started, see documentation page \"Install Flight Web Suite\""
    echoplus 0 "($headname) Flight Web-Suite service $s not started." >>$out
  else
    echoplus 3 "($headname) Flight Web-Suite service $s is started"
  fi
done
unset list

# Test 4: check that the web suite is enabled
echoplus 2 "Test 4: Check that Flight Web-Suite is enabled"

list=$(flight service stack status)

for s in ${services[@]};do
  echo $list | grep -q $s; result=$?
  if [[ $result != 0 ]]; then
    echoplus 0 "($headname) Flight Web-Suite service $s not enabled, see documentation page \"Install Flight Web Suite\""
    echoplus 0 "($headname) Flight Web-Suite service $s not enabled." >>$out
  else
    echoplus 3 "($headname) FLight Web-Suite service $s is enabled."
  fi
done
unset list

unset services

echoplus 2 ""
# Page 8: Setup SLURM Server
echoplus 1 "Performing tests for Setup SLURM Server"

# Test 1: check that everything is installed
echoplus 2 "Test 1: Check that necessary packages are installed"

unset packages
packages=(munge munge-libs perl-Switch numactl flight-slurm flight-slurm-slurmctld flight-slurm-devel flight-slurm-perlapi flight-slurm-torque flight-slurm-slurmd flight-slurm-example-configs flight-slurm-libpmi)
check_installed 'Setup SLURM Server' "$headname" "${packages[*]}"
unset packages

# Test 2: check that the correct information is in the slurm conf file at /opt/flight/opt/slurm/etc/slurm.conf
echoplus 2 "Test 2: Check validity of slurm.conf file"

# going to put in a check that this info is the same on head node as on all compute nodes, but also not empty

headSlurmConf=0
slurmConfFile='/opt/flight/opt/slurm/etc/slurm.conf'
if [[ ! -f $slurmConfFile ]]; then
  echoplus 0 "($headname) slurm conf file does not exist, see documentation page \"Setup SLURM Server\""
  echoplus 0 "($headname) $slurmConfFile does not exist" >>$out
else # if it does exist, then is it empty?
  if [[ ! -s $slurmConfFile ]]; then
    echoplus 0 "($headname) slurm configuration not set, see documentation page \"Setup SLURM Server\""
    echoplus 0 "($headname) slurm configuration not set." >> $out
  else
    headSlurmConf=$(cat $slurmConfFile)
  fi
fi

# Test 3: make sure directories /opt/flight/opt/slurm/var/{log,run,spool/slurm.state} exist
echoplus 2 "Test 3: Check existence of slurm necessary directories"
# Test 4: make sure owner of the directores  chown -R nobody: /opt/flight/opt/slurm/var/{log,run,spool}
echoplus 2 "Test 4: Check ownership of slurm necessary directories"

primeDir='/opt/flight/opt/slurm/var/'

subDirs=(log run spool 'spool/slurm.state')

for s in ${subDirs[@]};do
  if [[ ! -d "$primeDir""$s" ]];then # Test 3 - does the "-d" need to be a "-f" ?
    echoplus 0 "($headname) Directory/File \""$primeDir""$s"\" does not exist, see documentation page \"Setup SLURM Server\""
    echoplus 0 "($headname) Directory/File \""$primeDir""$s"\" does not exist." >> $out
  else # Test 4
    user=$(stat -c '%U' "$primeDir""$s") 
    if [[ ! $user = nobody ]];then
      echoplus 0 "($headname) Directory/File \""$primeDir""$s"\" is owned by the wrong user, see documentation page \"Setup SLURM Server\""
      echoplus 0 "($headname) Directory/File \""$primeDir""$s"\" is owned by \"$user\", should be owned by \"nobody\"" >> $out
    else
      echoplus 3 "($headname) Directory/File \""$primeDir""$s"\" appears to be set up correctly"
    fi
  fi
done
unset user

# Test 5: make sure munge key is in munge file /etc/munge/munge.key
echoplus 2 "Test 5: Confirm munge key"
# can't know what the munge key is, but can check that munge.key exists, that it is not empty and then later that it is the same as on compute nodes
headMunge=0
mungeFile='/etc/munge/munge.key'
if [[ ! -f $mungeFile ]]; then
  echoplus 0 "($headname) munge key does not exist, see documentation page \"Setup SLURM Server\""
  echoplus 0 "($headname) munge.key does not exist" >>$out
else # if it does exist, then is it empty?
  if [[ ! -s $mungeFile ]]; then
    echoplus 0 "($headname) munge key not set, see documentation page \"Setup SLURM Server\""
    echoplus 0 "($headname) munge key not set." >> $out
  else
    headMunge=$(cat $mungeFile)
  fi
  # test 6: make sure owner of munge key is correct
  user=$(stat -c '%U' $mungeFile) 
  if [[ ! $user = "munge" ]]; then
    echoplus 0 "($headname) munge.key is owned by the wrong user, see documentation page \"Setup SLURM Server\""
    echoplus 0 "($headname) munge.key is owned by \"$user\", should be owned by \"munge\"" >>$out
  else
    echoplus 3 "($headname) munge.key ownership is correct"
  fi
  # Test 7: make sure permission are correct on munge key chmod 400 /etc/munge/munge.key
  perm=$(stat -c %a $mungeFile)
  if [[ ! $perm = 400 ]];then
     echoplus 0 "($headname) munge.key permissions are incorrect, see documentation page \"Setup SLURM Server\""
     echoplus 0 "($headname) munge.key permissions are \"$perm\", should be \"400\"">>$out
  else
    echoplus 3 "($headname) munge.key permissions are correct"
  fi
fi


# Test 8: make sure munge is active and enabled
echoplus 2 "Test 6: Check activity and enability of munge and flight-slurmctld services"
# Test 9: make sure flight-slurmctld is active and enabled

services=(munge flight-slurmctld)

for s in ${services[@]}; do
  systemctl status $s 1>>/dev/null 2>>$out; result=$?
  if [[ $result != 0 ]];then
    echoplus 0 "($headname) $s not started, see documentation page \"Setup SLURM Server\""
    echoplus 0 "($headname) $s not started, system status exit code $result" >>$out
    exitme=true
  fi
  if [[ $(systemctl is-enabled $s) != "enabled" ]]; then
    echoplus 0 "($headname) $s is not enabled, see documentation page \"Setup SLURM Server\""
    echoplus 0 "($headname) $s is not enabled." >> $out
    exitme=true
  fi
done

if [[ $exitme = false ]];then
  delayedExit=true
else
  echoplus 3 "($headname) SLURM and munge services started and enabled"
  delayedExit=false
fi

echoplus 2 ""
#Page 9: Setup SLURM Clients
echoplus 1 "Performing tests for Setup SLURM Clients"
# Test 1 make sure the correct things are installed on compute nodes
echoplus 2 "Test 1: Check installation of necessary packages"
unset packages
packages=(munge munge-libs perl-Switch numactl flight-slurm flight-slurm-devel flight-slurm-perlapi flight-slurm-torque flight-slurm-slurmd flight-slurm-example-configs flight-slurm-libpmi)
for c in ${cnodeList[@]};do
  check_installed 'Setup SLURM Clients' "$c" "${packages[*]}"
done
unset packages

# Test 2: make sure slurm conf file on compute nodes is the same as on head node
echoplus 2 "Test 2: Check validity of slurm.conf file"
for c in ${cnodeList[@]}; do 
  # slurmConfFile is unchanged
  if [[ $(ssh $c '[ -f '"$slurmConfFile"' ] ; echo $?') != 0 ]]; then
    echoplus 0 "($c) slurm conf file does not exist, see documentation page \"Setup SLURM Clients\""
    echoplus 0 "($c) $slurmConfFile does not exist" >>$out
  else # if it does exist, then is it empty?
    if [[ $(ssh $c '[ -s '"$slurmConfFile"' ] ; echo $?') != 0 ]]; then
      echoplus 0 "($c) slurm configuration not set, see documentation page \"Setup SLURM Clients\""
      echoplus 0 "($c) slurm configuration not set." >> $out
    else
      cnodeSlurmConf=$(ssh $c "cat $slurmConfFile" 2>>$out) 
      if [[ "$cnodeSlurmConf" != "$headSlurmConf" ]];then
        echoplus 0 "($c/$headname) slurm configuration is not consistent between nodes, see documentation pages \"Setup SLURM Server\" and \"Setup SLURM Clients\""
        echoplus 0 "($c/$headname) slurm configuration is not consistent between nodes" >>$out
      else
        echoplus 3 "($c/$headname) SLURM configuration is consistent between nodes."
      fi
    fi
  fi
done

# Test 3: check  /opt/flight/opt/slurm/var/{log,run,spool} exist
echoplus 2 "Test 3: Check existence of SLURM necessary directories"
# Test 4: check owner of directories: /opt/flight/opt/slurm/var/{log,run,spool}
echoplus 2 "Test 4: check ownership of SLURM necessary directories"

echoplus 2 "Test 5: Check validity of munge key"

for c in ${cnodeList[@]}; do
  exitme=false
  primeDir='/opt/flight/opt/slurm/var/'

  subDirs=(log run spool)
  for s in ${subDirs[@]};do
    if [[ $(ssh $c '[ -d '"$primeDir""$s"' ] ; echo $?') != 0 ]]; then # Test 3
      echoplus 0 "($c) Directory/File \""$primeDir""$s"\" does not exist, see documentation page \"Setup SLURM Server\""
      echoplus 0 "($c) Directory/File \""$primeDir""$s"\" does not exist." >> $out
      exitme=true
    else # Test 4
      user=$(ssh $c 'stat -c ''%U '"$primeDir""$s" 2>>$out)
      if [[ ! $user = nobody ]];then
        echoplus 0 "($c) Directory/File \""$primeDir""$s"\" is owned by the wrong user, see documentation page \"Setup SLURM Server\""
        echoplus 0 "($c) Directory/File \""$primeDir""$s"\" is owned by \"$user\", should be owned by \"nobody\"" >> $out
        exitme=true
      else
        echoplus 3 "($c) Directory/File \""$primeDir""$s"\" has correct ownership."
      fi
    fi
  done
  unset user

  # Test 5: make sure the munge key is the same on this node as it is on the head node
  # headMunge contains the head munge key
  # mungeFile contains the file location of the munge key
  if [[ $(ssh $c '[ -f '"$mungeFile"' ] ; echo $?') != 0 ]]; then
    echoplus 0 "($c) munge key does not exist, see documentation page \"Setup SLURM Clients\""
    echoplus 0 "($c) munge.key does not exist" >>$out
    exitme=true
  else # if it does exist, then is it empty?
    if [[ $(ssh $c '[ -s '"$mungeFile"' ] ; echo $?') != 0 ]]; then
      echoplus 0 "($c) munge key not set, see documentation page \"Setup SLURM Clients\""
      echoplus 0 "($c) munge key not set." >> $out
      exitme=true
    else
      cnodeMunge=$(ssh $c 'cat '"$mungeFile")
    fi
    # test 6: make sure owner of munge key is correct
    user=$(ssh $c 'stat -c ''%U'" $mungeFile" 2>>$out)
    if [[ ! $user = "munge" ]]; then
      echoplus 0 "($c) munge.key is owned by the wrong user, see documentation page \"Setup SLURM Clients\""
      echoplus 0 "($c) munge.key is owned by \"$user\", should be owned by \"munge\"" >>$out
      exitme=true
    else
      echoplus 3 "($c) munge.key has correct ownership"
    fi
    # Test 7: make sure permission are correct on munge key chmod 400 /etc/munge/munge.key
    perm=$(ssh $c 'stat -c ''%a'" $mungeFile")
    if [[ ! $perm = 400 ]];then
       echoplus 0 "($c) munge.key permissions are incorrect, see documentation page \"Setup SLURM Clients\""
       echoplus 0 "($c) munge.key permissions are \"$perm\", should be \"400\"">>$out
       exitme=true
    fi
    if [[ "$headMunge" != "$cnodeMunge" ]];then
      echoplus 0 "($c/$headname) munge key is not consistent between nodes, see documentation pages \"Setup SLURM Server\" and \"Setup SLURM Clients\""
      echoplus 0 "($c/$headname) munge key is not consistent between nodes" >>$out
      exitme=true
    else
      echoplus 3 "($c/$headname) munge key is consistent between nodes"
    fi
  fi

  if [[ "$exitme" = true ]];then
    remove_cnode $c
    continue
  fi

  # Test 8: make sure than slurm is enabled
  
  # Test 9 make sure than slurm is started

  services=(munge flight-slurmd)

  for s in ${services[@]}; do
    ssh $c 'systemctl status '"$s" 1>>/dev/null 2>>$out; result=$?
    if [[ $result != 0 ]];then
      echoplus 0 "($c) $s not started, see documentation page \"Setup SLURM Clients\""
      echoplus 0 "($c) $s not started, system status exit code $result" >>$out
      exitme=true
    fi
    if [[ $(ssh $c 'systemctl is-enabled '"$s") != "enabled" ]]; then
      echoplus 0 "($c) $s is not enabled, see documentation page \"Setup SLURM Clients\""
      echoplus 0 "($c) $s is not enabled." >> $out
      exitme=true
    fi
  done

   if [[ "$exitme" = true ]];then
    echoplus 0 "($c) [EXIT] No further testing possible on this node."
    echoplus 0 "($c) [EXIT]" >>$out
    remove_cnode $c
    continue
  else
    echoplus 3 "($c) munge and flight-slurmd started and enabled."
  fi

done


echoplus 2 ""
# Page 10: Create Shared User
echoplus 1 "Performing tests for Create Shared User"

# Test 1: check if the user exists
echoplus 2 "Test 2: Check if user exists"
# Test 2: check if  the user has a password
echoplus 2 "Test 2: Check if user has a password set"
sharedUser="flight"
if id $sharedUser 1>>/dev/null 2>>$out; then
  passwdStatus=$(passwd --status "$sharedUser" | awk '{print $2}')
  if [[ "$passwdStatus" != "PS" ]];then
    echoplus 0 "($headname) shared user \"$sharedUser\" does not have a password on this node, see documentation page \"Create Shared User\""
    echoplus 0 "($headname) shared user \"$sharedUser\" does not have a password on this node, passwd state $passwdStatus" >>$out
  else
    echoplus 3 "($headname) shared user \"$sharedUser\" is setup as expected."
  fi
else
  echoplus 0 "($headname) shared user \"$sharedUser\" does not exist on this node, see documentation page \"Create Shared User\""
  echoplus 0 "($headname) shared user \"$sharedUser\" does not exist on this node." >>$out
fi

for c in ${cnodeList[@]};do
  if ssh $c "id $sharedUser" 1>>/dev/null 2>>$out; then
    passwdStatus=$(ssh $c 'passwd --status '"$sharedUser"' | awk '\''{print $2}'\')
    if [[ "$passwdStatus" != "PS" ]];then
      echoplus 0 "($c) shared user \"$sharedUser\" does not have a password on this node, see documentation page \"Create Shared User\""
      echoplus 0 "($c) shared user \"$sharedUser\" does not have a password on this node, passwd state $passwdStatus" >>$out
    else
      echoplus 3 "($c) shared user \"$sharedUser\" is setup as expected."
    fi
  else
    echoplus 0 "($c) shared user \"$sharedUser\" does not exist on this node, see documentation page \"Create Shared User\""
    echoplus 0 "($c) shared user \"$sharedUser\" does not exist on this node." >>$out
  fi
done



echoplus 2 ""
# Page 11: Install Genders and PDSH
echoplus 1 "Performing tests for Install Genders and PDSH"
# only on head node

# Test 1: check that its installed
echoplus 2 "Test 1: Check flight-pdsh installation"
unset packages
packages=(flight-pdsh)

check_installed 'Install Genders and PDSH' "$headname" "${packages[*]}"
unset packages
