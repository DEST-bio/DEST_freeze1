#!/usr/bin/env bash
#
#SBATCH -J mergeSync # A single job name for the array
#SBATCH --ntasks-per-node=1 # one core
#SBATCH -N 1 # on one node
#SBATCH -t 0:60:00 ### 1 hour
#SBATCH --mem 4G
#SBATCH -o /scratch/aob2x/dest/slurmOutput/mergeSync.%A_%a.out # Standard output
#SBATCH -e /scratch/aob2x/dest/slurmOutput/mergeSync.%A_%a.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab

#ijob -c1 -p standard -A berglandlab

#####################
### get jobs task ###
#####################

#SLURM_ARRAY_TASK_ID=3
pop=$( ls /scratch/aob2x/dest/dgn/syncData/*dm6.sync | \
cut -f1 -d'_' | rev | cut -f1 -d'/' | rev | sort | uniq | \
awk -v currJob=${SLURM_ARRAY_TASK_ID} '{if(currJob==NR) print $0}' )

echo $pop

cat /scratch/aob2x/dest/dgn/syncData/${pop}_Chr*dm6.sync > /scratch/aob2x/dest/dgn/syncData/${pop}_genome.dm6.sync
