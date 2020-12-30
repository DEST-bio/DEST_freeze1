#!/usr/bin/env bash
#
#SBATCH -J split_and_run # A single job name for the array
#SBATCH --ntasks-per-node=1 # one core
#SBATCH -N 1 # on one node
#SBATCH -t 2:00:00 ### most jobs should run in 60 minutes or less; the mitochondria takes a lot longer to run through pool-snp
#SBATCH --mem 10G
#SBATCH -o /scratch/aob2x/dest/slurmOutput/split_and_run.%A_%a.out # Standard output
#SBATCH -e /scratch/aob2x/dest/slurmOutput/split_and_run.%A_%a.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab

### run as: sbatch --array=1-$( wc -l ${wd}/poolSNP_jobs.csv | cut -f1 -d' ' ) ${wd}/DEST/snpCalling/run_poolsnp.sh
### sacct -j
###### sbatch --array=100 ${wd}/DEST/snpCalling/run_poolsnp.sh 001 10
###### sacct -j 13135642
###### ls -l ${outdir}/*.vcf.gz > /scratch/aob2x/failedJobs
####sacct -j 12813152 | head
#### sbatch --array=$( cat /scratch/aob2x/dest/poolSNP_jobs.csv | awk '{print NR"\t"$0}' | grep "2R,15838767,15852539" | cut -f1 ) ${wd}/DEST/snpCalling/run_poolsnp.sh
#### cat /scratch/aob2x/dest/poolSNP_jobs.csv | awk '{print NR"\t"$0}' | grep "2R,21912590,21926361" | cut -f1

module load htslib bcftools parallel intel/18.0 intelmpi/18.0 mvapich2/2.3.1 R/3.6.3 python/3.6.6 vcftools/0.1.16
#module spider python/3.7.7

##

## working & temp directory
  wd="/scratch/aob2x/dest"
  outdir="/scratch/aob2x/dest/sub_vcfs"
  popSet=${1}
  method=${2}
  maf=${3}
  mac=${4}
  version=${5}
  jobs=${6}
  #maf=01; mac=50; popSet="all"; method="PoolSNP"; version="paramTest"; jobs=poolSNP_jobs.sample.csv

## get list of SNYC files based on popSet & method
### full list
  syncPath1orig="/project/berglandlab/DEST/dest_mapped/*/*masked.sync.gz"
  syncPath2orig="/project/berglandlab/DEST/dest_mapped/*/*/*masked.sync.gz"

### target pops
  if [[ "${popSet}" == "PoolSeq" ]]; then
    syncPath1=""
    syncPath2=${syncPath2orig}
  elif [[ "${popSet}" == "all" ]]; then
    syncPath1=${syncPath1orig}
    syncPath2=${syncPath2orig}
  fi

## get job
  #SLURM_ARRAY_TASK_ID=2
  job=$( cat ${wd}/${jobs} | sed "${SLURM_ARRAY_TASK_ID}q;d" )
  jobid=$( echo ${job} | sed 's/,/_/g' )
  echo $job

## set up RAM disk
  ## rm /scratch/aob2x/test/*
  #tmpdir="/scratch/aob2x/test"
  #SLURM_JOB_ID=1
  [ ! -d /dev/shm/$USER/ ] && mkdir /dev/shm/$USER/
  [ ! -d /dev/shm/$USER/${SLURM_JOB_ID} ] && mkdir /dev/shm/$USER/${SLURM_JOB_ID}
  [ ! -d /dev/shm/$USER/${SLURM_JOB_ID}/${SLURM_ARRAY_TASK_ID} ] && mkdir /dev/shm/$USER/${SLURM_JOB_ID}/${SLURM_ARRAY_TASK_ID}

  tmpdir=/dev/shm/$USER/${SLURM_JOB_ID}/${SLURM_ARRAY_TASK_ID}

