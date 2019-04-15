#!/usr/bin/env perl 
#===============================================================================
=pod


=head2

         FILE: extract-fasta-coordinates.pl

        USAGE: ./extract-fasta-coordinates.pl --name=Bpa --start=10 --end=20 fasta.fas
               ./extract-fasta-coordinates.pl --start=10 --end=20 fasta.fas

  DESCRIPTION: Extracts fasta entry, and potentially a sub sequence from fasta file.
               Reads file names from stdin, prints to stdout.

      OPTIONS: -s, --start=<start>  First sequence position (integer) to print.
               -e, --end=<end>      Last sequence position (integer) to print.
               -n, --name=<name>    Sequence name (string) to print.

 REQUIREMENTS: BioPerl with Bio::DB::Fasta;

         BUGS: ---

        NOTES: * The BioPerl parser doesn't warn against duplicated fasta headers.
               * The BioPerl parser only reads the first string after '>' as the
                 fasta header (key). That is, '>Apa Bpa' and '>Apa Cpa' will collide!


         TODO: * Allow reading (and indexing) from several files at once.
               * Also allow reading (and indexing) from a folder.
               * Test if end > start. If not, either
                   1) Die, or
                   2) Warn, but give a tip of using `--reverse`
                      That is, using a `--reverse` flag will
                      extract from the end.
                   3) Extract from the end. That is, extract from
                      the end without having a `--reverse` option.
               * tie above returns undef if failure. Should test for that.
               * Should handle the .index files (delete, or write to /tmp)
                      

       AUTHOR: Johan Nylander (JN), johan.nylander@nbis.se

      COMPANY: NBIS/NRM

      VERSION: 1.0

      CREATED: 12/14/2018 09:16:58 AM

     REVISION: ---

=cut


#===============================================================================

use strict;
use warnings;
use Bio::DB::Fasta;
use Data::Dumper;
use Getopt::Long;

exec("perldoc", $0) unless (@ARGV);

my $name    = q{};
my $start   = 0;
my $end     = q{};
my $VERBOSE = 0;

GetOptions(
    "name=s"    => \$name,
    "start=i"   => \$start,
    "end=i"     => \$end,
    "verbose!"  => \$VERBOSE,
    "help"      => sub { exec("perldoc", $0); exit(0); },
);

if ($end and $start) {
    if ($end < $start) {
        die "Error: End ($end) should be > start ($start).\n";
    }
}

## TODO: Should rewrite to read, and index, several files at once
my $input = shift(@ARGV);

tie my %sequence_db, 'Bio::DB::Fasta', $input;

if ($name) {
    print STDOUT ">$name\n";
    if ($end) {
        print STDOUT $sequence_db{"$name:$start,$end"}, "\n";
    }
    else {
        my $whole_len = tied(%sequence_db)->length($name);
        print STDOUT $sequence_db{"$name:$start,$whole_len"}, "\n";
    }
}
else {
    while (my $id = each %sequence_db) {
        print STDOUT ">$id\n";
        if ($end) {
            print STDOUT $sequence_db{"$id:$start,$end"}, "\n";
        }
        else {
            my $whole_len = tied(%sequence_db)->length($id);
            print STDOUT $sequence_db{"$id:$start,$whole_len"}, "\n";
        }
    }
}

