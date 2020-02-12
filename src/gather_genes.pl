#!/usr/bin/env perl 
#===============================================================================
=pod


=head2

         FILE: gather_genes.pl

        USAGE: ./gather_genes.pl --outdir=out  inputfolders
               ./gather_genes.pl --outdir=genes $(find out -mindepth 1 -type d)

  DESCRIPTION: Gather genes from parsed nhmmer output. The script takes
               folder names as input, where it expects fasta files named
               <genomename>.<geneid>.fas (e.g. AbucgeM.12236.fas).
               The script will then gather the same geneid from all
               genomes and concatenate them to files named <geneid>.fas.
               These files are written in the current working directory,
               unless --outdir option is used.

      OPTIONS: -o, --outdir=<dir>  Output directory (created if not present).

 REQUIREMENTS: ---

         BUGS: ---

        NOTES: ---

       AUTHOR: Johan Nylander (JN), johan.nylander@nbis.se

      COMPANY: NBIS/NRM

      VERSION: 1.0

      CREATED: 2019-04-12 16:12:21

     REVISION: Wed 12 Feb 2020 06:09:47 PM CET

=cut


#===============================================================================

use strict;
use warnings;
use Getopt::Long;
use File::Basename;

exec("perldoc", $0) unless (@ARGV);

my $outdir = q{};
my $VERBOSE = 0;

GetOptions(
    "outdir=s" => \$outdir,
    "verbose!" => \$VERBOSE,
    "help"     => sub { exec("perldoc", $0); exit(0); },
);

if ($outdir) {
    if (! -d $outdir) {
        print "Creating directory $outdir.\n" if $VERBOSE;
        unless (mkdir $outdir) {
            die "Unable to create $outdir\n";
        }
    }
    else {
        print "Adding files to directory $outdir.\n" if $VERBOSE;

    }
}

my %gene_file_hash = ();

while (my $dir = shift(@ARGV)) {
    if ( ! -d $dir ) {
        die "Can not find directory $dir: $!\n";
    }
    my @fasta_files = <$dir/*.fas>;
    foreach my $filename (@fasta_files) {
        my ($name,$path,$suffix) = fileparse($filename,'.fas');
        my ($n, $geneid) = split /\./, $name;
        push @{$gene_file_hash{$geneid}}, $filename;
    }
}

foreach my $gene (keys %gene_file_hash) {
    my $outfile = $outdir . '/' . $gene . '.fas';
    open my $OUTFILE, ">", $outfile or die "Could not open file $outfile for writing $!\n";
    foreach my $infile (@{$gene_file_hash{$gene}}) {
        open my $INFILE, "<", $infile or die "Could not open file $infile for reading: $!\n";
        while (<$INFILE>) {
            print $OUTFILE $_;
        }
        close($INFILE);
    }
    close($OUTFILE);
}

