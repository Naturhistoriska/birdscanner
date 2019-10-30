# Files for running on Uppmax

- Last modified: ons okt 30, 2019  12:10
- Sign: JN

## Description

These files can be used to run the birdscanner workflow on uppmax.

Error and some progress printing are written in the `.err` files.

See the `birdscanner/README.md` for detailed instructions.

##  Run order

1. `sbatch refdata_and_init_and_plast.slurm.sh`
2. `sbatch hmmer.slurm.sh`
3. `sbatch parsehmmer.slurm.sh`

## Some handy slurm commands
    
    sbatch --test-only <file>.slurm.sh
    sbatch <file>.slurm.sh
    jobinfo -u $USER -M rackham,snowy
    scancel --state=pending -u $USER -M rackham,snowy

