#!/bin/bash -l

#SBATCH -A #UPPMAXACCOUNTNR#
#SBATCH -J refdata_and_init_and_plast
#SBATCH -t 01:00:00
#SBATCH -p core
#SBATCH -n 10
#SBATCH -M snowy,rackham 
#SBATCH --output=refdata_and_init_and_plast.out
#SBATCH --error=refdata_and_init_and_plast.err

# Slurm script for first step refdata_and_init_and_plast 
#
# Test by using:
#     sbatch --test-only refdata_and_init_and_plast.slurm.sh
#
# Start by using:
#     sbatch refdata_and_init_and_plast.slurm.sh
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

make -C .. refdata

>&2 echo "1/4: did make refdata, next is init"

make -C .. init

>&2 echo "2/4: did make init, next is plast"

make -C .. plast

>&2 echo "3/4: did make plast, next is parseplast"

make -C .. parseplast

>&2 echo "4/4: did make parseplast"
>&2 echo "Check refdata_and_init_and_plast.out for errors"
>&2 echo "Reached the end of the refdata_and_init_and_plast slurm script"
