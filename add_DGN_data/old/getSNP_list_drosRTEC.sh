#!/usr/bin/env bash
#
#SBATCH -J getSNP_list_drosRTEC # A single job name for the array
#SBATCH --ntasks-per-node=1 # one core
#SBATCH -N 1 # on one node
#SBATCH -t 1:00:00 ### 1 hours
#SBATCH --mem 12G
#SBATCH -o /scratch/aob2x/dest/slurmOutput/getSNP_list_drosRTEC.%A_%a.out # Standard output
#SBATCH -e /scratch/aob2x/dest/slurmOutput/getSNP_list_drosRTEC.%A_%a.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab

#SLURM_ARRAY_TASK_ID=2

module load gcc/7.1.0  openmpi/3.1.4 R/3.6.1

Rscript /scratch/aob2x/dest/DEST/add_DGN_data/getSNP_list_drosRTEC.R

~/liftOver \
/scratch/aob2x/dest/drosRTEC/drosRTEC_sites.dm3.bed \
/scratch/aob2x/dest/dgn/liftoverChains/dm3ToDm6.over.chain \
/scratch/aob2x/dest/drosRTEC/drosRTEC_sites.dm6.bed \
/scratch/aob2x/dest/drosRTEC/drosRTEC_sites.unmapped.bed
