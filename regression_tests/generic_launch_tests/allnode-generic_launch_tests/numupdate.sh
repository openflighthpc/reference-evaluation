#!/bin/bash -l
action=0
if [[ $1 == "+" || $1 == "-" ]]; then # only accept these actions
  action=$1
  shift
else
  echo -e '\033[0;31mCorrect usage is: `bash scriptname.sh +/- <filename1> <filename2> . . . `  \033[0m'
  exit 1
fi

while [[ $# -gt 0 ]]; do # while there are not 0 args
  number=${1%%_*} # remove from first _ to end
  let "number=number${action}1" # (in/de)crement by 1
  name=${1#*_} # remove up to first _
  mv "$1" "${number}_${name}"
  echo "$1 -> ${number}_${name}"
  shift
done

# simple script to increment or decrement file numbers where a file follows the naming scheme: X_string (where X is a number)
# run with `bash scriptname.sh +/- <filename1> <filename2> . . . `
