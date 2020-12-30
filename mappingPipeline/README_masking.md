## Convert MPILEUP and mask SYNC file

### This is an example script, which is showing how to run the pipeline to convert an mpileup file to sync format and mask positions based on (1) coverage thresholds, (2) proximity to indels and (3) repetitive elements

```bash
cd ~/GitHub/DEST/mappingPipeline/scripts

# at first pickle the reference in FASTA format to avoid excessive RAM memory usage and to speed things up

python PickleRef.py \
--ref testMpileup2Sync/ref.fa.txt \
--output reference

for i in 1 2

do

# convert mpileup to sync file and preserve Indel positions and the coverage distribution as python objects

python Mpileup2Sync.py \
--mpileup testMpileup2Sync/test${i}.txt \
--ref testMpileup2Sync/reference.ref \
--output testMpileup2Sync/out${i}

# create masked sync file and BED file with masked positions

python MaskSYNC.py \
--sync testMpileup2Sync/out${i}.sync.gz \
--output testMpileup2Sync/out${i} \
--indel testMpileup2Sync/out${i}.indel \
--coverage testMpileup2Sync/out${i}.cov \
--mincov 4 \
--maxcov 0.7

done

# combine the two masked sync files

command=paste
for i in testMpileup2Sync/out*_masked.sync.gz; do
command="$command <(gzip -cd $i )"
done
eval $command | cut -f 1-4,8 | gzip > testMpileup2Sync/joined_masked.sync.gz
```
