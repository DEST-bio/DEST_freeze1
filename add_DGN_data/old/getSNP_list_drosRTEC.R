### libraries
  library(data.table)
  library(foreach)

### functions
  loadData <- function(obj) {
   ### status
     print(obj)

   ### load data
     load(obj)

   ### return
    dt <- data.table(chr=info$X.CHROM, pos=info$POS)
    return(dt)
 }

### data
  fileList <- system("ls /scratch/aob2x/dest/drosRTEC/mel_freqdp*.Rdata", intern=T)
  dat <- foreach(i=fileList)%do%loadData(i)
  dat <- rbindlist(dat)

  setkey(dat, chr, pos)

### tack in chr
  dat[,chr:=gsub("chr", "", chr)]
  dat[,chr:=paste("chr", chr, sep="")]
  dat[,start:=pos]
  dat[,stop:=pos+1]

### disable scientific notation
  options(scipen = 999)

### export
  write.table(dat[,c("chr", "start", "stop"), with=F], file="/scratch/aob2x/dest/drosRTEC/drosRTEC_sites.dm3.bed",
                          quote=F, row.names=F, col.names=F, sep="\t")
