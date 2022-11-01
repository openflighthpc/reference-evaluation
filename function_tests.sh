#! /bin/bash -l


# verbosity
# 0 is errors only, not output otherwise
# 2 is quiet - errors and group headings
outputlvl=3 # is default level- also adds individual tests to output
# 4 is verbose, all the previous output and also warning and success messages


#output
out=test-functionality.out

#CONSTANTS
RED='\033[0;31m'
GRN='\033[0;32m'
ORNG='\033[0;33m'
NC='\033[0m' # No Color


# take input

while [[ $# -gt 0 ]]; do # while there are not 0 args
  case $1 in
    -e|--example)
      EXAMPLE="$2"
      shift # past argument
      shift # past value
      ;;
    -v|--verbose)
      outputlvl=4
      shift # past argument
      ;;
    -c|--chatty)
      outputlvl=3
      shift # past argument
      ;;
    -q|--quiet)
      outputlvl=1
      shift # past argument
      ;;
    -s|--silent)
      outputlvl=0
      shift # past argument
      ;;
    -*|--*)
      echo -e "${RED}Unknown option $1 ${NC}"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done


#-----------Function Zone--------

echoplus() { # adds options to echo like verbose etc
  local verbosity=$1
  shift
  local text=("$@")
  if [[ "$verbosity" -le "$outputlvl" ]];then
    echo -e "${text[*]}"
  fi
}

echoplusc() {
  local verbosity=$1
  local colour=$2
  shift;shift
  local text=("$@")
  if [[ "$verbosity" -le "$outputlvl" ]];then
    echo -e "${!colour}""${text[*]}""${NC}"
  fi
}

echoplusultra(){
  text=()
  verbosity="$outputlvl"
  colour="NC"
  print=false
  while [[ $# -gt 0 ]]; do # while there are not 0 args
    case $1 in
      -v|--verbosity)
        verbosity="$2"
        shift # past argument
        shift # past value
        ;;
      -c|--colour)
        colour="$2"
        shift # past argument
        shift # past value
        ;;
      -p|--print)
        print=true
        shift # past argument
        ;;
      -*|--*)
        echo -e "${RED}Unknown option $1 ${NC}"
        exit 1
        ;;
      *)
        text+=("$1") # save positional arg
        shift # past argument
        ;;
    esac
  done
  if [[ "$verbosity" -le "$outputlvl" ]];then
    if [[ "$colour" = "NC" ]];then
      if [[ $print = true ]];then printf "${text[*]}"; else echo "${text[*]}"; fi
    else
      if [[ $print = true ]];then printf "${!colour}""${text[*]}""${NC}"; else echo -e "${!colour}""${text[*]}""${NC}"; fi
    fi
  fi
}

#------------END--------------


# SLURM

# warning output files may be named something else, should put a specific output type to file

echoplusultra -v 2 "Checking functionality of SLURM"  # Page 1: SLURM

echoplusultra -v 3 "Test 1: Run interactive job"      # Test 1: interactive job

timeout 30 srun uptime 1>>/dev/null ; result=$?

if [[ $result != 0 ]]; then
  echoplusc 0 RED "[ERROR] Cannot run interactive job"

else
  echoplusc 4 GRN "Successfully ran interactive job."
fi


echoplusultra -v 3 "Test 2: Run batch job"
batchfile=auto-job-test.sh

touch $batchfile
echo '#!/bin/bash -l
echo "start"
sleep 1
echo "finish"'>$batchfile
jobid=$(sbatch --parsable $batchfile);result=$?

if [[ $result != 0 ]];then
  echoplusc 0 RED "[ERROR] Cannot start a batch job."
  echoplusultra -v 3 "Test 3: Cannot run Test 3"
else
  echoplusc 4 GRN "Successfully started running a batch job"
  echoplusultra -v 3 "Test 3: Check that job is in queue" # Test 3
  squeue | grep $jobid 1>>/dev/null; result=$?
  if [[ $result != 0 ]];then
    echoplusc 0 RED "[ERROR] Previously started batch job not in queue"
    echoplusultra -v 3 "Test 4: cannot run Test 4"
  else
    echoplusc 4 GRN "Successfully queued previously started batch job"
    sleep 2
    echoplusultra -v 3 "Test 4: Check that job completes successfully"  #Test 4

    timer=10
    echoplusultra -v 3 -p "Waiting for evidence of success. Time remaining: $timer\r"
    slurm=false
    for ((i=1; i<=$timer; i++)); do
      if  ! squeue | grep $jobid 1>>/dev/null && cat "slurm-$jobid.out" | grep "finish" 1>>/dev/null; then # if job is not in the queue AND finish has been written to the output file
        echoplusultra -p "\\n"
        echoplusultra -v 4 -c GRN "Job ran and finished successfully"
        slurm=true
        break
      else
        sleep 1
        ((timer=timer-1))
        echoplusultra -v 3 -p "Waiting for evidence of success. Time remaining:  $timer\r"
      fi
    done

    if [[ $slurm = false ]];then
      echoplusultra -p "\\n"
      echoplusultra -v 0 -c RED "[ERROR] Job failed to complete"
    fi
  fi
fi

# delete files used
rm -f "$batchfile"
rm -f "slurm-$jobid.out"
unset batchfile
unset jobid


# Page 2: Desktop tests
echoplusultra -v 3 ""
echoplusultra -v 2 "Checking functionality of desktop"

echoplusultra -v 3 "Test 1: Check availability"

desktop=false

if ! flight desktop avail 1>>/dev/null;then # if the command doesn't run
  echoplusc 0 RED "[ERROR] Could not check desktop availability"
