# Files for running on Uppmax

- Last modified: tor aug 08, 2019  12:10
- Sign: JN

**This document is work in progress!**

## Description

These files can be used to run the birdscanner workflow on uppmax.

Error and some progress printing are written in the `.err` files.

See the `birdscanner/README.md` for detailed instructions.

## (Current) Run order

1. `sbatch refdata.slurm.sh`
2. `sbatch init.slurm.sh`
3. `sbatch plast.slurm.sh`
4. `sbatch parseplast.slurm.sh`
5. `sbatch hmmer.slurm.sh`
6. `sbatch parsehmmer.slurm.sh`

## Some handy slurm commands
    
    sbatch --test-only <file>.slurm.sh
    sbatch <file>.slurm.sh
    jobinfo -u $USER -M rackham,snowy
    scancel --state=pending -u $USER -M rackham,snowy

