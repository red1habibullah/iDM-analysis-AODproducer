#! /bin/bash

## This script issues cmsDriver.py commands to generate
## CMSSW configs for GENSIM, DIGI, and AOD production from LHE files,
## for 2018 conditions. The CMSSW version is 10_2_3 and a config for
## each lifetime (1, 10, 100, 1000 mm) is generated.
##
## The lifetime replacement no longer occurs at the LHE level (i.e.
## manually replacing the lifetime in LHE events) but rather at the
## Pythia hadronizer level. For private production, there are four 
## different hadronizers, one for each ctau.
## 
## To produce 2017 AOD files use runOffGridpack2017.sh
##
## Currently MINIAOD production is commented out to save time.

## Usage: ./runOffGridpack.sh SIDMmumu_Mps-200_MZp-1p2_ctau-0p1.tar.xz

nevent=1000

SAMPLELHE="/store/group/lpcmetx/iDM/LHE/2018/signal/iDM_Mchi-5p25_dMchi-0p5.lhe"

HADRONIZER="externalLHEProducer_and_PYTHIA8_Hadronizer"
export BASEDIR=`pwd`

export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
source $VO_CMS_SW_DIR/cmsset_default.sh

RANDOMSEED=`od -vAn -N4 -tu4 < /dev/urandom`
#Sometimes the RANDOMSEED is too long for madgraph
RANDOMSEED=`echo $RANDOMSEED | rev | cut -c 3- | rev`

export SCRAM_ARCH=slc6_amd64_gcc700
if ! [ -r CMSSW_10_2_3/src ] ; then
    scram p CMSSW CMSSW_10_2_3
fi
cd CMSSW_10_2_3/src
eval `scram runtime -sh`
scram b -j 4
#rm -rf *
mkdir -p Configuration/GenProduction/python/

#function join_by { local IFS="$1"; shift; echo "$*"; }
#
#file_list=`eosls ${SAMPLEDIR}/*.lhe | sed "s|^|${SAMPLEDIR}|"`
#all_files=`join_by , $file_list`
#echo $all_files
#for file in $files; do
#    echo "/store/group/lpcmetx/iDM/LHE/2018/signal/iDM_Mchi-6p0_dMchi-2p0/$file"
#done

namebase=${HADRONIZER}

for ctau_mm in 1 10 100 1000
# 100 1000
#for ctau_mm in 10
do
    cp "${BASEDIR}/conf/${HADRONIZER}_ctau-${ctau_mm}.py" Configuration/GenProduction/python/
    eval `scram runtime -sh`
    scram b -j 4
    echo "1.) Generating GEN-SIM for lifetime ${ctau_mm}"
    genfragment=${namebase}_GENSIM_cfg_ctau-${ctau_mm}.py
    cmsDriver.py Configuration/GenProduction/python/${HADRONIZER}_ctau-${ctau_mm}.py \
        --filein $SAMPLELHE \
        --filetype LHE \
        --fileout file:${namebase}_GENSIM_ctau-${ctau_mm}.root \
        --mc --eventcontent RAWSIM --datatier GEN-SIM \
        --conditions 102X_upgrade2018_realistic_v15 --beamspot Realistic25ns13TeVEarly2018Collision \
        --step GEN,SIM --era Run2_2018 --nThreads 1 \
        --customise Configuration/DataProcessing/Utils.addMonitoring \
        --python_filename ${genfragment} --no_exec -n ${nevent}

    # this block is to load all files, and then replace '[ with [' in the filelist
    #--filein [$all_files] \
    #sed -i -e "s/'\[/\['/" ${genfragment}
    #sed -i -e "s/\]'/'\]/" ${genfragment}

    #Make each file unique to make later publication possible
    linenumber=`grep -n 'process.source' ${genfragment} | awk '{print $1}'`
    linenumber=${linenumber%:*}
    total_linenumber=`cat ${genfragment} | wc -l`
    bottom_linenumber=$((total_linenumber - $linenumber ))
    tail -n $bottom_linenumber ${genfragment} > tail.py
    head -n $linenumber ${genfragment} > head.py
    echo "    firstRun = cms.untracked.uint32(1)," >> head.py
    echo "    firstLuminosityBlock = cms.untracked.uint32($RANDOMSEED)," >> head.py
    cat tail.py >> head.py
    mv head.py ${genfragment}
    rm -rf tail.py

    #cmsRun -p ${genfragment}

    echo "2.) Generating DIGI-RAW-HLT for lifetime ${ctau_mm}"
    cmsDriver.py step1 \
        --filein file:${namebase}_GENSIM_ctau-${ctau_mm}.root \
        --fileout file:${namebase}_DIGIRAWHLT_ctau-${ctau_mm}.root \
        --era Run2_2018 --conditions 102X_upgrade2018_realistic_v15 \
        --mc --step DIGI,DATAMIX,L1,DIGI2RAW,HLT:@relval2018 \
        --procModifiers premix_stage2 \
        --datamix PreMix \
        --datatier GEN-SIM-DIGI-RAW --eventcontent PREMIXRAW \
        --pileup_input "dbs:/Neutrino_E-10_gun/RunIISummer17PrePremix-PUAutumn18_102X_upgrade2018_realistic_v15-v1/GEN-SIM-DIGI-RAW" \
        --number ${nevent} \
        --geometry DB:Extended --nThreads 1 \
        --python_filename ${namebase}_DIGIRAWHLT_cfg_ctau-${ctau_mm}.py \
        --customise Configuration/DataProcessing/Utils.addMonitoring \
        --no_exec
    #cmsRun -p ${namebase}_DIGIRAWHLT_cfg_ctau-${ctau_mm}.py

    echo "3.) Generating AOD for lifetime ${ctau_mm}"
    cmsDriver.py step2 \
        --filein file:${namebase}_DIGIRAWHLT_ctau-${ctau_mm}.root \
        --fileout file:${namebase}_AOD_ctau-${ctau_mm}.root \
        --mc --eventcontent AODSIM --datatier AODSIM --runUnscheduled \
        --conditions 102X_upgrade2018_realistic_v15 --step RAW2DIGI,L1Reco,RECO,RECOSIM,EI \
        --procModifiers premix_stage2 \
        --nThreads 1 --era Run2_2018 --python_filename ${namebase}_AOD_cfg_ctau-${ctau_mm}.py --no_exec \
        --customise Configuration/DataProcessing/Utils.addMonitoring -n ${nevent}
    #cmsRun -p ${namebase}_AOD_cfg_ctau-${ctau_mm}.py

    #echo "4.) Generating MINIAOD"
    #cmsDriver.py step3 \
        #    --filein file:${namebase}_AOD.root \
        #    --fileout file:${namebase}_MINIAOD.root \
        #    --mc --eventcontent MINIAODSIM --datatier MINIAODSIM --runUnscheduled \
        #    --conditions auto:phase1_2018_realistic --step PAT \
        #    --nThreads 8 --era Run2_2018 --python_filename ${namebase}_MINIAOD_cfg.py --no_exec \
        #    --customise Configuration/DataProcessing/Utils.addMonitoring -n ${nevent} || exit $?;
    #cmsRun -p ${namebase}_MINIAOD_cfg.py

    echo "DONE."
done
cd $BASEDIR
echo "ALL Done"