else
  prepped=$(flight desktop avail | grep "Verified" );result=$?
  possibles=(gnome kde xfce)
  tostart=()
  if [[ $result = 0 ]];then # at least one desktop is verified
      for p in ${possibles[@]};do
        if echo "$prepped" | grep $p 1>>/dev/null ; then # if a possible desktop is verified
          desktop=true
          tostart+="$p"
          echoplusc 4 GRN "Successfully checked available desktops, and found Verified"
        fi
      done
  else # none are verified
    echoplusc 0 ORNG "[WARNING] No desktops are prepared, cannot test desktop."
  fi
fi

if [[ $desktop = false ]];then
  echoplusultra -v 3 "Test 2: Cannot test, missing prerequisites."
  
else
  echoplusultra -v 3 "Test 2: Start a desktop, run a script on it, then kill it"  
fi
for t in ${tostart[@]};do
  echoplusultra -v 3 "Attempting to start: $t"
  # handy flight commands let me test it all
  desktopScript="$(pwd)"'/desktopTestScript.sh'
  desktopOut="$(pwd)"'/desktopTestScript.out'

  # create a test script to run on the desktop
  touch "$desktopScript"
  echo '#!/bin/bash
echo "test" >>'"$desktopOut ">"$desktopScript"
  chmod 777 "$desktopScript"

  # start flight desktop
  flight desktop start $t --script "$desktopScript" --kill-on-script-exit 1>>/dev/null; result=$?
  
  if [[ $result != 0 ]];then # it could theoretically fail to start
    echoplusc 0 RED "Desktop $t failed to start"
    desktop = false
    continue
  fi

  # now if the desktop started, and the script ran properly, there should be an output file
  timer=30
  echoplusultra -v 3 -p "Waiting for evidence of success. Time remaining: $timer\r"
  desktop=false
  while [[ $timer > 0 ]]; do
    if [[ -f "$desktopOut" ]];then
      desktop=true
      echoplusultra -p "\\n"
      echoplusc 4 GRN "Desktop $t successfully started, run and killed."
      break
    else
      sleep 1
      ((timer=timer-1))
      echoplusultra -v 3 -p "Waiting for evidence of success. Time remaining:  $timer\r"
    fi
  done

  if [[ $desktop = false ]];then
    echoplusultra -p "\\n"
    if [[ $timer = 0 ]];then
      echoplusc 0 RED "[ERROR] Desktop $t failed to run in time"
    else
      echoplusultra -v 0 -c RED "[ERROR] Desktop $t failed to run."
    fi
  fi

  rm -f "$desktopScript"
  rm -f "$desktopOut"
done




# Page 3: Environment

echoplusultra -v 3 ""
echoplusultra -v 2 "Check functionality of Environment"

echoplusultra -v 3 "Test 1: Check availability"

if flight env avail 1>>/dev/null; then # the command works
  echoplusc 4 GRN "Successfully checked available environments"
else
  echoplusc 0 RED "[ERROR] Cannot check available environments"
fi

echoplusultra -v 3 "Test 2: Create environment"
echoplusultra -v 3 -c ORNG "this may take some time . . ."

environments=(conda easybuild modules singularity spack)
env=false
for e in ${environments[@]};do
  output=$(timeout 0 /opt/flight/bin/flight env create "$e" 2>&1);
  if  echo "$output" | grep -q "has been created" ;then # it got created
    echoplusultra -v 4 -c GRN "Successfully created $e environment"
    env=$e
    break
  elif echo "$output" | grep -q "already exists"; then # it already exists
    echoplusultra -v 4 -c ORNG "$e environment already exists, testing an alternative"
  else
    echoplusultra -v 0 -c RED "[ERROR] Failed to create $e environment, testing an alternative"
  fi
done

if [[ $env = false ]];then
  echoplusultra -v 0 -c RED "Could not test creation of environment, cannot perform further environment tests."
else
  echoplusultra -v 3 "Test 3: Activate environment"
  # we successfully created an environment, now to try activate it maybe? then deactivate and purge
  if flight env activate $env ; then
    echoplusultra -v 4 -c GRN "Successfully activated $env environment"
    echoplusultra -v 3 "Test 4: Deactivate environment"
    if flight env deactivate ; then
      echoplusultra -v 4 -c GRN "Successfully deactivated $env environment"
      echoplusultra -v 3 "Test 5: Purge Environment"
      if flight env purge --yes $env 1>>/dev/null 2>>$out;then
        echoplusultra -v 4 -c GRN "Successfully purged $env environment"
      else
        echoplusultra -v 0 -c RED "[ERROR] Cannot purge $env environment."
      fi
    else
      echoplusultra -v 0 -c RED "[ERROR] Cannot deactivate $env environment, cannot perform further environment tests."
    fi
  else
    echoplusultra -v 0 -c RED "[ERROR] Could not activate $env environment, cannot perform further environment tests."
  fi
fi


# Page 3: genders and pdsh

echoplusultra -v 3 ""
echoplusultra -v 2 "Check functionality of Genders and PDSH"
echoplusultra -v 3 "Test 1: Confirm consistency"
node=($(nodeattr --expand))
genders=($(nodeattr -l $node))

gendertest=true
for g in ${genders[@]}; do # do the genders contain the node?
  if ! nodeattr -s $g | grep $node 1>>/dev/null ;then
    gendertest=false
  fi
done

if [[ $gendertest = true ]];then
  echoplusultra -v 4 -c GRN "Successfully checked genders functionality."
else
  echoplusultra -v 0 -c RED "[ERROR] genders/pdsh is inconsistent."
fi


