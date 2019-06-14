#!/usr/bin/env perl 
#===============================================================================
=pod


=head2

         FILE: create_slurm_file.pl

        USAGE: ./create_slurm_file.pl -a <account> -g <genome> [-t <time>][-c <cluster>] > <genome>.nhmmer.slurm.sh
               ./create_slurm_file.pl -a snic2017-7-10 -g PvioviF_genome  > PvioviF_genome.nhmmer.slurm.sh


  DESCRIPTION: Generate slurm file for running nhmmer.
               Slurm script can be submitted on uppmax.

      OPTIONS: -a, --account  Uppmax compute account (e.g. 'snic2019-1-1')
               -g, --genome   Genome name (e.g. "CgutgM_genome)
               -t, --time     Max compute time, HH:MM:SS (eg, "40:00:00")
               -c, --cluster  Compute cluster ('rackham' or 'snowy')
               -s, --stdout   Print to STDOUT instead of file.
               -p, --path     Default path (cwd) on server (e.g. "/proj/uppstore2018005/johan")

 REQUIREMENTS: Script will only run if necessary input data are in place.
               See NOTES below.

         BUGS: ---

        NOTES: Note in order for running the script on uppmax,
               you need the files (example):

                   run
                     ├── hmmer/CgutgM_genome.selected_concat.hmm
                     └── plast/CgutgM_genome.plast200.fas
               
               One method for gathering the relevant files on LOCAL machine
               is to use:

                   cd path_to_birdscanner
                   tar cvzf run4uppmax.tgz \
                       run/plast/*.plast200.fas \
                       run/hmmer/*.selected_concat.hmm

               The file run4uppmax.tgz could then be copied to Uppmax:

                   scp run4uppmax.tgz user@rackham.uppmax.uu.se:.

               To run on Uppmax, one would do

                   ssh user@rackham.uppmax.uu.se
                   tar xvzf run4uppmax.tgz
                   cd run4uppmax
                   for f in hmmer/*.nhmmer.slurm.sh ; do
                       sbatch "$f";
                       sleep 1;
                   done

               When all are done, gather the output (on rackham):

                   cd run4uppmax
                   tar cvzf run4local.tgz hmmer/*.nhmmer.out

               Then copy the run4local.tgz to LOCAL:/path/to/birdscanner/run/
               and extract.

               Note (fre 12 apr 2019 15:31:44): The .nhmmer.out files are large (333 MB per file)!
               Keep on UPPMAX for now?

       AUTHOR: Johan Nylander (JN), johan.nylander@nbis.se

      COMPANY: NBIS/NRM

      VERSION: 1.0

      CREATED: 04/03/2019 10:34:41 AM

     REVISION: fre 14 jun 2019 12:39:38

=cut


#===============================================================================

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;

exec("perldoc", $0) unless (@ARGV);

my $account      = 'snic2017-7-10';
my $cluster      = 'rackham,snowy';
my $filesuffix   = '.nhmmer.slurm.sh';
my $genome       = q{};
my $hmmer        = 'hmmer/3.2.1-intel';
my $ncpu         = 10;
my $out          = 1;
my $outfile      = q{};
my $path         = q{}; #'/proj/uppstore2018005/johan'
my $partition    = 'core';
my $standardout  = 0;
my $time         = '40:00:00';
my $slurm_script = q{};
my $PRINT; # Print file handle. Using the typeglob notation below

GetOptions(
    "account=s"   => \$account,
    "cluster=s"   => \$cluster,
    "genome=s"    => \$genome,
    "ncpu=i"      => \$ncpu,
    "path=s"      => \$path,
    "standardout" => \$standardout,
    "time=s"      => \$time,
    "help"        => sub { exec("perldoc", $0); exit(0); },
);

if (!$account) {
    die "Error: Need an uppmax compute account.\n";
}

if ($standardout) {
    $PRINT = *STDOUT; # Using the typeglob notation in order to use STDOUT as a variable
}
else {
    $outfile = $genome . $filesuffix;
    open ($PRINT, '>', $outfile) or die "$0 : Failed to open output file $out : $!\n\n";
}

if ($path eq '') {
$slurm_script = <<"END_SLURM";
#!/bin/bash -l

#SBATCH -J $genome.nhmmer
#SBATCH -A $account
#SBATCH -t $time
#SBATCH -p $partition
#SBATCH -n $ncpu
#SBATCH --output=/dev/null
#SBATCH --error=$genome.nhmmer.err

# Slurm script for nhmmer.
#
# The slurm script needs to be submitted in
# the run/hmmer dir (the same dir as the script).
#
# Test by using:
#     sbatch --test-only $genome.nhmmer.slurm.sh /path/to/birdscanner
#
# Start by using:
#     sbatch $genome.nhmmer.slurm.sh /path/to/birdscanner
#
# Stop by using:
#     scancel 1234
#     scancel -i -u user
#     scancel --state=pending -u user
#
# Monitor by using:
#    jobinfo -u \$USER
#    squeue
#
# Data required (example):
# ./run/hmmer/$genome.selected_concat.hmm
# ./run/plast/$genome.plast200.fas
#
# File structure:
#    run
#    ├── hmmer/$genome.selected_concat.hmm
#    ├── hmmer/$genome.nhmmer.slurm.sh
#    └── plast/$genome.plast200.fas

module load bioinfo-tools $hmmer

BIRDSCANNERDIR=\$1

if [ -z "\$BIRDSCANNERDIR" ]; then
  echo "Error: Need to provide full path to birdscanner directory as argument to the slurm script."
  exit 1
fi

## Copy files to \$SNIC_TMP
cp \${BIRDSCANNERDIR}/run/hmmer/$genome.selected_concat.hmm \$SNIC_TMP
cp \${BIRDSCANNERDIR}/run/plast/$genome.plast200.fas \$SNIC_TMP
cd \$SNIC_TMP

nhmmer --notextw --cpu $ncpu \\
    --tblout \${SNIC_TMP}/$genome.nhmmer.out \\
    \${SNIC_TMP}/$genome.selected_concat.hmm \\
    \${SNIC_TMP}/$genome.plast200.fas

# Copy back
cp \${SNIC_TMP}/$genome.nhmmer.out \${BIRDSCANNERDIR}/run/hmmer/.
rm \${SNIC_TMP}/$genome.selected_concat.hmm
rm \${SNIC_TMP}/$genome.plast200.fas

#nhmmer --notextw --cpu $ncpu \\
#    --tblout \${BIRDSCANNERDIR}/run/hmmer/$genome.nhmmer.out \\
#    \${BIRDSCANNERDIR}/run/hmmer/$genome.selected_concat.hmm \\
#    \${BIRDSCANNERDIR}/run/plast/$genome.plast200.fas

END_SLURM

}
else {
# Include the following later: '#SBATCH -M $cluster'

$slurm_script = <<"END_SLURM";
#!/bin/bash -l

#SBATCH -J $genome.nhmmer
#SBATCH -A $account
#SBATCH -t $time
#SBATCH -p $partition
#SBATCH -n $ncpu
#SBATCH --output=/dev/null
#SBATCH --error=$genome.nhmmer.err

# Slurm script for nhmmer.
#
# The slurm script needs to be submitted in
# the run/hmmer dir (the same dir as the script).
#
# Test by using:
#     sbatch --test-only $genome.nhmmer.slurm.sh
#
# Start by using:
#     sbatch $genome.nhmmer.slurm.sh
#
# Stop by using:
#     scancel 1234
#     scancel -i -u user
#     scancel --state=pending -u user
#
# Monitor by using:
#    jobinfo -u \$USER
#    squeue
#
# Data required (example):
# ./run/hmmer/$genome.selected_concat.hmm
# ./run/plast/$genome.plast200.fas
#
# File structure:
#    run
#    ├── hmmer/$genome.selected_concat.hmm
#    ├── hmmer/$genome.nhmmer.slurm.sh
#    └── plast/$genome.plast200.fas

module load bioinfo-tools $hmmer

## Copy files to \$SNIC_TMP
cp $path/run/hmmer/$genome.selected_concat.hmm \$SNIC_TMP
cp $path/run/plast/$genome.plast200.fas \$SNIC_TMP
cd \$SNIC_TMP

nhmmer --notextw --cpu $ncpu \\
    --tblout \$SNIC_TMP/$genome.nhmmer.out \\
    \$SNIC_TMP/$genome.selected_concat.hmm \\
    \$SNIC_TMP/$genome.plast200.fas

# Copy back
cp \$SNIC_TMP/$genome.nhmmer.out $path/run/hmmer/.
rm \$SNIC_TMP/$genome.selected_concat.hmm
rm \$SNIC_TMP/$genome.plast200.fas

#nhmmer --notextw --cpu $ncpu \\
#    --tblout $path/run/hmmer/$genome.nhmmer.out \\
#    $path/run/hmmer/$genome.selected_concat.hmm \\
#    $path/run/plast/$genome.plast200.fas

END_SLURM

}

print $PRINT $slurm_script;

if ($outfile) {
    close($PRINT);
    if ( -e $outfile ) {
        print STDERR "Created file: $outfile\n";
    }
}
