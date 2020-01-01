# AOD production via condor

The main script is submitPileup.py, with usage:

```
$ ./submitPileup.py gridpack_filename year [njobs]
```

The gridpack file should be located under `./gridpacks/Production/` and only its name (without the path) is given to submitPileup.py.

There is one Pythia hadronizer config for each proper lifetime under `./conf/` (i.e. ctau = 1, 10, 100, 1000 mm), and then a set of 4 for 2017/18 and another set for 2016. The 2017/18 hadronizers use the CP5 MC tunes and the 2016 hadronizers use the CUEP8M1 tunes as recommended by GEN-SIM/MC groups.

The submitPileup.py script calls another script, `runOffGridpackXXXXPileupCondor.sh`, based on the year passed as an argument. Each runOffGridpack script runs the appropriate cmsDriver and cmsRun commands to generate an AOD from a gridpack. The steps are:

* step A: Generate LHE events from gridpack (runs MG+Pythia)
* step B (or step 'GEN-SIM' in CMSSW): Generate GEN-SIM from LHE (runs CMSSW simulation)
* step C (or step1 in CMSSW): Generate DIGI-RAW-HLT from GEN-SIM (runs digitization and reconstruction)
* step D (or step2 in CMSSW): Generate AOD from DIGI (creates final physics objects)

Since the production includes pileup, there is also a DIGI-RAW-HLT cmsDriver template config for each year, e.g. `DIGIRAWHLT_template_XXXX.py`, in order to save time. Loading all the pileup samples before the mixing stage takes quite a while (and doesn't change from sample to sample), so it's much faster to issue the cmsDriver.py command once and save the result as a template file, only replacing the relevant quantities on a per-run basis. All of this is handled by submitPileup.py.

In addition, there are examples for 2018 only of `runOffGridpack2018.sh` and `runOffGridpack2018Pileup.sh`, the first one configured to produce AODs without pileup, and the second to run with pileup but interactively (no condor).

Finally, there is a script called `moveFiles.sh` to transfer all produced AODs from a single temporary output folder (currently `/store/group/lpcmetx/iDM/Samples`) to a final storage folder (currently `/store/group/lpcmetx/iDM/AOD/$year/signal/Mchi-XX_dMchi-XX_ctau-XX` depending on sample parameters). The usage is:

```
$ ./moveFiles.sh year mchi dmchi
```
