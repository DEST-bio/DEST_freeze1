#!/usr/bin/env bash
#
#SBATCH -J sync_knownSites # A single job name for the array
#SBATCH --ntasks-per-node=1 # one core
#SBATCH -N 1 # on one node
#SBATCH -t 0:60:00 ### 1 hour
#SBATCH --mem 4G
#SBATCH -o /scratch/aob2x/dest/slurmOutput/sync_knownSites.%A_%a.out # Standard output
#SBATCH -e /scratch/aob2x/dest/slurmOutput/sync_knownSites.%A_%a.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab

#ijob -c1 -p standard -A berglandlab

#####################
### get jobs task ###
#####################

#SLURM_ARRAY_TASK_ID=100
##chr_i=$( echo "${SLURM_ARRAY_TASK_ID}%5+1" | bc )
##pop_i=$( echo "${SLURM_ARRAY_TASK_ID}%35+1" | bc )

pop=$( grep  "^${SLURM_ARRAY_TASK_ID}[[:space:]]" /scratch/aob2x/dest/dgn/pops.delim | cut -f3 )
chr=$( grep  "^${SLURM_ARRAY_TASK_ID}[[:space:]]" /scratch/aob2x/dest/dgn/pops.delim | cut -f2 )


##if [ ${chr_i} == "1" ]; then
##  chr="2L"
##elif [ ${chr_i} == "2" ]; then
##  chr="2R"
##elif [ ${chr_i} == "3" ]; then
##  chr="3L"
##elif [ ${chr_i} == "4" ]; then
##  chr="3R"
##elif [ ${chr_i} == "5" ]; then
##  chr="X"
##fi
##

echo $pop
echo $chr


#pop=SIM; chr=2L

##########################
### csv to sync format ###
##########################

if [ ! -f /scratch/aob2x/dest/dgn/syncData/${pop}_Chr${chr}.long.sync.sort ]; then
  paste -d' ' \
  /scratch/aob2x/dest/referenceGenome/r5/${chr}.long \
  /scratch/aob2x/dest/dgn/csvData/${pop}_Chr${chr}.csv | \
  awk -F' ' -v chr=${chr} '
  {
  nN=gsub(/N/,"",$2)
  nA=gsub(/A/,"",$2)
  nT=gsub(/T/,"",$2)
  nC=gsub(/C/,"",$2)
  nG=gsub(/G/,"",$2)

  nObs=nA+nT+nC+nG

  print "chr"chr"_"NR"\t"chr"\t"NR"\t"toupper($1)"\t"nA":"nT":"nC":"nG":"nN":0"

  }' | sort -k1b,1 > /scratch/aob2x/dest/dgn/syncData/${pop}_Chr${chr}.long.sync.sort
fi

#### intersect with known sites

join -a1 \
/scratch/aob2x/dest/dest/dgn_drosRTEC_drosEU.sites.noMerge.noDups.noRep.dm3.dm6Tag.bed.dm3IDsort \
/scratch/aob2x/dest/dgn/syncData/${pop}_Chr${chr}.long.sync.sort | grep "chr"${chr}"_" |
cut -f5,8,9 -d' ' | sed 's/dm6_chr//g' | sed 's/_/ /g' | sort -k1,1b -k2,2g > /scratch/aob2x/dest/dgn/syncData/${pop}_Chr${chr}.dm6.sync
