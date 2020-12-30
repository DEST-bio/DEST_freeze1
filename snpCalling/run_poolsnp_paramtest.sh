#!/usr/bin/env bash
#
#SBATCH -J split_and_run # A single job name for the array
#SBATCH --ntasks-per-node=10 # one core
#SBATCH -N 1 # on one node
#SBATCH -t 5:00:00 ### 15 minutes
#SBATCH --mem 10G
#SBATCH -o /scratch/aob2x/dest/slurmOutput/split_and_run.%A_%a.out # Standard output
#SBATCH -e /scratch/aob2x/dest/slurmOutput/split_and_run.%A_%a.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab

### run as: sbatch --array=1-$( wc -l ${wd}/poolSNP_jobs.sample.csv | cut -f1 -d' ' ) ${wd}/DEST/snpCalling/run_poolsnp_paramtest.sh
### sacct -j 13025604

### sacct -j
###### sbatch --array=1 ${wd}/DEST/snpCalling/run_poolsnp_paramtest.sh
###### sacct -j 13025487
###### ls -l ${outdir}/*.vcf.gz > /scratch/aob2x/failedJobs
####sacct -j 12813152 | head
#### sbatch --array=$( cat /scratch/aob2x/dest/poolSNP_jobs.csv | awk '{print NR"\t"$0}' | grep "2R,15838767,15852539" | cut -f1 ) ${wd}/DEST/snpCalling/run_poolsnp.sh
#### cat /scratch/aob2x/dest/poolSNP_jobs.csv | awk '{print NR"\t"$0}' | grep "2R,21912590,21926361" | cut -f1

module load htslib bcftools parallel intel/18.0 intelmpi/18.0 R/3.6.3 parallel


## working & temp directory
  wd="/scratch/aob2x/dest"
  syncPath1="/project/berglandlab/DEST/dest_mapped/*/*masked.sync.gz"
  syncPath2="/project/berglandlab/DEST/dest_mapped/*/*/*masked.sync.gz"

## get job
  #SLURM_ARRAY_TASK_ID=20
  job=$( cat ${wd}/poolSNP_jobs.sample.csv | sed "${SLURM_ARRAY_TASK_ID}q;d" )
  jobid=$( echo ${job} | sed 's/,/_/g' )
  echo $job

## set up RAM disk
  ## rm /scratch/aob2x/test/*
  #tmpdir="/scratch/aob2x/test"
  #SLURM_JOB_ID=1; SLURM_ARRAY_TASK_ID=4; SLURM_NTASKS_PER_NODE=1
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


    #syncFile=/project/berglandlab/DEST/dest_mapped/extra_pipeline_output/WA_se_14_spring/WA_se_14_spring.masked.sync.gz

    #job=2R,23063908,23202846

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

  parallel -j ${SLURM_NTASKS_PER_NODE} subsection ::: $( ls ${syncPath1} ${syncPath2} | grep -v "SNAPE" | grep -v "joseph_extra_copies" ) ::: ${job} ::: ${tmpdir}


  # ls ${syncPath1} ${syncPath2} | grep -v "SNAPE" | grep -v "joseph_extra_copies"  | wc -l
  # head

### paste function
  echo "paste"
  Rscript --no-save --no-restore ${wd}/DEST/snpCalling/paste.R ${job} ${tmpdir}

  #head ${tmpdir}/allpops.sites | awk '{print NF}'
### run through PoolSNP
  echo "poolsnp"

  runPoolSNP () {
    maf=${1}
    mac=${2}
    tmpdir=${3}
    jobid=${4}
    #maf=01; mac=10
    wd="/scratch/aob2x/dest"
    outdir="/scratch/aob2x/dest/sub_vcfs_paramTest"

    echo ${maf}_${mac}_${tmpdir}

    #cat ${tmpdir}/allpops.names | tr '\n' ',' | sed 's/,$//g'

    cat ${tmpdir}/allpops.sites | python ${wd}/DEST/snpCalling/PoolSnp.py \
    --sync - \
    --min-cov 4 \
    --max-cov 0.95 \
    --min-count ${mac} \
    --min-freq 0.${maf} \
    --miss-frac 0.5 \
    --names $( cat ${tmpdir}/allpops.names | tr '\n' ',' | sed 's/,$//g' )  > ${tmpdir}/${jobid}.${maf}.${mac}.vcf

    echo "compress and clean"
    bgzip -c ${tmpdir}/${jobid}.${maf}.${mac}.vcf > ${outdir}/${jobid}.${maf}.${mac}.paramTest.vcf.gz
    tabix -p vcf ${outdir}/${jobid}.${maf}.${mac}.paramTest.vcf.gz


  }
  export -f runPoolSNP

  parallel -j ${SLURM_NTASKS_PER_NODE} runPoolSNP ::: 001 01 05 ::: 5 10 15 20 50 100 ::: ${tmpdir} ::: ${jobid}
  #parallel -j 1 runPoolSNP ::: 01 ::: 5 ::: ${tmpdir} ::: ${jobid}

### compress and clean up

  #echo "vcf -> bcf "
  #bcftools view -Ou ${tmpdir}/${jobid}.vcf.gz > ${outdir}/${jobid}.bcf

  rm -fr ${tmpdir}

### done
  echo "done"
