#! /bin/bash

## This script is used to produce AOD files from a gridpack for
## 2016 data. The CMSSW version is 8_0_21 and all four lifetimes are
## produced: {1, 10, 100, 1000} mm per seed.
##
## The lifetime replacement no longer occurs at the LHE level (i.e.
## manually replacing the lifetime in LHE events) but rather at the
## Pythia hadronizer level. For private production, there are four 
## different hadronizers, one for each ctau, which gets called by this
## script as appropriate. For official central production, can have the
## calling script `sed` into the one hadronizer file to change the 
## lifetime accordingly.
##
## Currently MINIAOD production is commented out to save time (and we don't use it).

## Usage: ./runOffGridpack.sh gridpack_file.tar.xz

export BASEDIR=`pwd`
GP_f=$1
GRIDPACKDIR=${BASEDIR}/gridpacks
LHEDIR=${BASEDIR}/mylhes
SAMPLEDIR=${BASEDIR}/samples
[ -d ${LHEDIR} ] || mkdir ${LHEDIR}

HADRONIZER="externalLHEProducer_and_PYTHIA8_Hadronizer_2016"
namebase=${GP_f/.tar.xz/}
nevent=500

export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
source $VO_CMS_SW_DIR/cmsset_default.sh

export SCRAM_ARCH=slc6_amd64_gcc530
if ! [ -r CMSSW_8_0_21/src ] ; then
    scram p CMSSW CMSSW_8_0_21
fi
cd CMSSW_8_0_21/src
eval `scram runtime -sh`
scram b -j 4
tar xaf ${GRIDPACKDIR}/${GP_f}
sed -i 's/exit 0//g' runcmsgrid.sh
ls -lrth

RANDOMSEED=`od -vAn -N4 -tu4 < /dev/urandom`
#Sometimes the RANDOMSEED is too long for madgraph
RANDOMSEED=`echo $RANDOMSEED | rev | cut -c 3- | rev`

echo "0.) Generating LHE"
sh runcmsgrid.sh ${nevent} ${RANDOMSEED} 4
namebase=${namebase}_$RANDOMSEED
cp cmsgrid_final.lhe ${LHEDIR}/${namebase}.lhe
echo "${LHEDIR}/${namebase}.lhe" 
rm -rf *
cd ${BASEDIR}

export SCRAM_ARCH=slc6_amd64_gcc530
if ! [ -r CMSSW_8_0_21/src ] ; then
    scram p CMSSW CMSSW_8_0_21
fi
cd CMSSW_8_0_21/src
rm -rf *
mkdir -p Configuration/GenProduction/python/

