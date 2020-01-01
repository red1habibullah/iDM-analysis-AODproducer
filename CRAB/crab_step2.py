from CRABClient.UserUtilities import config
config = config()

sample_name = 'Mchi-6p0_dMchi-2p0_ctau-1000'

config.General.requestName = 'step2_' + sample_name
config.General.workArea = 'crab'
config.General.transferOutputs = True
config.General.transferLogs = True

config.JobType.pluginName = 'Analysis'
config.JobType.psetName = 'externalLHEProducer_and_PYTHIA8_Hadronizer_AOD_cfg_ctau-1000.py'
config.JobType.numCores = 1
config.JobType.maxMemoryMB = 4000

config.Data.inputDataset = '/Mchi-6p0_dMchi-2p0_ctau-1000/asterenb-step1-0c44357b4d68f01003c1f09edb307b21/USER'
config.Data.inputDBS = 'phys03'
config.Data.outputDatasetTag = 'step2'
config.Data.splitting = 'FileBased'
config.Data.unitsPerJob = 1
config.Data.publication = True
config.Data.ignoreLocality = True
config.Data.outLFNDirBase = '/store/group/lpcmetx/iDM/MC/2018/signal'

config.Site.ignoreGlobalBlacklist = True
config.Site.whitelist = ["T3_US_FNALLPC"]
config.Site.storageSite = 'T3_US_FNALLPC'
