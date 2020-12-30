# Scripts to call polymorphic sites using PoolSNP and SNAPE.

## Description
> This set of scripts generates VCF files from whole-genome SYNC files using one of two SNP calling pipelines.

### 0. Define working directory
```bash
wd=/scratch/aob2x/dest
```

### 1. Generate job id file
```bash
Rscript ${wd}/DEST/snpCalling/makeJobs.R
```

### 2a. Make PoolSNP based VCF file (bgzip out). Uses MAF > 0.001 & MAC > 50. These are reasonable thresholds that produce consistent pn/ps, number of SNPs, et, but can be filtered at a later stage using standard VCF tools. </br>
First paramter is the population set ('all' samples or just the 'PoolSeq' samples). Second parameter is the SNP calling method (PoolSNP or SNAPE). If method == PoolSNP, third parameter is MAF filter, fourth is MAC filter. These are retained for the SNAPE version just to keep things consistent.

```bash
sbatch --array=1-$( wc -l ${wd}/poolSNP_jobs.csv | cut -f1 -d' ' ) ${wd}/DEST/snpCalling/run_poolsnp.sh all PoolSNP 001 50 10Nov2020 poolSNP_jobs.csv
sbatch --array=1-$( wc -l ${wd}/poolSNP_jobs.csv | cut -f1 -d' ' ) ${wd}/DEST/snpCalling/run_poolsnp.sh PoolSeq PoolSNP 001 50 10Nov2020 poolSNP_jobs.csv
sbatch --array=1-$( wc -l ${wd}/poolSNP_jobs.csv | cut -f1 -d' ' ) ${wd}/DEST/snpCalling/run_poolsnp.sh PoolSeq SNAPE NA NA 10Nov2020 poolSNP_jobs.csv
```

### 2b. Collect PoolSNP (bcf out)
```bash
sbatch --array=1-8 ${wd}/DEST/snpCalling/gather_poolsnp.sh all PoolSNP 001 50 10Nov2020
sbatch --array=1-8 ${wd}/DEST/snpCalling/gather_poolsnp.sh PoolSeq PoolSNP 001 50 10Nov2020
sbatch --array=1-8 ${wd}/DEST/snpCalling/gather_poolsnp.sh PoolSeq SNAPE NA NA 10Nov2020
```


### 2c. Bind chromosomes, annotate and convert (bgzip out; GDS out)
```bash
sbatch ${wd}/DEST/snpCalling/annotate.sh all PoolSNP 001 50 10Nov2020
sbatch ${wd}/DEST/snpCalling/annotate.sh PoolSeq PoolSNP 001 50 10Nov2020
sbatch ${wd}/DEST/snpCalling/annotate.sh PoolSeq SNAPE NA NA 10Nov2020
```



## 3. Parameter evaluation for PoolSNP (global MAC & MAF thresholds)
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
cp /scratch/aob2x/dest/dest*paramTest*.ann.vcf.gz /project/berglandlab/DEST/paramTest/.
