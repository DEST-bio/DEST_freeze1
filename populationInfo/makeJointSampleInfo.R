### Make joint popInfo file for DEST
### Final data has columsn: sampleId, country, city, collectionDate, lat, long, season, nFlies, locality, type (inbred/pooled), continent


### ijob -c1 -p standard -A berglandlab
### module load intel/18.0 intelmpi/18.0 R/3.6.0; R


### libraries
	library(data.table)
	library(gdata)
	#library(cowplot)
	library(foreach)
	library(ggplot2)
	library(ggmap)
	library(maps)
	library(mapdata)
	library(rnoaa)
	library(sp)
	library(rworldmap)

### set working directory
	setwd("/scratch/aob2x/dest")

### this section loads in the disparate meta-data files and concatenates them.
	### load in DrosEU data
		dat.drosEU <- read.xls("./DEST/populationInfo/DrosEU_allYears_180607.xlsx")

		dat.drosEU.dt <- as.data.table(dat.drosEU[-1,c(2,2,5,6,7,12,13,15,16)])
		setnames(dat.drosEU.dt,
				names(dat.drosEU.dt),
				c("sampleId", "sequenceId", "country", "city", "collectionDate", "lat", "long", "season", "nAutosomes"))
		dat.drosEU.dt[,locality:=paste(tstrsplit(sampleId, "_")[[1]],
									tstrsplit(sampleId, "_")[[2]], sep="_")]
		dat.drosEU.dt[season=="S", season:="spring"]
		dat.drosEU.dt[season=="F", season:="fall"]
		dat.drosEU.dt[,type:="pooled"]
		#dat.drosEU.dt[,collectionDate := as.POSIXct(collectionDate)]
		dat.drosEU.dt[,continent:="Europe"]
		dat.drosEU.dt[,set:="DrosEU"]
		dat.drosEU.dt[,nFlies:=as.numeric(as.character(nAutosomes))/2]
		dat.drosEU.dt[,nAutosomes:=NULL]
		dat.drosEU.dt[,lat:=as.numeric(as.character(lat))]
		dat.drosEU.dt[,long:=as.numeric(as.character(long))]

		### change the spelling of 5 Ukranian samples to correct for differences in spelling
			dat.drosEU.dt[grepl("UA_Cho_14", sampleId), sampleId:=gsub("UA_Cho_14", "UA_Che_14", sampleId)]
			dat.drosEU.dt[grepl("UA_Pyr_14", sampleId), sampleId:=gsub("UA_Pyr_14", "UA_Pir_14", sampleId)]


		### add in SRA accession numbers from separate file
			drosEU.sra <- fread("./DEST/populationInfo/drosEU_SraRunInfo.csv")
			setnames(drosEU.sra, c("LibraryName", "Run", "Experiment"), c("sampleId", "SRA_accession", "SRA_experiment"))

			dat.drosEU.dt <- merge(dat.drosEU.dt, drosEU.sra[,c("sampleId", "SRA_accession", "SRA_experiment"),with=F], by="sampleId", all=T)
			dat.drosEU.dt <- dat.drosEU.dt[!is.na(set)]


	### load in DrosRTEC data
		dat.drosRTEC <- read.xls("./DEST/populationInfo/vcf_popinfo_Oct2018.xlsx")

		dat.drosRTEC.dt <- as.data.table(dat.drosRTEC[,c(1, 4, 10, 8, 13, 11, 12, 7, 17, 4)])
		setnames(dat.drosRTEC.dt,
				names(dat.drosRTEC.dt),
				c("sampleName", "sra_sampleName", "country", "city", "collectionDate", "lat", "long", "season", "nFlies", "locality"))
		dat.drosRTEC.dt[,type:="pooled"]
		#dat.drosRTEC.dt[,collectionDate := as.POSIXct(collectionDate)]
		dat.drosRTEC.dt[long>0,continent:="Europe"]
		dat.drosRTEC.dt[long<0,continent:="NorthAmerica"]
		dat.drosRTEC.dt[,set:="DrosRTEC"]
		dat.drosRTEC.dt[,lat:=as.numeric(as.character(lat))]
		dat.drosRTEC.dt[,long:=as.numeric(as.character(long))]
		dat.drosRTEC.dt[,collectionDate:=gsub("-", "/", collectionDate)]

		### fix issue with SRA_accession numbers for a few Maine populations
			#dat.drosRTEC.dt[sampleId=="ME_bo_09_fall.r1", SRA_accession:="SRX661844"]
			#dat.drosRTEC.dt[sampleId=="ME_bo_09_fall.r2", SRA_accession:="SRR2006283"]
			dat.drosRTEC.dt[sra_sampleName=="mel14TWA7", sra_sampleName:="mel14TWA7_SPT"]

		### add in SRA accession numbers from separate file
			### from two bio-projects:
			### set1: https://www.ncbi.nlm.nih.gov/bioproject/PRJNA256231
			### set2: https://www.ncbi.nlm.nih.gov/bioproject/PRJNA308584
			drosRTEC.sra.1 <- fread("./DEST/populationInfo/drosRTEC_set1_SraRunInfo.txt")
			drosRTEC.sra.2 <- fread("./DEST/populationInfo/drosRTEC_set2_SraRunInfo.txt")

			setnames(drosRTEC.sra.1, c("Sample Name", "Run", "Experiment"), c("sra_sampleName", "SRA_accession", "SRA_experiment"))
			setnames(drosRTEC.sra.2, c("Sample Name", "Run", "Experiment"), c("sra_sampleName", "SRA_accession", "SRA_experiment"))

			drosRTEC.sra.1[SRA_accession=="SRR1525694", sra_sampleName:="FL_rep2"]
			drosRTEC.sra.2 <- drosRTEC.sra.2[!sra_sampleName%in%c("PA_2012_FAT", "VI_2012_FAT", "mel14TWA7")]

			drosRTEC.sra <- rbind(drosRTEC.sra.1[,c("sra_sampleName", "SRA_accession", "SRA_experiment"),with=F],
														drosRTEC.sra.2[,c("sra_sampleName", "SRA_accession", "SRA_experiment"),with=F])

			dat.drosRTEC.dt <- merge(dat.drosRTEC.dt, drosRTEC.sra, by="sra_sampleName", all=T)

			setnames(dat.drosRTEC.dt, "sampleName", "sampleId")

			### strip out duplicate Maine library
				dat.drosRTEC.dt <- dat.drosRTEC.dt[SRA_accession!="SRR2006283"]



	### load in DPGP data
		### first parse Individuals file to select which individuals; modified with population tag
			dpgp.ind <- as.data.table(read.xls("./DEST/populationInfo/TableS1_individuals.xls", skip=5, header=T))
			dpgp.ind <- dpgp.ind[Focal.Genome.Represented=="X,2L,2R,3L,3R"][,c("population", "Stock.ID", "Genome.Type", "Mean.Depth", "Data.Group")]
			setnames(dpgp.ind, "population", "sampleId")

			dpgp.ind[,dgn_set:=paste(sampleId, Data.Group, sep="/")]


			dpgp.pop.use <- dpgp.ind[,list(n=.N), list(sampleId, Data.Group, Genome.Type, dgn_set)][n>=5]

			dpgp.pop.use <- dpgp.pop.use[!dgn_set%in%c("DSPR/DSRP", "FR/DPGP2", "EA/AGES", "EF/AGES", "FR/DPGP2", "SP/DPGP2", "FR_/BERGMAN", "GA_/BERGMAN", "GH/BERGMAN")]

			setkey(dpgp.ind, sampleId, Data.Group)
			setkey(dpgp.pop.use, sampleId, Data.Group)

			dpgp.ind.use <- dpgp.ind[J(dpgp.pop.use)]

			### tack in Simulans
				dpgp.ind.use <- rbind(dpgp.ind.use, data.table(sampleId="SIM", Stock.ID="Simulans", Genome.Type="inbred_line", Mean.Depth=NA, Data.Group="SIM", dgn_set="SIM/SIM", i.Genome.Type="inbred_line", i.dgn_set="SIM/SIM", n=1))


			write.csv(dpgp.ind.use, "./DEST/populationInfo/dpgp.ind.use.csv", quote=F, row.names=F)

		### Get population metadata
		### http://johnpool.net/TableS2_populations.xls
			dat.dpgp <- read.xls("./DEST/populationInfo/TableS2_populations.xls", skip=4)


			dat.dpgp.dt <- as.data.table(dat.dpgp[,c(1,1, 2,3,4,6,7)])
			setnames(dat.dpgp.dt,
					names(dat.dpgp.dt),
					c("sampleId", "sequenceId", "country", "city", "collectionDate", "lat", "long"))

			setkey(dat.dpgp.dt, sampleId)
			setkey(dpgp.ind.use, sampleId)
			dat.dpgp.dt <- merge(dat.dpgp.dt, dpgp.pop.use)

	### get the DPGP populations that are being used in this biuld of the data
	### the script which makes this file is here: DEST/add_DGN_data/pop_chr_maker.sh
		#current.dpgp.pops <- fread("/scratch/aob2x/dest/dgn/pops.delim")
		#current.dpgp.pops <- unique(current.dpgp.pops$V3)

		###these samples need to be dealt with directly.
		#current.dpgp.pops[!sapply(current.dpgp.pops, function(x) x%in%as.character(dat.dpgp.dt$sampleId))]


		#dat.dpgp.dt <- dat.dpgp.dt[sampleId%in%current.dpgp.pops]

		dat.dpgp.dt[,collectionDate := paste(tstrsplit(collectionDate, "/")[[2]], tstrsplit(collectionDate, "/")[[1]], sep="/")]
		dat.dpgp.dt[grepl("NA", collectionDate), collectionDate:=tstrsplit(collectionDate, "/")[[2]]]
		#dat.dpgp.dt[,collectionDate := as.POSIXct(collectionDate)]

		dat.dpgp.dt[sequenceId=="ZI", sequenceId:="dpgp3"]
		dat.dpgp.dt[,season:=NA]
		dat.dpgp.dt[,locality:=sampleId]
		dat.dpgp.dt[,set:="dgn"]

		### tack in simulans
			dat.dpgp.dt <- rbind(dat.dpgp.dt,
								 data.table(sampleId="SIM", sequenceId="SIM", country="w501", city="w501", collectionDate=NA, lat=NA, long=NA, n=1, season=NA, locality="w501", set="dgn", Data.Group="SIMULANS", Genome.Type="inbred_line", dgn_set="SIMULANS/SIM"), fill=T)

		### get continents
			coords2continent = function(points) {
				### thanks Andy! https://stackoverflow.com/questions/21708488/get-country-and-continent-from-longitude-and-latitude-point-in-r/21727515
				countriesSP <- getMap(resolution='low')
				#countriesSP <- getMap(resolution='high') #you could use high res map from rworldxtra if you were concerned about detail

				# converting points to a SpatialPoints object
				# setting CRS directly to that from rworldmap
				pointsSP = SpatialPoints(points, proj4string=CRS(proj4string(countriesSP)))


				# use 'over' to get indices of the Polygons object containing each point
				indices = over(pointsSP, countriesSP)

				#indices$continent   # returns the continent (6 continent model)
				indices$REGION   # returns the continent (7 continent model)
				#indices$ADMIN  #returns country name
				#indices$ISO3 # returns the ISO3 code
			}

			dat.dpgp.dt[,lat:=as.numeric(as.character(lat))]
			dat.dpgp.dt[,long:=as.numeric(as.character(long))]

			dat.dpgp.dt[!is.na(lat), continent:=gsub(" ", "_", as.character(coords2continent(na.omit(as.matrix(dat.dpgp.dt[,c("long", "lat"),with=F])))))]
			dat.dpgp.dt[,SRA_accession:=NA]
			dat.dpgp.dt[,SRA_experiment:=NA]
			setnames(dat.dpgp.dt, "n", "nFlies")
			setnames(dat.dpgp.dt, "Genome.Type", "type")

	### combine,
		columns2use <- c("sampleId", "country", "city", "collectionDate", "lat", "long", "season", "locality", "type", "continent", "set", "nFlies", "SRA_accession", "SRA_experiment")


		samps <- rbindlist(list(dat.drosEU.dt[,columns2use,with=F],
												 		dat.drosRTEC.dt[,columns2use,with=F],
														dat.dpgp.dt[,columns2use,with=F]))


		samps[,year := as.numeric(tstrsplit(collectionDate, "/")[[1]])]

		samps[grepl("[0-9]{4}/[0-9]{2}/[0-9]{2}", collectionDate),yday := yday(as.POSIXct(collectionDate))]
		samps[,nFlies := as.numeric(as.character(nFlies))]

		samps[season=="n", season:=NA]
		samps[,season:=factor(season, levels=c("spring", "fall", "frost"))]

		samps[sampleId=="NC_ra_03_n", collectionDate:="2003"]
		samps[sampleId=="NC_ra_03_n", year:=2003]

	### get GHCND site
		### the problem is that the closest GHCND site to the lat/long does not necessarily have the full climate data for the preceeding year.
		### This is a function to identify the closest station with the most information

		### first, pull the list of statsions
			stations <- ghcnd_stations(refresh=TRUE)
			stations <- as.data.table(stations)

		### function to identify best station to use

			getBestStation <- function(lat, long, year, threshold=2) {
				### i <- which(samps$sampleId=="PA_li_14_spring"); i<-180
				### lat <- samps$lat[i]; long <- samps$long[i]; threshold=3; year=samps$year[i]

				if(!is.na(lat)) {
					stations[,d:=spDistsN1(pts=as.matrix(cbind(longitude, latitude)), pt=c(long, lat), longlat=T)]

					stations.tmp <- stations[first_year<=year & last_year>=year][element%in%c("TMAX", "TMIN")][which.min(abs(d))]

					if(dim(stations.tmp)[1]==1) {
						return(data.table(stationId=stations.tmp$id, dist_km=stations.tmp$d))
					} else {
						return(data.table(stationId=NA, dist_km=NA))
					}
				} else {
					return(data.table(stationId=NA, dist_km=NA))
				}
			}


			o <- foreach(i=1:dim(samps)[1])%dopar%{
				print(i)
				getBestStation(lat=samps[i]$lat, long=samps[i]$long, year=samps[i]$year, threshold=4)

			}
			o <- rbindlist(o)

			samps <- cbind(samps, o)

			### all of the collections (except DGRP & SIM have id)
				table(!is.na(samps$stationId))

			### how far away are these stations? ~80% within 50km; ~95% within 100km
				mean(samps$dist_km<1, na.rm=T)
				mean(samps$dist_km<5, na.rm=T)
				mean(samps$dist_km<10, na.rm=T)
				mean(samps$dist_km<50, na.rm=T)
				mean(samps$dist_km<75, na.rm=T)
				mean(samps$dist_km<100, na.rm=T)

			### the far stations are mostly in Africa
				table(samps$set, samps$dist_km<20)

	### save
		write.csv(samps, "./DEST/populationInfo/samps.csv", quote=F, row.names=F)
