# Scripts to download, map, call polymorphism in pooled sequencing data-sets for Drosophila

## Description
> This set of scripts provides a pipeline to build wholeGenomeSync files for each population sample from raw FASTQ data and defines a Dockerfile to build a docker image which can act as a standalone tool to run the pipeline.

### 0. Define working directory
```bash
wd=/scratch/aob2x/dest
```

### 1. Download data from SRA (specify 72 hour time limit)
```bash
sbatch --array=1-$( wc -l < ${wd}/DEST/populationInfo/samps.csv ) \
${wd}/DEST/mappingPipeline/scripts/downloadSRA.sh
```

### 2. Check that data are in the correct FASTQ format
Double check that all downloaded data are in Fastq33. Uses script from [here](https://github.com/brentp/bio-playground/blob/master/reads-utils/guess-encoding.py). </br>

```bash
sbatch ${wd}/DEST/mappingPipeline/scripts/check_fastq_encoding.sh
grep -v "1.8" ${wd}/fastq/qualEncodings.delim
```

### 3. Build singularity container from docker image
```bash
cd ${wd}
module load singularity
singularity pull docker://jho5ze/dmelsync:hpc
#singularity pull docker://alanbergland/dest_mapping:latest
```

### 4. Run the singularity container across list of populations
```bash
sbatch --array=2-$( cat ${wd}/DEST/populationInfo/samps.csv | cut -f1,14 -d',' | grep -v "NA" | wc -l ) \
${wd}/DEST/mappingPipeline/scripts/runDocker.sh
```
