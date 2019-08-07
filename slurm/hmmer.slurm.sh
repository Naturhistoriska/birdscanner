#!/bin/bash -l

#SBATCH -A #UPPMAXACCOUNTNR#
#SBATCH -J hmmer
#SBATCH -t 00:05:00
#SBATCH -p core
#SBATCH -n 1
#SBATCH -M rackham,snowy 
#SBATCH --output=/dev/null
#SBATCH --error=hmmer.err

# Slurm script for hmmer
#
# Test by using:
#     sbatch --test-only hmmer.slurm.sh
#
# Start by using:
#     sbatch hmmer.slurm.sh
#
# Stop by using:
#     scancel 1234
#     scancel -i -u $USER
#     scancel --state=pending -u $USER
#
# Monitor by using:
#    jobinfo -u $USER -M snowy,rackham
#    sinfo -p devel
#    squeue
#

module load bioinfo-tools
module load hmmer/3.2.1-intel
module load blast/2.7.1+
module load gnuparallel

make -C .. hmmer

>&2 echo "Reached the end of the hmmer slurm script"
>&2 echo "Generated files should be in the ../run/hmmer folder"
>&2 tree -P '*.nhmmer.out' ../run/hmmer


