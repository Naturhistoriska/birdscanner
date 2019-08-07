#!/bin/bash -l

#SBATCH -A #UPPMAXACCOUNTNR#
#SBATCH -J parseplast
#SBATCH -t 00:10:00
#SBATCH -p core
#SBATCH -n 10
#SBATCH -M snowy,rackham 
#SBATCH --output=/dev/null
#SBATCH --error=parseplast.err

# Slurm script for parseplast
#
# Test by using:
#     sbatch --test-only parseplast.slurm.sh
#
# Start by using:
#     sbatch parseplast.slurm.sh
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

make -C .. parseplast

>&2 echo "Reached the end of the parseplast slurm script"
>&2 echo "Generated files should be in the ../run/plast folder"
>&2 tree -P '*plast*' ../run/plast

