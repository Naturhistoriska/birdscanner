#!/bin/bash -l

#SBATCH -A snic2017-7-291
#SBATCH -J init_and_plast
#SBATCH -t 00:30:00
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
module load blast/2.7.1+
module load gnuparallel

make -C .. refdata

>&2 echo "did make refdata"

make -C .. init

>&2 echo "did make init"

make -C .. plast

>&2 echo "did make plast"

make -C .. parseplast

>&2 echo "did make parseplast"
>&2 echo "Reached the end of the first slurm script"

