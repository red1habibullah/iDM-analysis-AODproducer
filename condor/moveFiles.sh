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

for file in `eos root://cmseos.fnal.gov ls /store/user/as2872/iDM/Samples`; do

    echo "Moving file $file ..."

    if [[ $file == *"Mchi-$mchi"*"ctau-1."* ]]; then
        eos root://cmseos.fnal.gov mv /store/user/as2872/iDM/Samples/$file /store/group/lpcmetx/iDM/AOD/$basedir/Mchi-${mchi}_dMchi-${dmchi}_ctau-1/$file
    elif [[ $file == *"Mchi-$mchi"*"ctau-10."* ]]; then
        eos root://cmseos.fnal.gov mv /store/user/as2872/iDM/Samples/$file /store/group/lpcmetx/iDM/AOD/$basedir/Mchi-${mchi}_dMchi-${dmchi}_ctau-10/$file
    elif [[ $file == *"Mchi-$mchi"*"ctau-100."* ]]; then
        eos root://cmseos.fnal.gov mv /store/user/as2872/iDM/Samples/$file /store/group/lpcmetx/iDM/AOD/$basedir/Mchi-${mchi}_dMchi-${dmchi}_ctau-100/$file
    elif [[ $file == *"Mchi-$mchi"*"ctau-1000."* ]]; then
        eos root://cmseos.fnal.gov mv /store/user/as2872/iDM/Samples/$file /store/group/lpcmetx/iDM/AOD/$basedir/Mchi-${mchi}_dMchi-${dmchi}_ctau-1000/$file
    fi

done
