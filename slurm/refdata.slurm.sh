#!/bin/bash -l

#SBATCH -A #UPPMAXACCOUNTNR#
#SBATCH -J refdata
#SBATCH -t 00:10:00
#SBATCH -p core
#SBATCH -n 10
#SBATCH -M snowy,rackham 
#SBATCH --output=/dev/null
#SBATCH --error=refdata.err

# Slurm script for refdata
#
# Test by using:
#     sbatch --test-only refdata.slurm.sh
#
# Start by using:
#     sbatch refdata.slurm.sh
#
# Stop by using:
#     scancel 1234
#     scancel -i -u $USER
#     scancel --state=pending -u $USER
#
# Monitor by using:
#    jobinfo -u $USER -M snowy,rackham
#    squeue
#

module load bioinfo-tools
module load hmmer/3.2.1-intel
module load blast/2.7.1+
module load gnuparallel

make -C .. refdata

>&2 echo "Reached the end of the refdata slurm script"
>&2 echo "Generated files should be in folders:"
>&2 echo "  ../data/genomes"
>&2 echo "  ../data/reference/fasta_files"
>&2 echo "  ../data/reference/selected folders"
>&2 tree ../data/genomes
>&2 tree ../data/reference/fasta_files
>&2 tree ../data/reference/selected

