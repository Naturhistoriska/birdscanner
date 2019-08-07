#!/bin/bash -l

#SBATCH -A #UPPMAXACCOUNTNR#
#SBATCH -J plast
#SBATCH -t 00:20:00
#SBATCH -p core
#SBATCH -n 10
#SBATCH -M snowy,rackham 
#SBATCH --output=/dev/null
#SBATCH --error=plast.err

# Slurm script for plast
#
# Test by using:
#     sbatch --test-only plast.slurm.sh
#
# Start by using:
#     sbatch plast.slurm.sh
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

make -C .. plast

>&2 echo "Reached the end of the plast slurm script"
>&2 echo "Generated files should be in the ../run/plast folder"
>&2 tree ../run/plast -P *.tab

