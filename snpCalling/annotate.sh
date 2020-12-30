#!/usr/bin/env bash
#
#SBATCH -J annotate # A single job name for the array
#SBATCH --ntasks-per-node=10 # one core
#SBATCH -N 1 # on one node
#SBATCH -t 24:00:00 ### 6 hours
#SBATCH --mem 20G
#SBATCH -o /scratch/aob2x/dest/slurmOutput/split_and_run.%A_%a.out # Standard output
#SBATCH -e /scratch/aob2x/dest/slurmOutput/split_and_run.%A_%a.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab


# cat /scratch/aob2x/dest/slurmOutput/split_and_run.19037185_4.err
module load htslib bcftools intel/18.0 intelmpi/18.0 parallel R/3.6.3


popSet=${1}
method=${2}
maf=${3}
mac=${4}
version=${5}
#maf=001; mac=100; popSet="all"; method="PoolSNP"; version="paramTest"

wd=/scratch/aob2x/dest

echo "index"
  bcftools index -f ${wd}/sub_bcf/dest.2L.${popSet}.${method}.${maf}.${mac}.${version}.bcf
  bcftools index -f ${wd}/sub_bcf/dest.2R.${popSet}.${method}.${maf}.${mac}.${version}.bcf
  bcftools index -f ${wd}/sub_bcf/dest.3L.${popSet}.${method}.${maf}.${mac}.${version}.bcf
  bcftools index -f ${wd}/sub_bcf/dest.3R.${popSet}.${method}.${maf}.${mac}.${version}.bcf
  bcftools index -f ${wd}/sub_bcf/dest.X.${popSet}.${method}.${maf}.${mac}.${version}.bcf
  bcftools index -f ${wd}/sub_bcf/dest.Y.${popSet}.${method}.${maf}.${mac}.${version}.bcf
  bcftools index -f ${wd}/sub_bcf/dest.4.${popSet}.${method}.${maf}.${mac}.${version}.bcf


echo "concat"
  bcftools concat \
  ${wd}/sub_bcf/dest.*.${popSet}.${method}.${maf}.${mac}.${version}.bcf \
  -o ${wd}/dest.${popSet}.${method}.${maf}.${mac}.${version}.bcf


echo "convert to vcf & annotate"
  bcftools view \
  --threads 10 \
  ${wd}/dest.${popSet}.${method}.${maf}.${mac}.${version}.bcf | \
  java -jar ~/snpEff/snpEff.jar \
  eff \
  BDGP6.86 - > \
  ${wd}/dest.${popSet}.${method}.${maf}.${mac}.${version}.ann.vcf


echo "fix header" #this is now fixed in PoolSNP.py
  sed -i '0,/CHROM/{s/AF,Number=1/AF,Number=A/}' ${wd}/dest.${popSet}.${method}.${maf}.${mac}.${version}.ann.vcf
  sed -i '0,/CHROM/{s/AC,Number=1/AC,Number=A/}' ${wd}/dest.${popSet}.${method}.${maf}.${mac}.${version}.ann.vcf
  sed -i '0,/CHROM/{s/AD,Number=1/AD,Number=A/}' ${wd}/dest.${popSet}.${method}.${maf}.${mac}.${version}.ann.vcf
  sed -i '0,/CHROM/{s/FREQ,Number=1/FREQ,Number=A/}' ${wd}/dest.${popSet}.${method}.${maf}.${mac}.${version}.ann.vcf

  bcftools view -h ${wd}/dest.${popSet}.${method}.${maf}.${mac}.${version}.ann.vcf > ${wd}/tmp.header

  bcftools reheader --threads 10 -h ${wd}/tmp.header -o ${wd}/dest.${popSet}.${method}.${maf}.${mac}.${version}.header.bcf ${wd}/dest.${popSet}.${method}.${maf}.${mac}.${version}.bcf

echo "make GDS"
  #Rscript --vanilla ${wd}/DEST/snpCalling/vcf2gds.R ${wd}/dest.${popSet}.${method}.${maf}.${mac}.${version}.ann.vcf

echo "bgzip & tabix"
  bgzip -c ${wd}/dest.${popSet}.${method}.${maf}.${mac}.${version}.ann.vcf > ${wd}/dest.${popSet}.${method}.${maf}.${mac}.${version}.ann.vcf.gz
  tabix -p vcf ${wd}/dest.${popSet}.${method}.${maf}.${mac}.${version}.ann.vcf.gz
