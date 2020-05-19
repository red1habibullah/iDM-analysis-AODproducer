#!/bin/bash

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 year mchi dmchi" >&2
    exit 1
fi

year=$1
mchi=$2
dmchi=$3
#basedir="2018/GenFilter_1or2jets_icckw1_drjj0_xptj80_xqcut20_qcut20"
basedir="$year/signal"

eos root://cmseos.fnal.gov mkdir /store/group/lpcmetx/iDM/AOD/$basedir/Mchi-${mchi}_dMchi-${dmchi}_ctau-1
eos root://cmseos.fnal.gov mkdir /store/group/lpcmetx/iDM/AOD/$basedir/Mchi-${mchi}_dMchi-${dmchi}_ctau-10
eos root://cmseos.fnal.gov mkdir /store/group/lpcmetx/iDM/AOD/$basedir/Mchi-${mchi}_dMchi-${dmchi}_ctau-100
eos root://cmseos.fnal.gov mkdir /store/group/lpcmetx/iDM/AOD/$basedir/Mchi-${mchi}_dMchi-${dmchi}_ctau-1000

for file in `eos root://cmseos.fnal.gov ls /store/group/lpcmetx/iDM/Samples`; do

    if [[ $file == *"Mchi-${mchi}_dMchi-${dmchi}"*"ctau-1_"*"year-$year"* ]]; then
        echo "Moving file $file ..."
        eos root://cmseos.fnal.gov mv /store/group/lpcmetx/iDM/Samples/$file /store/group/lpcmetx/iDM/AOD/$basedir/Mchi-${mchi}_dMchi-${dmchi}_ctau-1/$file
    elif [[ $file == *"Mchi-${mchi}_dMchi-${dmchi}"*"ctau-10_"*"year-$year"* ]]; then
        echo "Moving file $file ..."
        eos root://cmseos.fnal.gov mv /store/group/lpcmetx/iDM/Samples/$file /store/group/lpcmetx/iDM/AOD/$basedir/Mchi-${mchi}_dMchi-${dmchi}_ctau-10/$file
    elif [[ $file == *"Mchi-${mchi}_dMchi-${dmchi}"*"ctau-100_"*"year-$year"* ]]; then
        echo "Moving file $file ..."
        eos root://cmseos.fnal.gov mv /store/group/lpcmetx/iDM/Samples/$file /store/group/lpcmetx/iDM/AOD/$basedir/Mchi-${mchi}_dMchi-${dmchi}_ctau-100/$file
    elif [[ $file == *"Mchi-${mchi}_dMchi-${dmchi}"*"ctau-1000_"*"year-$year"* ]]; then
        echo "Moving file $file ..."
        eos root://cmseos.fnal.gov mv /store/group/lpcmetx/iDM/Samples/$file /store/group/lpcmetx/iDM/AOD/$basedir/Mchi-${mchi}_dMchi-${dmchi}_ctau-1000/$file
    fi

done
