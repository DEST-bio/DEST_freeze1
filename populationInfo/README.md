# Population information & basic figures

## Description
>  This directory contains scripts to generate meta-data file for the DEST dataset. It first pulls together the meta-data files for the drosRTEC, drosEU, and dgn datasets from their respective supplemental data files. Also pulls in ghcnd data.

## File structure set up

## Make meta-data file ###
  > ~~ijob -c1 -p standard -A berglandlab~~
  > RUN: `makeJointSampleInfo.R`
  > Outputs `DEST/populationInfo/samps.csv`

## Make figures
  ## Map figure
  > RUN: `sbatch makeNiceMap.sh`

  python2.7 makeNiceMap.py input.txt > output.txt` <br/>
