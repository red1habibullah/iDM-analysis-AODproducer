# iDM-analysis-AODproducer

This is the repository used to produce AOD samples for the inelastic dark matter (iDM) analysis. The starting point is a gridpack created with Madgraph using a variant of the HAHM model. The gridpack config and Madgraph cards can be found [here](https://github.com/afrankenthal/GridPacker/tree/idm-branch).

There are two ways to produce AODs: via CRAB or via condor. There is a folder for each, with detailed instructions on how to run in each subfolder's README. However, currently only condor really works, due to issues in the way CMSSW handles multiple LHE input files (see e.g. [here](https://twiki.cern.ch/twiki/bin/view/CMSPublic/SWGuideLHEInterface#LHESource) and [here](https://github.com/dmwm/CRABServer/issues/4659#issuecomment-76165323)). I tried to work around this issue but kept getting strange (i.e. wrong) results producing AODs via CRAB. So for now the (strongly) recommended way is via condor.

