#!/usr/bin/env bash
#
#SBATCH -J getSNP_list_drosEU# A single job name for the array
#SBATCH --ntasks-per-node=1 # one core
#SBATCH -N 1 # on one node
#SBATCH -t 1:00:00 ### 1 hours
#SBATCH --mem 1G
#SBATCH -o /scratch/aob2x/dest/slurmOutput/getSNP_list_drosEU.%A_%a.out # Standard output
#SBATCH -e /scratch/aob2x/dest/slurmOutput/getSNP_list_drosEU.%A_%a.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab

#SLURM_ARRAY_TASK_ID=2

zcat /scratch/aob2x/dest/drosEU/DrosEU-mac002-mic10-mc20-mf0001-mif02-filtered-ann.vcf.gz | grep -v "#" | cut -f1,2 | \
awk '{print "chr"$1"\t"$2"\t"$2+1}' > /scratch/aob2x/dest/drosEU/drosEU_sites.dm6.bed
