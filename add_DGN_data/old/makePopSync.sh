#!/usr/bin/env bash
#
#SBATCH -J makePopSync # A single job name for the array
#SBATCH --ntasks-per-node=1 # one core
#SBATCH -N 1 # on one node
#SBATCH -t 6:00:00 ### 6 hours
#SBATCH --mem 1G
#SBATCH -o /scratch/aob2x/dest/slurmOutput/makePopSync.%A_%a.out # Standard output
#SBATCH -e /scratch/aob2x/dest/slurmOutput/makePopSync.%A_%a.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab


wd="/scratch/aob2x/dest"

#####################
### get jobs task ###
#####################

#SLURM_ARRAY_TASK_ID=50
##chr_i=$( echo "${SLURM_ARRAY_TASK_ID}%5+1" | bc )
##pop_i=$( echo "${SLURM_ARRAY_TASK_ID}%35+1" | bc )

pop=$( grep  "^${SLURM_ARRAY_TASK_ID}[[:space:]]" ${wd}/dgn/pops.delim | cut -f3 )
chr=$( grep  "^${SLURM_ARRAY_TASK_ID}[[:space:]]" ${wd}/dgn/pops.delim | cut -f2 )


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

############################
### paste per chromosome ###
############################

#if [ ! -f ${wd}/dgn/csvData/${pop}_Chr${chr}.csv ]; then
#
#    paste -d',' ${wd}/dgn/longData/${pop}_*_Chr${chr}*long  \
#    ${wd}/dgn/csvData/${pop}_Chr${chr}.csv
#
#fi
#

##########################
### csv to sync format ###
##########################

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

if(nObs>0) {
if((nA/nObs > 0 && nA/nObs < 1) || (nC/nObs > 0 && nC/nObs < 1) || (nT/nObs > 0 && nT/nObs < 1) || (nG/nObs > 0 && nG/nObs<1)) {
print chr"\t"NR"\t"toupper($1)"\t"nA":"nT":"nC":"nG":"nN":0"
}
}
}' less -S  > /scratch/aob2x/dest/dgn/syncData/${pop}_Chr${chr}.sync
