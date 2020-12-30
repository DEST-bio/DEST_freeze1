#!/usr/bin/env bash
#
#SBATCH -J annotate # A single job name for the array
#SBATCH --ntasks-per-node=10 # one core
#SBATCH -N 1 # on one node
#SBATCH -t 12:00:00 ### 6 hours
#SBATCH --mem 90G
#SBATCH -o /scratch/aob2x/dest/slurmOutput/split_and_run.%A_%a.out # Standard output
#SBATCH -e /scratch/aob2x/dest/slurmOutput/split_and_run.%A_%a.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab


## sacct -j 13029805
module load htslib bcftools intel/18.0 intelmpi/18.0 parallel


stem=$( ls /scratch/aob2x/dest/sub_bcf_paramTest/dest.June14_2020.maf001.*.paramTest.bcf | rev | cut -d'.' -f3,4 | rev | sort | uniq | sed "${SLURM_ARRAY_TASK_ID}q;d" )
#maf=001
wd=/scratch/aob2x/dest


bcftools concat \
${wd}/sub_bcf_paramTest/dest.June14_2020.maf001.2L.${stem}.paramTest.bcf \
${wd}/sub_bcf_paramTest/dest.June14_2020.maf001.2R.${stem}.paramTest.bcf \
${wd}/sub_bcf_paramTest/dest.June14_2020.maf001.3L.${stem}.paramTest.bcf \
${wd}/sub_bcf_paramTest/dest.June14_2020.maf001.3R.${stem}.paramTest.bcf \
${wd}/sub_bcf_paramTest/dest.June14_2020.maf001.X.${stem}.paramTest.bcf \
${wd}/sub_bcf_paramTest/dest.June14_2020.maf001.4.${stem}.paramTest.bcf \
${wd}/sub_bcf_paramTest/dest.June14_2020.maf001.Y.${stem}.paramTest.bcf \
-n \
-o ${wd}/paramTest/dest.${stem}.paramTest.bcf

bcftools view \
--threads 10 \
${wd}/paramTest/dest.${stem}.paramTest.bcf > ${wd}/paramTest/dest.${stem}.paramTest.vcf

java -jar ~/snpEff/snpEff.jar \
eff \
BDGP6.86 \
${wd}/paramTest/dest.${stem}.paramTest.vcf > \
${wd}/paramTest/dest.${stem}.paramTest.ann.vcf

#Rscript --vanilla ${wd}/DEST/snpCalling/vcf2gds.R ${wd}/dest.June14_2020.${maf}.ann.vcf

bgzip -c ${wd}/paramTest/dest.${stem}.paramTest.ann.vcf > ${wd}/paramTest/dest.${stem}.paramTest.ann.vcf.gz