for ctau_mm in 1 10 100 1000
#for ctau_mm in 100
do
    #export SCRAM_ARCH=slc6_amd64_gcc481
    #if [ -r CMSSW_7_1_30/src ] ; then 
    #    echo release CMSSW_7_1_30 already exists
    #else
    #    scram p CMSSW CMSSW_7_1_30
    #fi
    #cd CMSSW_7_1_30/src
    #eval `scram runtime -sh`
    #mkdir -p Configuration/GenProduction/python/

    cp "${BASEDIR}/conf/${HADRONIZER}_ctau-${ctau_mm}.py" Configuration/GenProduction/python/
    eval `scram runtime -sh`
    scram b -j 4
    echo "1.) Generating GEN-SIM for lifetime ${ctau_mm}"
    genfragment=${namebase}_GENSIM_cfg_ctau-${ctau_mm}.py
    cmsDriver.py Configuration/GenProduction/python/${HADRONIZER}_ctau-${ctau_mm}.py \
        --filein file:${LHEDIR}/${namebase}.lhe \
        --fileout file:${namebase}_GENSIM_ctau-${ctau_mm}.root \
        --mc --eventcontent RAWSIM --datatier GEN-SIM \
        --conditions 80X_mcRun2_asymptotic_2016_TrancheIV_v8 --beamspot Realistic50ns13TeVCollision \
        --step GEN,SIM --era Run2_2016 \
        --customise Configuration/DataProcessing/Utils.addMonitoring \
        --python_filename ${genfragment} --no_exec -n ${nevent} || exit $?;

    #cmsDriver.py Configuration/GenProduction/python/${HADRONIZER}_ctau-${ctau_mm}.py \
    #    --filein file:${LHEDIR}/${namebase}.lhe \
    #    --fileout file:${namebase}_GENSIM_ctau-${ctau_mm}.root \
    #    --mc --eventcontent RAWSIM --datatier GEN-SIM \
    #    --conditions MCRUN2_71_V1::All --beamspot Realistic50ns13TeVCollision \
    #    --step GEN,SIM \
    #    --magField 38T_PostLS1
    #    --customise SLHCUpgradeSimulations/Configuration/postLS1Customs.customisePostLS1,Configuration/DataProcessing/Utils.addMonitoring \
    #    --python_filename ${genfragment} --no_exec -n ${nevent} || exit $?;

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

    cmsRun -p ${genfragment}

    #cd $BASEDIR
    #export SCRAM_ARCH=slc6_amd64_gcc530
    #if ! [ -r CMSSW_8_0_21/src ] ; then
    #    scram p CMSSW CMSSW_8_0_21
    #fi
    #cd CMSSW_8_0_21/src
    #eval `scram runtime -sh`
    #scram b -j 4

    #cp "CMSSW_7_1_30/src/${namebase}_GENSIM_ctau-${ctau_mm}.root" .

    # Step1 is pre-computed, since it takes a while to load all pileup pre-mixed samples
    echo "2.) Generating DIGI-RAW-HLT for lifetime ${ctau_mm}"
    cp ${BASEDIR}/DIGIRAWHLT_template_2016.py .
    sed -i "s/file:placeholder_in.root/file:${namebase}_GENSIM_ctau-${ctau_mm}.root/g" DIGIRAWHLT_template_2016.py
    sed -i "s/file:placeholder_out.root/file:${namebase}_DIGIRAWHLT_ctau-${ctau_mm}.root/g" DIGIRAWHLT_template_2016.py
    sed -i "s/input = cms.untracked.int32(10)/input = cms.untracked.int32(${nevent})/g" DIGIRAWHLT_template_2016.py
    mv DIGIRAWHLT_template_2016.py ${namebase}_DIGIRAWHLT_cfg_ctau-${ctau_mm}.py

    #echo "2.) Generating DIGI-RAW-HLT for lifetime ${ctau_mm}"
    #cmsDriver.py step1 \
    #    --filein file:${namebase}_GENSIM_ctau-${ctau_mm}.root \
    #    --fileout file:${namebase}_DIGIRAWHLT_ctau-${ctau_mm}.root \
    #    --era Run2_2018 --conditions 102X_upgrade2018_realistic_v15 \
    #    --mc --step DIGI,DATAMIX,L1,DIGI2RAW,HLT:@relval2018 \
    #    --procModifiers premix_stage2 \
    #    --datamix PreMix \
    #    --datatier GEN-SIM-DIGI-RAW --eventcontent PREMIXRAW \
    #    --pileup_input "dbs:/Neutrino_E-10_gun/RunIISummer17PrePremix-PUAutumn18_102X_upgrade2018_realistic_v15-v1/GEN-SIM-DIGI-RAW" \
    #    --number ${nevent} \
    #    --geometry DB:Extended --nThreads 1 \
    #    --python_filename ${namebase}_DIGIRAWHLT_cfg_ctau-${ctau_mm}.py \
    #    --customise Configuration/DataProcessing/Utils.addMonitoring \
    #    --no_exec || exit $?;
    cmsRun -p ${namebase}_DIGIRAWHLT_cfg_ctau-${ctau_mm}.py

    echo "3.) Generating AOD for lifetime ${ctau_mm}"
    cmsDriver.py step2 \
        --filein file:${namebase}_DIGIRAWHLT_ctau-${ctau_mm}.root \
        --fileout file:${namebase}_AOD_ctau-${ctau_mm}_year-2016.root \
        --mc --eventcontent AODSIM --datatier AODSIM --runUnscheduled \
        --conditions 80X_mcRun2_asymptotic_2016_TrancheIV_v8 --step RAW2DIGI,L1Reco,RECO,EI \
        --nThreads 2 --era Run2_2016 --python_filename ${namebase}_AOD_cfg_ctau-${ctau_mm}.py --no_exec \
        --customise Configuration/DataProcessing/Utils.addMonitoring -n ${nevent} || exit $?;
    cmsRun -p ${namebase}_AOD_cfg_ctau-${ctau_mm}.py

    # MINIAOD production is commented out
    #echo "4.) Generating MINIAOD"
    #cmsDriver.py step3 \
        #    --filein file:${namebase}_AOD.root \
        #    --fileout file:${namebase}_MINIAOD.root \
        #    --mc --eventcontent MINIAODSIM --datatier MINIAODSIM --runUnscheduled \
        #    --conditions auto:phase1_2018_realistic --step PAT \
        #    --nThreads 8 --era Run2_2018 --python_filename ${namebase}_MINIAOD_cfg.py --no_exec \
        #    --customise Configuration/DataProcessing/Utils.addMonitoring -n ${nevent} || exit $?;
    #cmsRun -p ${namebase}_MINIAOD_cfg.py

    pwd
    cmd="ls -arlth *.root"
    echo $cmd && eval $cmd

    echo "DONE."
done
echo "ALL Done"
