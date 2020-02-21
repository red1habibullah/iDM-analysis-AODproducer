#!/bin/bash

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 year mchi dmchi" >&2
    exit 1
fi

year=$1
mchi=$2
dmchi=$3

# Set final LPC dir with write access
LPCdir=/store/group/lpcmetx/iDM/Samples

for file in `ls /eos/user/a/asterenb/iDM/Samples`; do

    if [[ $file == *"Mchi-$mchi"*"year-$year"* ]]; then
        echo "Moving file $file to temporary folder Samples on the LPC EOS..."
	xrdcp /eos/user/a/asterenb/iDM/Samples/$file "root://cmseos.fnal.gov/$LPCdir"
	if [ $? -eq 0 ]; then
		rm /eos/user/a/asterenb/iDM/Samples/$file
	fi
    fi

done
