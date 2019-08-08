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
module load blast/2.7.1+
module load gnuparallel


## Adjust here the time asked for _per_genome_ in the nhmmer search

make HMMERTIME=40:00:00 -C .. hmmer

echo ""
echo ""
echo "Reached the end of the hmmer slurm script."
echo "nhmmer jobs should now have been submitted to cluster."
echo "Submission details, and any possible errors, are in the hmmer.err file."
echo "Monitor submitted jobs with with the 'jobinfo' command."
echo "When all nhmmer searches are finished, you should see outfiles,"
echo "/run/hmmer/<genome>.nhmmer.out, in the folder birdscanner/run/hmmer."

