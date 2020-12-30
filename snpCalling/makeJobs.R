#module load intel/18.0 intelmpi/18.0 R/3.6.3; R


### libraries
  library(data.table)
  library(foreach)

### define working directory where
  wd="/project/berglandlab/DEST"

### get chromosome names and lengths
  chrs="2L|2R|3L|3R|4|X|Y|mitochondrion_genome"

  fai.file="/scratch/aob2x/dest/referenceGenome/r6/holo_dmel_6.12.fa.fai" ## path to hologenome 6.12
  chrLen <- fread(fai.file)

  chrs.dt <- foreach(chr.i=tstrsplit(chrs, "\\|"), .combine="rbind")%do%{
    data.table(chr=chrLen[V1==chr.i[1]]$V1,
               maxLen=chrLen[V1==chr.i[1]]$V2)
  }

### split into how many jobs?
  nJobs <- 999

### how many jobs per chr
  chrs.dt[,nJobs:=floor(maxLen/sum(chrs.dt$maxLen)*nJobs) + 1]

### make jobs
  jobs <- foreach(chr.i=chrs.dt$chr, .combine="rbind", .errorhandling="remove")%do%{
    #chr.i <- chrs.dt$chr[8]
    tmp <- data.table(chr=chr.i,
                      start=floor(seq(from=1, to=chrs.dt[chr==chr.i]$maxLen, length.out=chrs.dt[chr==chr.i]$nJobs)))

    if(dim(tmp)[1]==1) {
      tmp2 <- data.table(chr=chr.i,
                         start=1, stop=chrs.dt[chr==chr.i]$maxLen)
    } else {
      tmp2 <- data.table(chr=chr.i,
                          start=tmp[-length(tmp$start)]$start,
                          stop=tmp[-1]$start - 1 )
    }
    return(tmp2)
  }

### write job file
  write.table(jobs, quote=F, col.names=F, row.names=F, sep=",", file="/scratch/aob2x/dest/poolSNP_jobs.csv")
