#!/usr/bin/env perl 
#===============================================================================
=pod

=head2

         FILE: remove_gapped_seqs_in_fasta.pl

        USAGE: ./remove_gapped_seqs_in_fasta.pl [-p 10] [-N] [-c] [-v] fasta_file(s) 

  DESCRIPTION: Reads files in FASTA format and removes sequences if they contain
               p percent gaps or missing data (- or ?). -p=10 allows 10% missing
               data, etc.
               
               Default is to remove sequences with an "all-gap" sequence.

               Use option '-N' to include the IUPAC symbol N as missing data.

               Use option '-c' with redirection to get a tab-separated list
               of missing data counts:

                   remove_gapped_seqs_in_fasta.pl --count file.fas 2>/dev/null

      OPTIONS:
               -p=x  allow x percent missing data
               -v    report name and number of positions with missing data.
               -N    include N among missing data (thus counting ? + - + N)
               -c    count and report missing data

        NOTES: ---

       AUTHOR: Johan Nylander (JN)

      COMPANY: NBIS/NRM

      VERSION: 2.0

      CREATED: 10/31/2011 10:14:10 AM

     REVISION: 03/21/2017 09:54:40 PM

=cut
#===============================================================================

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;

my $p_missing = 0;
my $verbose   = 0;
my $N         = q{};
my $count     = q{};
my $suffix    = '.degapped.fas';
my $help;

if (@ARGV < 1) {
    print STDERR "Usage: $0 [-p=50] [--verbose] [-N] fasta_file(s)\n\n";
    print STDERR "       -p=x   -- allow x percent missing data (coded as \'-\' or \'?\')\n";
    print STDERR "       -v     -- report name and number of positions with missing data for excluded seqs.\n";
    print STDERR "       -N     -- include \'N\' among missing data (thus counting \'?\',\'-\',\'N\').\n";
    print STDERR "       -c     -- count and report gap symbols.\n";
}
else {
    GetOptions(
               'percent-missing=i' => \$p_missing,
               'verbose'           => \$verbose,
               'count'             => \$count,
               'N'                 => \$N,
               'help'              => sub { exec("perldoc", $0); exit(0); },
              );
}

while(my $infile = shift(@ARGV)) {
    my $outfile = $infile . $suffix;
    my $term = $/;
    open my $INFILE, "<", $infile or die "could not open infile '$infile' : $! \n";
    print STDERR "\nReading file $infile\n" if ($verbose);
    $/ = ">";
    my $OUTFILE;
    if (!$count) {
        open $OUTFILE, ">", $outfile or die "could not open outfile $outfile : $! \n";
        print STDERR "\nWriting to $outfile\n\n" if ($verbose);
    }
    while(<$INFILE>) {
        chomp;
        next if($_ eq '');
        my ($id, @sequencelines) = split /\n/;
        my $sequence;
        foreach my $line (@sequencelines) {
            $sequence .= $line;
        }

        my $length = length($sequence);
        my $ngaps_allowed;

        if ($p_missing) {
            $ngaps_allowed = ($p_missing/100.0) * $length;
        }
        else {
            $ngaps_allowed = $length - 1; # Default is to only remove seqs being "gap-only"
        }

        my $ngaps     = 0;
        my $nquestion = 0;
        my $nN        = 0;
        my $nmissing  = 0;

        for ($sequence =~ /-/g) {
            $ngaps++;
        }

        for ($sequence =~ /\?/g) {
            $nquestion++;
        }

        for ($sequence =~ /N/ig) {
            $nN++;
        }

        if ($N) {
            $nmissing = $ngaps + $nquestion + $nN;
        }
        else {
            $nmissing = $ngaps + $nquestion;
        }

        if ($count) {
            my $tot = $ngaps + $nquestion + $nN;
            print STDERR "ID\tlength\t-\t?\tN\ttotal\n";
            print STDOUT "$id\t$length\t$ngaps\t$nquestion\t$nN\t$tot\n";
        }
        else {
            if ($nmissing == $length) {
                if ($p_missing == 100) {
                    print $OUTFILE ">", $id, "\n", $sequence, "\n"; 
                }
                else {
                    print STDERR "Seq $id removed:\n  length $length\n     \'-\' $ngaps\n     \'?\' $nquestion\n     \'N\' $nN\n" if($verbose);
                }
            }
            elsif ($nmissing > $ngaps_allowed) {
                print STDERR "Seq $id removed:\n  length $length\n     \'-\' $ngaps\n     \'?\' $nquestion\n     \'N\' $nN\n" if($verbose);
            }
            else {
                print $OUTFILE ">", $id, "\n", $sequence, "\n"; 
            }
        }
    }
    close($INFILE);
    close($OUTFILE) unless($count);
    $/ = $term;
}

