# Run slurm scripts

- Last modified: ons aug 07, 2019  02:24
- Sign: JN

## Description

1. Change directory to the `birdscanner/slurm` folder

2. Edit the slurm scripts by adding the appropriate account
        #SBATCH -A xxxx-x-xx

3. Adjust the time for scripts. Allow X hours per genome

4. Submit (manually) the slurm scripts in order:

#### Steps

*Note:* Merge steps 1+2, and 3+4?

1. `sbatch refdata.slurm.sh`

        >&2 echo "Reached the end of the refdata slurm script"
        >&2 echo "Generated files should be in folders:"
        >&2 echo "  ../data/genomes"
        >&2 echo "  ../data/reference/fasta_files"
        >&2 echo "  ../data/reference/selected folders"
        >&2 tree ../data/genomes
        >&2 tree ../data/reference/fasta_files
        >&2 tree ../data/reference/selected

2. `sbatch init.slurm.sh`

        >&2 echo "Reached the end of the init slurm script"
        >&2 echo "Generated files should be in the ../run/plast folder"
        >&2 tree ../run/plast

3. `sbatch plast.slurm.sh`

        >&2 echo "Reached the end of the plast slurm script"
        >&2 echo "Generated files should be in the ../run/plast folder"
        >&2 tree -P '*.tab' ../run/plast

4. `sbatch parseplast.slurm.sh`

        >&2 echo "Reached the end of the parseplast slurm script"
        >&2 echo "Generated files should be in the ../run/plast folder"
        >&2 tree -P '*plast*' ../run/plast

5. `sbatch hmmer.slurm.sh`

        >&2 echo "Reached the end of the nhmmer slurm script"
        >&2 echo "Generated files should be in the ../run/hmmer folder"
        >&2 tree -P '*.nhmmer.out' ../run/hmmer

6. `sbatch parsehmmer.slurm.sh`

        >&2 echo "Reached the end of the parsehmmer slurm script"
        >&2 echo "Generated files should be in the ../out folder"

