#!/bin/bash

#####################
### download data ###
#####################

nohup wget http://pooldata.genetics.wisc.edu/dpgp2_sequences.tar.bz2 &
#nohup wget http://pooldata.genetics.wisc.edu/dpgp3_sequences.tar.bz2 &


####################
### wide to long ###
####################

w2l () {
	echo ${1}

	sed 's/\(.\)/\1\n/g' ${1} > ${1}.long
}
export -f w2l

#nohup parallel --gnu -j1 w2l ::: $( ls /mnt/spicy_2/dest/african/dpgp3_sequences_temp/*.seq ) &
#nohup parallel --gnu -j1 w2l ::: $( ls /mnt/spicy_2/dest/african/dpgp2_sequences_temp/CO*.seq ) &
nohup parallel --gnu -j1 w2l ::: $( ls /mnt/spicy_2/dest/african/dpgp2_sequences_temp/+(GA|GU|NG)*.seq ) &

############################
### paste per chromosome ###
############################

paste_per_chr () {
	paste -d','  ${2}/${3}*${1}*long > \
	${2}/${3}_${1}.csv
}
export -f paste_per_chr

#nohup parallel --gnu -j1 paste_per_chr ::: 2L 2R 3L 3R X ::: /mnt/spicy_2/dest/african/dpgp3_sequences_temp ::: dpgp3 &
nohup parallel --gnu -j1 paste_per_chr ::: 2L 2R 3L 3R X ::: /mnt/spicy_2/dest/african/dpgp2_sequences_temp ::: CO GA GU NG &




################################
### tack in reference genome ###
################################

w2l_ref () {
	#echo ${1}

	grep -v ">" ${1} | sed 's/\(.\)/\1\n/g' | grep -v '^$' > ${1}.long
}
export -f w2l_ref


#parallel --gnu -j1 w2l_ref ::: /mnt/spicy_2/dest/reference/chr2L.fa /mnt/spicy_2/dest/reference/chr2R.fa /mnt/spicy_2/dest/reference/chr3L.fa /mnt/spicy_2/dest/reference/chr3R.fa /mnt/spicy_2/dest/reference/chrX.fa


##########################
### csv to sync format ###
##########################

csv2sync () {


fn=${1}
#chr=$( echo ${fn} | rev | cut -f1 -d'/' | rev | sed 's/dpgp3_//g' | sed 's/.csv//g' )
chr=$( echo ${fn} | grep -oE '_2L|_2R|_3L|_3R|_X' | sed 's/_//g' )

paste -d' ' /mnt/spicy_2/dest/reference/chr${chr}.fa.long ${fn} | awk -F' ' -v chr=${chr} '
{
nN=gsub(/N/,"",$2)"\t"
nA=gsub(/A/,"",$2)"\t"
nC=gsub(/C/,"",$2)"\t"
nT=gsub(/T/,"",$2)"\t"
nG=gsub(/G/,"",$2)"\t"

nObs=nA+nC+nT+nG

if(nObs>0) {
if((nA/nObs > 0 && nA/nObs < 1) || (nC/nObs > 0 && nC/nObs < 1) || (nT/nObs > 0 && nT/nObs < 1) || (nG/nObs > 0 && nG/nObs<1)) {
print chr"\t"NR"\t"toupper($1)"\t"nN"\t"nA"\t"nC"\t"nT"\t"nG
}
}
}' > ${1}.sync
}
export -f csv2sync

