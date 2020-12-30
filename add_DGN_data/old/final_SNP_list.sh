#!/usr/bin/env bash
#
#SBATCH -J finalSNP_list # A single job name for the array
#SBATCH --ntasks-per-node=1 # one core
#SBATCH -N 1 # on one node
#SBATCH -t 1:00:00 ### 1 hours
#SBATCH --mem 1G
#SBATCH -o /scratch/aob2x/dest/slurmOutput/finalSNP_list.%A_%a.out # Standard output
#SBATCH -e /scratch/aob2x/dest/slurmOutput/finalSNP_list.%A_%a.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab

#SLURM_ARRAY_TASK_ID=2



module load gcc/7.1.0 bedops/2.4.1

### First do a bit of modification to the bed file
 cat /scratch/aob2x/dest/dest/dgn_drosRTEC_drosEU.sites.dm6.bed | \
 awk '{
 if(NF==3) {
   print $0"\tdm6_"$1":"$2
 } else if(NF==4) {
   print $0
 }
}' > /scratch/aob2x/dest/dest/dgn_drosRTEC_drosEU.sites.dm6.bed.tmp

rm /scratch/aob2x/dest/dest/dgn_drosRTEC_drosEU.sites.dm6.bed
mv  /scratch/aob2x/dest/dest/dgn_drosRTEC_drosEU.sites.dm6.bed.tmp  /scratch/aob2x/dest/dest/dgn_drosRTEC_drosEU.sites.dm6.bed

### Next identify 11M NEW sites
  bedops \
  -n \
  /scratch/aob2x/dest/dest/dgn_drosRTEC_drosEU.sites.dm6.bed \
  /scratch/aob2x/dest/dest/drosRTEC_DrosEU_DGRP_SNPs_filtered.pos.dm6.bed > \
  /scratch/aob2x/dest/dest/dgn_drosRTEC_drosEU.sites.dm6.additional.bed

### Liftover full and additional sites to dm3
  ### FULL
    ~/liftOver \
    /scratch/aob2x/dest/dest/dgn_drosRTEC_drosEU.sites.dm6.bed \
    /scratch/aob2x/dest/dgn/liftoverChains/dm6ToDm3.over.chain \
    /scratch/aob2x/dest/dest/dgn_drosRTEC_drosEU.sites.dm3.bed \
    /scratch/aob2x/dest/dest/dgn_drosRTEC_drosEU.sites.unmapped.bed

  ### Additional
    ~/liftOver \
    /scratch/aob2x/dest/dest/dgn_drosRTEC_drosEU.sites.dm6.additional.bed \
    /scratch/aob2x/dest/dgn/liftoverChains/dm6ToDm3.over.chain \
    /scratch/aob2x/dest/dest/dgn_drosRTEC_drosEU.sites.dm3.additional.bed \
    /scratch/aob2x/dest/dest/dgn_drosRTEC_drosEU.sites.unmapped.additional.bed
