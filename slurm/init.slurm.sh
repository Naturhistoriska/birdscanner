#!/bin/bash -l

#SBATCH -A #UPPMAXACCOUNTNR#
#SBATCH -J init
#SBATCH -t 00:10:00
#SBATCH -p core
#SBATCH -n 10
#SBATCH -M snowy,rackham 
#SBATCH --output=/dev/null
#SBATCH --error=init.err

# Slurm script for init
#
# Test by using:
#     sbatch --test-only init.slurm.sh
#
# Start by using:
#     sbatch init.slurm.sh
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

make -C .. init

>&2 echo "Reached the end of the init slurm script"
>&2 echo "Generated files should be in the ../run/plast folder"
>&2 tree ../run/plast

