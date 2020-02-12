#!/usr/bin/env perl 
#===============================================================================
=pod


=head2

         FILE: create_nhmmer_slurm_file.pl

        USAGE: ./create_nhmmer_slurm_file.pl -a <account> -g <genome> [-t <time>][-c <cluster>][-n <Ncpus>] > <genome>.nhmmer.slurm.sh
               ./create_nhmmer_slurm_file.pl -a snic201X-X-XX -g PvioviF_genome > PvioviF_genome.nhmmer.slurm.sh


  DESCRIPTION: Generate slurm file for running nhmmer.
               Slurm script can be submitted on uppmax.

      OPTIONS: -a, --account  Uppmax compute account (e.g. 'snic2019-1-1')
               -g, --genome   Genome name (e.g. "CgutgM_genome)
               -t, --time     Max compute time, HH:MM:SS (eg, "40:00:00")
               -c, --cluster  Compute cluster ('rackham' or 'snowy', default: both)
               -s, --stdout   Print to STDOUT instead of file.
               -o, --outfile  Print to outfile
               -p, --path     Default path (cwd) on server (e.g. "/proj/uppstoreXXXX/XXXX")

 REQUIREMENTS: Script will only run if necessary input data are in place.
               See NOTES below.

         BUGS: ---

        NOTES: Note in order for running the script on uppmax,
               you need the files (example):

                   run
                     ├── hmmer/CgutgM_genome.selected_concat.hmm
                     └── plast/CgutgM_genome.plast200.fas
               

       AUTHOR: Johan Nylander (JN), johan.nylander@nrm.se

      COMPANY: NBIS/NRM

      VERSION: 1.0

      CREATED: 04/03/2019 10:34:41 AM

     REVISION: Wed 12 Feb 2020 06:08:11 PM CET

=cut


#===============================================================================

use strict;
use warnings;
use Getopt::Long;

exec("perldoc", $0) unless (@ARGV);

my $account      = '#UPPMAXACCOUNTID#';
my $cluster      = 'rackham,snowy';
my $filesuffix   = '.nhmmer.slurm.sh';
my $genome       = q{};
my $hmmer        = 'hmmer/3.2.1-intel';
my $ncpu         = 10;
my $out          = 1;
my $outfile      = q{};
my $path         = q{};
my $partition    = 'core';
my $standardout  = 0;
my $time         = '40:00:00';
my $slurm_script = q{};
my $PRINT;

GetOptions(
    "account=s"   => \$account,
    "cluster=s"   => \$cluster,
    "genome=s"    => \$genome,
    "ncpu=i"      => \$ncpu,
    "outfile=s"   => \$outfile,
    "path=s"      => \$path,
    "standardout" => \$standardout,
    "time=s"      => \$time,
    "help"        => sub { exec("perldoc", $0); exit(0); },
);

if (!$account) {
    die "Error: Need an uppmax compute account.\n";
}

if ($standardout) {
    $PRINT = *STDOUT;
}
elsif ($outfile) {
    open ($PRINT, '>', $outfile) or die "$0 : Failed to open output file $out : $!\n\n";
}
else {
    $outfile = $genome . $filesuffix;
    open ($PRINT, '>', $outfile) or die "$0 : Failed to open output file $out : $!\n\n";
}

if ($path eq '') {
$slurm_script = <<"END_SLURM";
#!/bin/bash -l

#SBATCH -A $account
#SBATCH -J $genome.nhmmer
#SBATCH -t $time
#SBATCH -p $partition
#SBATCH -n $ncpu
#SBATCH -M $cluster
#SBATCH --output=/dev/null
#SBATCH --error=slurm/$genome.nhmmer.err

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
#     scancel -i -u \$USER
#     scancel --state=pending -u \$USER -M $cluster
#
# Monitor by using:
#    jobinfo -u \$USER -M $cluster
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
cp \${BIRDSCANNERDIR}/run/plast/$genome.plast*.fas \$SNIC_TMP
cd \$SNIC_TMP

nhmmer --notextw --cpu $ncpu \\
    --tblout \${SNIC_TMP}/$genome.nhmmer.out \\
    \${SNIC_TMP}/$genome.selected_concat.hmm \\
    \${SNIC_TMP}/$genome.plast*.fas

# Copy back
cp \${SNIC_TMP}/$genome.nhmmer.out \${BIRDSCANNERDIR}/run/hmmer/.
rm \${SNIC_TMP}/$genome.selected_concat.hmm
rm \${SNIC_TMP}/$genome.plast*.fas

#nhmmer --notextw --cpu $ncpu \\
#    --tblout \${BIRDSCANNERDIR}/run/hmmer/$genome.nhmmer.out \\
#    \${BIRDSCANNERDIR}/run/hmmer/$genome.selected_concat.hmm \\
#    \${BIRDSCANNERDIR}/run/plast/$genome.plast*.fas

>&2 echo "Submitted the $genome.nhmmer slurm script"
>&2 echo "Look for file ../run/hmmer/$genome.nhmmer.out when finished."

END_SLURM

}
else {
$slurm_script = <<"END_SLURM";
#!/bin/bash -l

#SBATCH -A $account
#SBATCH -J $genome.nhmmer
#SBATCH -t $time
#SBATCH -p $partition
#SBATCH -n $ncpu
#SBATCH -M $cluster
#SBATCH --output=/dev/null
#SBATCH --error=slurm/$genome.nhmmer.err

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
#     scancel -i -u \$USER
#     scancel --state=pending -u \$USER -M $cluster
#
# Monitor by using:
#    jobinfo -u \$USER -M $cluster
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
cp $path/run/plast/$genome.plast*.fas \$SNIC_TMP
cd \$SNIC_TMP

nhmmer --notextw --cpu $ncpu \\
    --tblout \$SNIC_TMP/$genome.nhmmer.out \\
    \$SNIC_TMP/$genome.selected_concat.hmm \\
    \$SNIC_TMP/$genome.plast*.fas

# Copy back
cp \$SNIC_TMP/$genome.nhmmer.out $path/run/hmmer/.
rm \$SNIC_TMP/$genome.selected_concat.hmm
rm \$SNIC_TMP/$genome.plast*.fas

#nhmmer --notextw --cpu $ncpu \\
#    --tblout $path/run/hmmer/$genome.nhmmer.out \\
#    $path/run/hmmer/$genome.selected_concat.hmm \\
#    $path/run/plast/$genome.plast*.fas

>&2 echo "Submitted the $genome.nhmmer slurm script"
>&2 echo "Look for file ../run/hmmer/$genome.nhmmer.out when finished."


END_SLURM

}

print $PRINT $slurm_script;

if ($outfile) {
    close($PRINT);
    if ( -e $outfile ) {
        print STDERR "Created file: $outfile\n";
    }
}
