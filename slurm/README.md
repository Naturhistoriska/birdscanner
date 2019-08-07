# Files for running on Uppmax

- Last modified: fre aug 02, 2019  04:23
- Sign: JN

## Notes

The following steps may be logically distinct (maybe lump steps 1. and 2. ?):

1. `make refdata` -- Will use parallel (with `$(NCPU)`) and pigz. Best run on, say `sbatch -node`

2. `make init`, `make plast`, `make parseplast`, `make slurm` -- Will use `$(NCPU)`. Best run on, say `sbatch -node`.

3. `make nhmmer` -- Will use `$(NCPU)` and are currently run using `sbatch -p core -n 10`.

4. `make parsehmmer` -- Will use `$(NCPU)`. 


