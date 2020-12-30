#!/usr/bin/env bash
#
#SBATCH -J getRef # A single job name for the array
#SBATCH --ntasks-per-node=1 # one core
#SBATCH -N 1 # on one node
#SBATCH -t 0:60:00 ### 30 minutes
#SBATCH --mem 1G
#SBATCH -o /scratch/aob2x/dest/slurmOutput/getRef.%A_%a.out # Standard output
#SBATCH -e /scratch/aob2x/dest/slurmOutput/getRef.%A_%a.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab


### download ref genome

downloadRef() {
  wget \
  -O /scratch/aob2x/dest/referenceGenome/r5/${1}.raw.gz \
  ftp://ftp.flybase.net/genomes/Drosophila_melanogaster/dmel_r5.57_FB2014_03/dna/${1}.raw.gz
}
export -f downloadRef

downloadRef 2L
downloadRef 2R
downloadRef 3L
downloadRef 3R
downloadRef X


### wide to long

w2l_ref () {
	#echo ${1}

	zcat /scratch/aob2x/dest/referenceGenome/r5/${1}.raw.gz | grep -v ">" | sed 's/\(.\)/\1\n/g' | grep -v '^$' > /scratch/aob2x/dest/referenceGenome/r5/${1}.long
}
export -f w2l_ref

w2l_ref 2L
w2l_ref 2R
w2l_ref 3L
w2l_ref 3R
w2l_ref X