#nohup parallel --gnu -j1 csv2sync ::: $( ls /mnt/spicy_2/dest/african/dpgp3_sequences_temp/dpgp3_*.csv ) &
nohup parallel --gnu -j1 csv2sync ::: $( ls /mnt/spicy_2/dest/african/dpgp2_sequences_temp/*.csv ) &



#################################################
### find union of lists, output as bed format ###
#################################################

	#mkdir /mnt/spicy_2/dest/african/dpgp_sites

	union_bed () {
		chr=${1}
		dir=${2}

		cat ${dir}/*${chr}*.sync | cut -f2 | sort | uniq | sort -k1,1n | awk -v chr=${chr} '{print "chr"chr"\t"$0"\t"$0+1}' > /mnt/spicy_2/dest/african/dpgp_sites/dpgp_${chr}.bed
	}
	export -f union_bed


	parallel --gnu -j1 union_bed ::: 2L 2R 3L 3R X ::: /mnt/spicy_2/dest/african/+(dpgp2|dpgp3)_sequences_temp


#######################
### liftover to dm6 ###
#######################

	doLiftover () {

		/mnt/spicy_1/sin/liftOver \
		${2}/dpgp_${1}.bed \
		/mnt/spicy_1/sin/dm3ToDm6.over.chain \
		${2}/dpgp_${1}.dm6.bed \
		${2}/dpgp_${1}.dm6.unmapped.bed
	}
	export -f doLiftover

	parallel --gnu -j1 doLiftover ::: 2L 2R 3L 3R X ::: /mnt/spicy_2/dest/african/dpgp_sites

##########################################
### concatenate and join wiht drosRTEC ###
##########################################

	cat /mnt/spicy_2/dest/african/dpgp_sites/dpgp*.dm6.bed | cut -f1,2 | sed 's/\t/_/g' > /mnt/spicy_2/dest/african/dpgp_sites/dpgp.dm6.list

	sed 's/\t/_/g' /mnt/spicy_2/dest/drosRTEC_sites.dm6.delim > /mnt/spicy_2/dest/drosRTEC_sites.dm6.list

	cat /mnt/spicy_2/dest/african/dpgp_sites/dpgp.dm6.list /mnt/spicy_2/dest/drosRTEC_sites.dm6.list | sort | uniq | sed 's/_/\t/' | sort -k2,2n -k1,1g  > /mnt/spicy_2/dest/drosRTEC.dpgp.sites.delim

	#### in R
	Rscript - <<EOF
	#!/usr/bin/env Rscript

	library(data.table)
	dat <- fread("drosRTEC.dpgp.sites.delim", header=F)
	setkey(dat, V1)

	dat <- dat[!J("chrUn")]

	write.table(dat, quote=F, row.names=F, col.names=F, file="drosRTEC.dpgp.sites.sort.delim")
	EOF

##############################################################################
##############################################################################
### use DrosEU, DrosRTEC, DPGP merged sites to re-call SNPs in SYNC format ###
##############################################################################
##############################################################################


###############################
### liftover back to dm3/R5 ###
###############################

# wget http://hgdownload.soe.ucsc.edu/goldenPath/dm6/liftOver/dm6ToDm3.over.chain.gz




cat /mnt/spicy_2/dest/pipeline/drosRTEC_DrosEU_DGRP_SNPs_filtered.pos | awk '{print "chr"$1"\t"$2"\t"$2+1"\tdm6_chr"$1":"$2"-"$2}' > \
/mnt/spicy_2/dest/drosRTEC_DrosEU_DGRP_SNPs_filtered.pos.dm6.bed

/mnt/spicy_1/sin/liftOver \
/mnt/spicy_2/dest/drosRTEC_DrosEU_DGRP_SNPs_filtered.pos.dm6.bed \
/mnt/spicy_2/dest/dm6ToDm3.over.chain \
/mnt/spicy_2/dest/drosRTEC_DrosEU_DGRP_SNPs_filtered.pos.dm3.bed \
/mnt/spicy_2/dest/drosRTEC_DrosEU_DGRP_SNPs_filtered.pos.dm6.unmapped.bed


cat /mnt/spicy_2/dest/drosRTEC_DrosEU_DGRP_SNPs_filtered.pos.dm3.bed | \
sed 's/chr//g' | awk '{print $1"_"$2"\t"$1"\t"$2"\t"$4}' | sort -k 1b,1 > \
/mnt/spicy_2/dest/drosRTEC_DrosEU_DGRP_SNPs_filtered.pos.dm3.bed.sort



#################################################################
### generate long, genome-wide SYNC file of dpgp pops. ##########
### This'll be intersected later on with the delim file above ###
#################################################################

csv2sync_long () {


fn=${1}
#chr=$( echo ${fn} | rev | cut -f1 -d'/' | rev | sed 's/dpgp3_//g' | sed 's/.csv//g' )
chr=$( echo ${fn} | grep -oE '_2L|_2R|_3L|_3R|_X' | sed 's/_//g' )

paste -d' ' /mnt/spicy_2/dest/reference/chr${chr}.fa.long ${fn} | awk -F' ' -v chr=${chr} '
{
nN=gsub(/N/,"",$2)
nA=gsub(/A/,"",$2)
nC=gsub(/C/,"",$2)
nT=gsub(/T/,"",$2)
nG=gsub(/G/,"",$2)

nObs=nA+nC+nT+nG

print chr"_"NR"\t"chr"\t"NR"\t"toupper($1)"\t"nA":"nC":"nT":"nG":"nN":0"
}' | sort -k1b,1 > ${1}.long.sync.sort
}
export -f csv2sync_long

nohup parallel --gnu -j1 csv2sync_long ::: $( ls /mnt/spicy_2/dest/african/dpgp3_sequences_temp/dpgp3_*.csv ) &
nohup parallel --gnu -j1 csv2sync_long ::: $( ls /mnt/spicy_2/dest/african/dpgp2_sequences_temp/*.csv ) &


### split SNP file per chromosome
cat /mnt/spicy_2/dest/drosRTEC_DrosEU_DGRP_SNPs_filtered.pos.dm3.bed.sort | awk '{ print $0 > "/mnt/spicy_2/dest/drosRTEC_DrosEU_DGRP_SNPs_filtered.pos.dm3.bed.sort."$2 }'


### merge

mergeFun () {

targetChr=$( echo ${1} | rev | cut -d'/' -f1 | rev | cut -d'_' -f2 | cut -d'.' -f1)


join -a1 \
/mnt/spicy_2/dest/drosRTEC_DrosEU_DGRP_SNPs_filtered.pos.dm3.bed.sort.${targetChr} \
${1} |
cut -f4,7,8 -d' ' | awk -F' ' '{
split($1, sp, "-")
split(sp[1], sp2, ":")
split(sp2[1], sp3, "_")
print sp3[2]" "sp2[2]" "$2" "$3
}' | sort -k1,1b -k2,2g > ${1}.dm6.use

}
export -f mergeFun

#nohup parallel --gnu -j1 mergeFun ::: $( ls /mnt/spicy_2/dest/african/dpgp3_sequences_temp/dpgp3_*.csv.long.sync.sort ) &
#nohup parallel --gnu -j1 mergeFun ::: $( ls /mnt/spicy_2/dest/african/dpgp2_sequences_temp/*.csv.long.sync.sort ) &



#### paste
paste -d' ' /mnt/spicy_2/dest/african/+(dpgp2|dpgp3)_sequences_temp/*2L*dm6.use | cut -d' ' -f1,2,3,4,8,12,16,20 > /mnt/spicy_2/dest/african/dpgp_2L.sync
paste -d' ' /mnt/spicy_2/dest/african/+(dpgp2|dpgp3)_sequences_temp/*2R*dm6.use | cut -d' ' -f1,2,3,4,8,12,16,20 > /mnt/spicy_2/dest/african/dpgp_2R.sync
paste -d' ' /mnt/spicy_2/dest/african/+(dpgp2|dpgp3)_sequences_temp/*3L*dm6.use | cut -d' ' -f1,2,3,4,8,12,16,20 > /mnt/spicy_2/dest/african/dpgp_3L.sync
paste -d' ' /mnt/spicy_2/dest/african/+(dpgp2|dpgp3)_sequences_temp/*3R*dm6.use | cut -d' ' -f1,2,3,4,8,12,16,20 > /mnt/spicy_2/dest/african/dpgp_3R.sync
paste -d' ' /mnt/spicy_2/dest/african/+(dpgp2|dpgp3)_sequences_temp/*X*dm6.use | cut -d' ' -f1,2,3,4,8,12,16,20 > /mnt/spicy_2/dest/african/dpgp_X.sync

	#### NOTE: There is an error in these lines. dpgp3 is being dropped. I am leaving for posterity.....
	#paste -d' ' /mnt/spicy_2/dest/african/+(dpgp2|dpgp3)_sequences_temp/*2L*dm6.use | cut -d' ' -f1,2,3,4,8,12,16 > /mnt/spicy_2/dest/african/dpgp_2L.sync
	#paste -d' ' /mnt/spicy_2/dest/african/+(dpgp2|dpgp3)_sequences_temp/*2R*dm6.use | cut -d' ' -f1,2,3,4,8,12,16 > /mnt/spicy_2/dest/african/dpgp_2R.sync
	#paste -d' ' /mnt/spicy_2/dest/african/+(dpgp2|dpgp3)_sequences_temp/*3L*dm6.use | cut -d' ' -f1,2,3,4,8,12,16 > /mnt/spicy_2/dest/african/dpgp_3L.sync
	#paste -d' ' /mnt/spicy_2/dest/african/+(dpgp2|dpgp3)_sequences_temp/*3R*dm6.use | cut -d' ' -f1,2,3,4,8,12,16 > /mnt/spicy_2/dest/african/dpgp_3R.sync
	#paste -d' ' /mnt/spicy_2/dest/african/+(dpgp2|dpgp3)_sequences_temp/*X*dm6.use | cut -d' ' -f1,2,3,4,8,12,16 > /mnt/spicy_2/dest/african/dpgp_X.sync

#### concatenate
cat /mnt/spicy_2/dest/african/*sync | sort -k1,1b -k2,2g | gzip - > /mnt/spicy_2/dest/DPGP.sync.gz

### make metadata file
ls /mnt/spicy_2/dest/african/+(dpgp2|dpgp3)_sequences_temp/*2L*dm6.use | rev | cut -f1 -d'/' | rev | cut -f1 -d'_' | awk '{print NR"\t"$0}' > /mnt/spicy_2/dest/DPGP.sync.meta
