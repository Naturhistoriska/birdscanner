#!/bin/bash -l

#SBATCH -A #UPPMAXACCOUNTNR#
#SBATCH -J hmmer
#SBATCH -t 00:10:00
#SBATCH -p core
#SBATCH -n 1
#SBATCH -M rackham,snowy 
#SBATCH --output=hmmer.err

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
module load blast/2.9.0+
module load gnuparallel

## Adjust here the time asked for _per_genome_ in the nhmmer search

>&2 echo "1/1: starting hmmer"
make HMMERTIME=40:00:00 -C .. hmmer

>&2 echo ""
>&2 echo ""
>&2 echo "nhmmer jobs should now have been submitted to cluster."
>&2 echo "Submission details, and any possible errors, are in the hmmer.err file."
>&2 echo "Monitor submitted jobs with with the 'jobinfo' command."
>&2 echo "When all nhmmer searches are finished, you should see outfiles"
>&2 echo "named <genome>.nhmmer.out in folder ../run/hmmer/."
>&2 echo "To monitor, try (from the slurm folder):  wc -l ../run/hmmer/*.nhmmer.out"
>&2 echo "Reached the end of the hmmer slurm script."
