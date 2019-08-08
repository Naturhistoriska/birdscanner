#!/bin/bash -l

#SBATCH -A #UPPMAXACCOUNTNR#
#SBATCH -J parsehmmer
#SBATCH -t 00:30:00
#SBATCH -p core
#SBATCH -n 1
#SBATCH -M snowy 
#SBATCH --output=/dev/null
#SBATCH --error=parsehmmer.err

# Slurm script for hmmer
#
# Test by using:
#     sbatch --test-only parsehmmer.slurm.sh
#
# Start by using:
#     sbatch parsehmmer.slurm.sh
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

make -C .. parsehmmer

>&2 echo "Reached the end of the parsehmmer slurm script"
>&2 echo "Generated files should be in the ../out folder"
>&2 tree ../out

