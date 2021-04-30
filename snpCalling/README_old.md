# Scripts to call SNPs and generate VCF and GDS working files

## Description

This set of scripts provides a pipeline to combine all the outputs from our first pipeline "1.Mapping" in order to call SNPs and subsequently generate working VCF and GDS files. It is important to highlights that our scripts can be used to call SNPs for both our sub-pipelines: the PoolSNP sub-pipeline and the SNAPE-pooled sub-pipeline. 

This script is divided into various sections and users may start it at different point depending on their starting data. For example, users seeking to replicate our results from the DEST paper are advised to execute all steps including those from the precious pipeline. On the other hand, those using the data set on new data may need to modify the code at certain steps.

As before, be advised that this script assumes that the user will run the program on a cluster computer as it takes advantage of array jobs. Nevertheless, the script can be modified to run on a different configuration. 


## Before we start: Download the DEST pipeline
### Define working directory 

```bash
wd=./DEST_freeze1/snpCalling/
```

## Define the fai file corresponding to the reference genome
The file "holo_dmel_6.12.fa.fai" is the fai file generated from indexing the reference genome (in this case the holo-genome) we used to map reads. This is a file of small size which we will provide in the git repo, but can be generated using samtools.

```bash
fai=${wd}/holo_dmel_6.12.fa.fai
```
## Part 1. Generate a master "guide file" for jobs.
This will help paralelize the pipeline, optimizing memory and time. This step requires the fai file as well as running R. Notice that our example shows a very idiosyncratic way to load R. This is probably only applicable to our super computer. Please modify accordingly

```bash
#Loading R in our cluster. Modify to your cluster
module load intel/18.0 intelmpi/18.0
module load goolf/7.1.0_3.1.4
module load gdal proj R/4.0.0

#Running the script
Rscript makeJobs.R \
${wd} \
${fai}
```

## Part 2a. Call SNP and Make files using the PoolSNP sub-pipeline

**READ THIS EVEN IF YOU ARE ONLY RUNNING THE SNAPE SUBPIPE:** The following description applies to both subpipes, PoolSNP and SNAPE-pooled. At this point, we will call SNPs using the script "run_poolsnp.sh". 

**How does this code work?** This code is designed to be run as an array job. This is accomplished by calling the code using sbatch with the --array flag. The size of this array can be determined using the size of the "poolSNP_jobs.csv" file generated in step 1. 

The code takes in 6 arguments: The first paramter is the population set ('all' samples or just the 'PoolSeq' samples). Second parameter is the SNP calling method (PoolSNP or SNAPE). If method == PoolSNP, third parameter is MAF filter, fourth is MAC filter. These are retained for the SNAPE version as "NA" just to keep things consistent (see part 2d). The fifth paramenter is a user defined named which will be attached to all outputs. Lastly, the sixth paramenter is the master guide file, generated above.

```bash
sbatch --array=1-$( wc -l ${wd}/poolSNP_jobs.csv | cut -f1 -d' ' ) \
${wd}/run_poolsnp.sh \
all PoolSNP 001 50 10Mar2021 poolSNP_jobs.csv
```

Running the poolSNP sub-pipeline allows users to explore different paramenters, for example:

```bash
sbatch --array=1-$( wc -l ${wd}/poolSNP_jobs.csv | cut -f1 -d' ' ) \
${wd}/run_poolsnp.sh \
all PoolSNP 001 50 10Nov2020 poolSNP_jobs.csv

sbatch --array=1-$( wc -l ${wd}/poolSNP_jobs.csv | cut -f1 -d' ' ) \
${wd}/run_poolsnp.sh \
PoolSeq PoolSNP 001 50 10Nov2020 poolSNP_jobs.csv
```

## Part 2b. Gather BCF outputs into a unified file

This script collects all the individual bcf files generated above into a single file. The paramenters for this code are the same as above.

```bash
sbatch --array=1-8 \
${wd}/gather_poolsnp.sh \
all PoolSNP 001 50 10Nov2020
```

## Part 2c. Annotate and make final VCF

This script takes the gathered VCF created in 2b and outputs a final VCF. Next, the script implements a program which annotates each SNP in the VCF. This script has a final step which also outputs a GDS file. This is optional, but we recommend this step to people interested in replicating out analyses. 

```bash
sbatch ${wd}/annotate.sh \
all PoolSNP 001 50 10Nov2020
```

## Part 2d. Modify this code for running SNAPE-pooled. 

Here is an example of the code modified for generating VCF/GDS for SNAPE. Notice that many of the parameters needed for PoolSNP are no longer applicable to SNAPE. So these parameters are set as "NA".

```bash
sbatch --array=1-$( wc -l ${wd}/poolSNP_jobs.csv | cut -f1 -d' ' ) \
${wd}/run_poolsnp.sh \
PoolSeq SNAPE NA NA 10Nov2020 poolSNP_jobs.csv

sbatch --array=1-8 \
${wd}/gather_poolsnp.sh \
PoolSeq SNAPE NA NA 10Nov2020

sbatch \
${wd}/annotate.sh \
PoolSeq SNAPE NA NA 10Nov2020
```

The VCF and GDS files generated at this point can be used to replicate the analyses shown in the paper. 

## 3. [OPTIONAL] Parameter evaluation for PoolSNP (global MAC & MAF thresholds)

For users interested in optimizing parameters for PoolSNP, we provide the following example code to evaluate core  PoolSNP parameters using a small subset of the data.

### 3a. Random sample of ~10% of data:
```bash
  shuf -n 100 ${wd}/poolSNP_jobs.csv > ${wd}/poolSNP_jobs.sample.csv
```

### 3b. Run pool_snp
```bash
  module load parallel

  runJob () {
    wd="/scratch/aob2x/dest"
    sbatch --array=1-$( wc -l ${wd}/poolSNP_jobs.sample.csv | cut -f1 -d' ' ) ${wd}/DEST/snpCalling/run_poolsnp.sh all PoolSNP ${1} ${2} paramTest poolSNP_jobs.sample.csv
  }
  export -f runJob

  parallel -j 1 runJob ::: 001 01 05 ::: 5 10 15 20 50 100

```

### 3c. Run gather
```bash
  module load parallel

  runJob () {
    wd="/scratch/aob2x/dest"
    sbatch --array=1-8 ${wd}/DEST/snpCalling/gather_poolsnp.sh all PoolSNP ${1} ${2} paramTest
  }
  export -f runJob

  parallel -j 1 runJob ::: 001 01 05 ::: 5 10 15 20 50 100
```

### 3d. Run annotate
```bash
  module load parallel

  runJob () {
    wd="/scratch/aob2x/dest"
    sbatch ${wd}/DEST/snpCalling/annotate.sh all PoolSNP ${1} ${2} paramTest
  }
  export -f runJob

  parallel -j 1 runJob ::: 001 01 05 ::: 5 10 15 20 50 100
```
