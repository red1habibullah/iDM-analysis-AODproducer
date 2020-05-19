#!/usr/bin/env python

import os, sys

'''Usage: ./submit.py <LHE/gridpack filename> year [njobs]
'''

def buildSubmit(infile, workpath, mode, uid, year):
    '''A series of actions to prepare submit dir'''

    stageOutPiece = '''
remoteDIR="/eos/user/a/asterenb/iDM/Samples"
for f in `ls *AOD*.root`; do
    cmd="xrdcp -vf file:///$PWD/$f root://eosuser.cern.ch/$remoteDIR/$f"
    echo $cmd && eval $cmd
done'''

    os.makedirs(workpath+'/submit/conf')
    os.system('cp conf/* %s/submit/conf/' % workpath)
    try:
        if mode=='lhe':
            os.makedirs(workpath+'/submit/mgLHEs')
            os.system('cp mgLHEs/%s %s/submit/mgLHEs' % (infile, workpath))
            os.system('cp replaceLHELifetime.py %s/submit' % workpath)
            os.system('cp runOffLHE.sh %s/submit' % workpath)
            with open('%s/submit/runOffLHE.sh' % workpath, 'a') as f:
                f.write(stageOutPiece)
        else:
            os.makedirs(workpath+'/submit/gridpacks')
            os.system('cp gridpacks/Production/%s %s/submit/gridpacks' % (infile, workpath))
            os.system('cp runOffGridpack%sPileupCondorLxplusCtau1mm.sh %s/submit' % (year,workpath))
            os.system('cp DIGIRAWHLT_template_%s.py %s/submit' % (year,workpath))
            with open('%s/submit/runOffGridpack%sPileupCondorLxplusCtau1mm.sh' % (workpath,year), 'a') as f:
                f.write(stageOutPiece)
    except:
        print "%s probably does not exist." % infile
        cmd = ['ls -lrth '+s for s in ('.', 'mgLHES', 'gridpacks')]
        for c in cmd:
            print cmd
            os.system(cmd)
        raise


    #os.system('cp /tmp/x509up_u%d %s/x509up' % (uid, workpath))
    print "Tarring up submit..."
    os.chdir(workpath)
    os.system('tar -chzf submit.tgz submit')
    os.chdir('..')



def buildExec(infile, workpath, mode, year):
    '''Given the workpath, write a exec.sh in it, to be used by condor'''

    execF = '''#!/bin/bash

export HOME=${PWD}

tar xvaf submit.tgz
cd submit
sh %s.sh %s
cd ${HOME}
rm -r submit/

exit 0'''
    with open(workpath + '/exec.sh', 'w') as f:
        # Deduce decay length [mm] from gridpack name..
        # e.g. *_ctau-0p1.tar.xz
        # e.g. *_ctau-0p01.lhe.gz
        ctau = '0'
        if 'iDM' in infile:
            nameTags = infile.split('.')[0].split('_')
            for t in nameTags:
                if 'ctau' in t:
                    ctau = t.split('-', 1)[-1]
                    ctau = str( float(ctau.replace('p','.'))) # in mm already *10 )

        if mode == 'lhe':
            f.write(execF % ('runOffLHE', infile+' '+ctau))
        else:
            f.write(execF % (('runOffGridpack%sPileupCondorLxplusCtau1mm' % year), infile+' '+ctau))



def buildCondor(process, workpath, logpath, uid, njobs=1):
    '''build the condor file, return the abs path'''

    condorF = '''universe = vanilla
executable = {0}/exec.sh
should_transfer_files = YES
WHEN_TO_TRANSFER_OUTPUT = ON_EXIT_OR_EVICT
+SpoolOnEvict = False
transfer_input_files = {0}/submit.tgz
transfer_output_files = ""
input = /dev/null
output = {1}/$(Cluster)_$(Process).out
error = {1}/$(Cluster)_$(Process).err
log = {1}/$(Cluster)_$(Process).log
rank = Mips
request_memory = 8000
arguments = $(Process)
+JobFlavour = "tomorrow"
requirements = (OpSysAndVer =?= "SLCern6")
#on_exit_hold = (ExitBySignal == True) || (ExitCode != 0)
+AcctGroup = "analysis"
+ProjectName = "DarkMatterSimulation"
queue {2}'''.format(workpath, logpath, njobs)
    condorFN = 'condor_%s.jdl' % process

    with open(logpath + '/' + condorFN, 'w') as jdlfile:
        jdlfile.write(condorF)

    return os.path.join(logpath, condorFN)


if __name__ == "__main__":

    if len(sys.argv) < 3:
        print "ERROR! Need at least 2 arguments!"
        print "Usage: ./submit.py <LHE/gridpack filename> year [njobs]"
        sys.exit()
    elif sys.argv[2] not in ['2016', '2017', '2018']: 
        print "ERROR! Year (2016/17/18) is a mandatory argument!"
        print "Usage: ./submit.py <LHE/gridpack filename> year [njobs]"
        sys.exit()

    inf = sys.argv[1]
    Mode = 'lhe' if 'lhe' in inf else 'gridpack'
    Process = inf.split('/')[-1].split('.')[0]
    print Process
        
    year = sys.argv[2]

    Njobs = 1 if len(sys.argv) < 4 else sys.argv[3]

    Logpath = os.getcwd() + '/Logs'
    if not os.path.isdir(Logpath): os.mkdir(Logpath)
    Submissionpath = os.getcwd() + '/submissions'
    if not os.path.isdir(Submissionpath): os.mkdir(Submissionpath)
    Workpath = Submissionpath + '/submit_' + Process
    if os.path.isdir(Workpath): os.system('rm -rf %s' % Workpath)
    os.mkdir(Workpath)
    Uid = os.getuid()

    buildSubmit(infile=inf, workpath=Workpath, mode=Mode, uid=Uid, year=year)
    buildExec(infile=inf, workpath=Workpath, mode=Mode, year=year)
    theCondor = buildCondor(process=Process, workpath=Workpath,
            logpath=Logpath, uid=Uid, njobs=Njobs)
    os.system('condor_submit %s' % theCondor)
