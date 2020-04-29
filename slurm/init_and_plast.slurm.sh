#!/bin/bash -l

#SBATCH -A #UPPMAXACCOUNTNR#
#SBATCH -J init_and_plast
#SBATCH -t 01:00:00
#SBATCH -p core
#SBATCH -n 10
#SBATCH -M snowy,rackham 
#SBATCH --output=init_and_plast.out
#SBATCH --error=init_and_plast.err

# Slurm script for first step init_and_plast 
#
# Test by using:
#     sbatch --test-only init_and_plast.slurm.sh
#
# Start by using:
#     sbatch init_and_plast.slurm.sh
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
module load blast/2.9.0+
module load gnuparallel

>&2 echo "1/3: starting init"
make -C .. init
>&2 echo "did make init"

>&2 echo "2/3: starting plast"
make -C .. plast
>&2 echo "did make plast"

>&2 echo "3/3: starting parseplast"
make -C .. parseplast
>&2 echo "did make parseplast"

>&2 echo "Check init_and_plast.out for errors"
>&2 echo "Reached the end of the init_and_plast slurm script"

