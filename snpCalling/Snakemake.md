Ensure that the BDGP6.86 is installed.
If not run 
```bash
java -jar snpEff.jar download -v BDGP6.86
```

First run to do a dry run with snakemake. This outputs the jobs which will be submitted, checks that everything snakemake needs for initialization is present, checks for syntax issues, etc.
```bash
snakemake --profile slurm -n
```

Then, if everything looks OK, run:
```bash
snakemake --profile slurm
```