# #!/bin/bash

module purge
module load gcc/7.1.0  openmpi/3.1.4 intel/18.0  intelmpi/18.0 R/3.6.3
Rscript makeJobs.R $1 $2