## get sub section
  subsection () {
    syncFile=${1}
    job=${2}
    jobid=$( echo ${job} | sed 's/,/_/g' )
    tmpdir=${3}

    pop=$( echo ${syncFile} | rev | cut -f1 -d'/' | rev | sed 's/.masked.sync.gz//g' )


    #syncFile=/project/berglandlab/DEST/dest_mapped/GA/GA.masked.sync.gz

    #job=2L,1,13766
    #job=mitochondrion_genome,1,19524

    chr=$( echo $job | cut -f1 -d',' )
    start=$( echo $job | cut -f2 -d',' )
    stop=$( echo $job | cut -f3 -d',' )

    echo ${pop}_${jobid}

    tabix -b 2 -s 1 -e 2 \
    ${syncFile} \
    ${chr}:${start}-${stop} > ${tmpdir}/${pop}_${jobid}

  }
  export -f subsection

  echo "subset"
  # syncPath1=/project/berglandlab/DEST/dest_mapped/GA/GA.masked.sync.gz; syncPath2=/project/berglandlab/DEST/dest_mapped/pipeline_output/UK_Mar_14_12/UK_Mar_14_12.masked.sync.gz

  if [[ "${method}" == "SNAPE" ]]; then
    echo "SNAPE" ${method}
    parallel -j 1 subsection ::: $( ls ${syncPath1} ${syncPath2} | grep "SNAPE" | grep "monomorphic" ) ::: ${job} ::: ${tmpdir}
  elif [[ "${method}" == "PoolSNP" ]]; then
    echo "PoolSNP" ${method}
    parallel -j 1 subsection ::: $( ls ${syncPath1} ${syncPath2} | grep -v "SNAPE" ) ::: ${job} ::: ${tmpdir}
  fi

### paste function
  echo "paste"
  #find ${tmpdir} -size  0 -print -delete
  Rscript --no-save --no-restore ${wd}/DEST/snpCalling/paste.R ${job} ${tmpdir} ${method}

### run through PoolSNP
  echo "poolsnp"

  if [[ "${method}" == "SNAPE" ]]; then
    echo $method
    cat ${tmpdir}/allpops.${method}.sites | python ${wd}/DEST/snpCalling/PoolSnp.py \
    --sync - \
    --min-cov 4 \
    --max-cov 0.95 \
    --miss-frac 0.5 \
    --min-count 0 \
    --min-freq 0 \
    --posterior-prob 0.9 \
    --SNAPE \
    --names $( cat ${tmpdir}/allpops.${method}.names |  tr '\n' ',' | sed 's/,$//g' )  > ${tmpdir}/${jobid}.${popSet}.${method}.${maf}.${mac}.${version}.vcf

  elif [[ "${method}"=="PoolSNP" ]]; then
    echo $method

    cat ${tmpdir}/allpops.${method}.sites | python ${wd}/DEST/snpCalling/PoolSnp.py \
    --sync - \
    --min-cov 4 \
    --max-cov 0.95 \
    --min-count ${mac} \
    --min-freq 0.${maf} \
    --miss-frac 0.5 \
    --names $( cat ${tmpdir}/allpops.${method}.names |  tr '\n' ',' | sed 's/,$//g' )  > ${tmpdir}/${jobid}.${popSet}.${method}.${maf}.${mac}.${version}.vcf
  fi

### compress and clean up
  echo "compress and clean"

  cat ${tmpdir}/${jobid}.${popSet}.${method}.${maf}.${mac}.${version}.vcf | vcf-sort | bgzip -c > ${outdir}/${jobid}.${popSet}.${method}.${maf}.${mac}.${version}.vcf.gz
  tabix -p vcf ${outdir}/${jobid}.${popSet}.${method}.${maf}.${mac}.${version}.vcf.gz

  #cp ${tmpdir}/allpops* ${outdir}/.

  #echo "vcf -> bcf "
  #bcftools view -Ou ${tmpdir}/${jobid}.vcf.gz > ${outdir}/${jobid}.bcf

  rm -fr ${tmpdir}

### done
  echo "done"
