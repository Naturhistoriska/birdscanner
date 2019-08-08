# Files for running on Uppmax

- Last modified: tor aug 08, 2019  12:03
- Sign: JN

**This document is work in progress!**

## Description

These files can be used to run the birdscanner workflow on uppmax.

See the `birdscanner/README.md` for detailed instructions.

## (Current) Run order

1. `sbatch refdata.slurm.sh`
2. `sbatch init.slurm.sh`
3. `sbatch plast.slurm.sh`
4. `sbatch parseplast.slurm.sh`
5. `sbatch hmmer.slurm.sh`
6. `sbatch parsehmmer.slurm.sh`

