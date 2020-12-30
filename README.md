# DEST
  > Scripts for mapping and quality control of DEST dataset

## Metadata
  > `populationInfo\`: Has supplemental data from the DrosEU, DrosRTEC, and DPGP files to make a unified meta-datafile; attaches GHCND station based on lat. and long.

## PoolSeq mapping pipeline
  > `mappingPipeline\`: Contains dockerized mapping pipeline. Downloads data, produces bam files, filter files, gSYNC files

## Incorporate DGN data
  > `add_DGN_datda\`: Downloads, formats, lifts-over DGN data into gSYNC format

## SNP calling
  > `PoolSNP4Sync\`: SNP calling based on gSYNC files </br>
  > `SNAPE\`: SNP calling based on snape output

## Utility scripts
  > `utility\`: (a) download individual files; (b)
