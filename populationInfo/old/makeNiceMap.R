###module load gcc/7.1.0  openmpi/3.1.4 R/3.6.0; R

### libraries
  library(plyr)
  library(ggmap)
  library(ggplot2)

### set working directory
	setwd("/scratch/aob2x/dest")

### load data
  Data=read.table("DEST/populationInfo/output.txt",header=T,na.string="AL")
  DataSum =ddply(Data, c("latitude","longitude","X","Y"), summarise, N=length(latitude))

world=map_data("world")
#shapes=c(15,16,17,18)
shapes=c(18,15,17,16)

pdf("DEST/populationInfo/MapSuggestion2.pdf",width=16,height=10)
P <- ggplot() + geom_polygon(data = world, aes(x=long, y = lat,group=group),fill="grey90",color="black",size=0.2) +
    coord_fixed(1.3) +
    geom_segment(data = DataSum,
               mapping=aes(x=longitude,
                             y=latitude,
                             xend=longitude + X,
                             yend=latitude + Y),
               size=0.5, color="black",
               alpha = 0.9) +
    geom_point(data = DataSum,
              aes(x = longitude+X,
                  y = latitude+Y, size=N))

P+theme_classic()
dev.off()
