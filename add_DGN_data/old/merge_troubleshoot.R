
### ijob -c1 -p standard -A berglandlab
### module load gcc/7.1.0  openmpi/3.1.4 R/3.6.0; R

### libraries
  library(data.table)
  library(foreach)

### load
fl <- list(snpSet="/scratch/aob2x/dest/dest/dgn_drosRTEC_drosEU.sites.dm6.noRep.bed",
        drosRTEC="/scratch/aob2x/dest/drosRTEC/DrosRTEC.sync.new",
        dgn="/scratch/aob2x/dest/dgn/finalSync/dgn.dm6.sync",
        drosEU="/scratch/aob2x/dest/drosEU/2020_jan/DrosEU_dgn_drosRTEC_drosEU.sites.dm6.noRep.sync")

fl <- list(snpSet="/scratch/aob2x/dest/dest/dgn_drosRTEC_drosEU.sites.dm6.noRep.bed",

        drosEU="/scratch/aob2x/dest/drosEU/2020_jan/DrosEU_dgn_drosRTEC_drosEU.sites.dm6.noRep.sync")

o <- foreach(i=fl)%do%{
  #i<-fl[1]
  message(names(i))
  tmp <- as.data.table(fread(i[[1]], select=c(1,2)))
  tmp[,chr:=gsub("chr", "", V1)]
  tmp[,foo := as.numeric(which(i==fl))]
  if(as.numeric(which(i==fl))==4) tmp[,V2:=V2-1]
  setkey(tmp, chr, V2)
  return(tmp)
}
o[[2]][,V2:=V2-1]
### drosRTEC
  setkey(o[[1]], chr, V2)
  setkey(o[[2]], chr, V2)

  rtec <- merge(o[[1]], o[[2]], all=T)
  table(is.na(rtec$foo.x), is.na(rtec$foo.y))

### dgn
  dgn <- merge(o[[1]], o[[3]], all=T)


### droseu
  eu <- merge(o[[1]], o[[4]], all=T)
