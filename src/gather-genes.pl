#!/usr/bin/perl 
#===============================================================================
=pod


=head2

         FILE: gather-genes.pl

        USAGE: ./gather-genes.pl  folders

  DESCRIPTION: 

      OPTIONS: ---

 REQUIREMENTS: ---

         BUGS: ---

        NOTES: ---

       AUTHOR: Johan Nylander (JN), johan.nylander@nbis.se

      COMPANY: NBIS/NRM

      VERSION: 1.0

      CREATED: 2019-04-12 16:12:21

     REVISION: ---

=cut


#===============================================================================

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use File::Basename;

exec("perldoc", $0) unless (@ARGV);

my $infile  = q{};
my $outfile  = q{};
my $VERBOSE = 0;

GetOptions(
    "infile=s"  => \$infile,
    "outfile=s" => \$outfile,
    "verbose!"  => \$VERBOSE,
    "help"      => sub { exec("perldoc", $0); exit(0); },
);


my %gene_file_hash = ();

while(my $dir = shift(@ARGV)) {
    if ( ! -d $dir ) {
        die "Can not find directory $dir: $!\n";
    }
    my @fasta_files = <$dir/*.fas>;
    foreach my $filename (@fasta_files) {
        my ($name,$path,$suffix) = fileparse($filename,'.fas');
        my ($n,$geneid) = split /\./, $name;
        push @{$gene_file_hash{$geneid}}, $filename;
    }
}

foreach my $gene (keys %gene_file_hash) {
    my $outfile = $gene . ".fas";
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

