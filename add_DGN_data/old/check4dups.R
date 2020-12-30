
### ijob -c1 -p standard -A berglandlab
### module load gcc/7.1.0  openmpi/3.1.4 R/3.6.0; R

library(data.table)

dat <- fread("/scratch/aob2x/dest/dest/dgn_drosRTEC_drosEU.sites.noMerge.noDups.dm6.bed")
setkey(dat, V1, V2)

table(duplicated(dat))

table(dat$V2==(dat$V3-1))
