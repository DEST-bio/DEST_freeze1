# Sample information

## Description
>  This directory contains scripts to generate meta-data files for the DEST dataset.

## Sample metadata
  > `DEST_freeze1/populationInfo/makeJointSampleInfo.R` generates several files:
  > 1. `DEST_freeze1/populationInfo/samps.csv` <br> Contains collection information (locality, date, SRA accession, weather station ID, etc). This is Supplemental Table 1 <br>
  > 2. `DEST_freeze1/populationInfo/dest.worldclim.csv` contains WorldClim data for sampling localities

## Library sequencing statistics
  > `DEST_freeze1/populationInfo/sequencingStats/sequencingSummaryStats.R` generates generates data that is part of Figure 3 and is found in Supplemental Table 2 <br>
  > 1. `DEST_freeze1/populationInfo/sequencingStats/rd.csv` Average read depth
  > 2. `DEST_freeze1/populationInfo/sequencingStats/pcr.csv` PCR duplicate rate
  > 3. `DEST_freeze1/populationInfo/sequencingStats/simulans.csv` D. simulans contamination rate
