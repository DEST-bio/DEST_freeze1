#!/usr/bin/env bash

module purge

module load htslib bcftools intel/18.0 intelmpi/18.0 parallel

popSet=${1}
method=${2}
maf=${3}
mac=${4}
version=${5}
wd=${6}
outdir=$wd/sub_vcfs

chr=$( cat ${wd}/poolSNP_jobs.csv | cut -f1 -d',' | sort | uniq | sed "${SLURM_ARRAY_TASK_ID}q;d" )

echo "Chromosome: $chr"

bcf_outdir="${wd}/sub_bcf"
if [ ! -d $bcf_outdir ]; then
    mkdir $bcf_outdir
fi

echo "grabbing from ${outdir}/*.${popSet}.${method}.${maf}.${mac}.${version}.vcf.gz"
echo "ls output: $(ls ${outdir}/*.${popSet}.${method}.${maf}.${mac}.${version}.vcf.gz)"

echo
echo "Command: ls -d ${outdir}/*.${popSet}.${method}.${maf}.${mac}.${version}.vcf.gz | sort -t"_" -k2,2 -k3g,3  | \
grep /${chr}_"
echo ""

ls -d ${outdir}/*.${popSet}.${method}.${maf}.${mac}.${version}.vcf.gz | sort -t"_" -k2,2 -k3g,3  | \
grep /${chr}_ > $outdir/vcfs_order.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.sort

echo "Concatenating"

bcftools concat \
--threads 20 \
-f $outdir/vcfs_order.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.sort \
-O v \
-n \
-o $bcf_outdir/dest.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.bcf
