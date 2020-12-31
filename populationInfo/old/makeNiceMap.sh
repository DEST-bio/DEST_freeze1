#!/usr/bin/env bash
#
#SBATCH -J makeNiceMap # A single job name for the array
#SBATCH --ntasks-per-node=1 # one core
#SBATCH -N 1 # on one node
#SBATCH -t 0:00:10 ### 30 minutes
#SBATCH --mem 1G
#SBATCH -o /scratch/aob2x/dest/slurmOutput/makeNiceMap.%A_%a.out # Standard output
#SBATCH -e /scratch/aob2x/dest/slurmOutput/makeNiceMap.%A_%a.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab

module load gcc/5.4.0  openmpi/3.1.4 python/2.7.16 R/3.6.0

wd=/scratch/aob2x/dest

### parse input file
#`input.txt` is tab-delimited with four columns (Lat,Lon,Season[spring,fall,frost,NA] and Year) <br/>

head -n1 ${wd}/DEST/populationInfo/samps.csv | tr ',' '\n' | nl | grep -E "lat|long|season|year" ### 6,7,8,14

cut -f 6,7,8,14 -d',' ${wd}/DEST/populationInfo/samps.csv | sed '1d' | sed '$d' | tr ',' '\t' | grep -v "NA$" > ${wd}/DEST/populationInfo/input.txt

python2.7 ${wd}/DEST/populationInfo/makeNiceMap.py ${wd}/DEST/populationInfo/input.txt > ${wd}/DEST/populationInfo/output.txt

Rscript ${wd}/DEST/populationInfo/makeNiceMap.R
