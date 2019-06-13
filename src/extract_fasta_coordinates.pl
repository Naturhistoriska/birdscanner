#!/usr/bin/env perl 
#===============================================================================
=pod

=head1

         FILE: extract_fasta_coordinates.pl

        USAGE: ./extract_fasta_coordinates.pl [-s=<start>] [-e=<end>] [-o=<string>] INPUT  

  DESCRIPTION: Extract positions from fasta formatted sequence entries.
               Reads from stdin, prints to stdout.

      OPTIONS: -s, --start=<integer>  First position to print (inclusively). Default: "1".
               -e, --end=<integer>    Last position to print (inclusively). Default: all.
               -o, --outname=<string> Rename the output sequence to <string>.
               -h, --help             Help info.

 REQUIREMENTS: perldoc for help text.

         BUGS: ---

        NOTES: First position in sequence is position 1 (one).

       AUTHOR: Johan Nylander (JN), Johan.Nylander@nbis.se

      COMPANY: NBIS/NRM

      VERSION: 1.0

      CREATED: 09/22/2015 02:53:00 PM

     REVISION: 2019-06-13

=cut

#===============================================================================

use strict;
use warnings;
use Getopt::Long;

my $start   = 0;
my $end     = q{};
my $outname = q{};
my $verbose = 0;

GetOptions(
    "start=i"   => \$start,
    "end=i"     => \$end,
    "outname=s" => \$outname,
    "verbose!"  => \$verbose,
    "help"      => sub { exec("perldoc", $0); exit(0); },
);

my $i = 0;
my $first = 0;

while (<>) {
    chomp;
    if ($_ =~ /^\s*$/) {
        next;
    }
    if (/^>/) {
        if ($first) {
            print STDOUT "\n";
        }
        if ($outname) {
            print STDOUT ">$outname\n";
        }
        else {
            print STDOUT $_, "\n";
        }
        $i = 0;
        $first = 1;
    }
    else {
        my (@sequenceline) = split //;
        foreach my $base (@sequenceline) {
            $i++;
            print STDERR "i:$i base:$base start:$start end:$end\n" if $verbose;
            if ($end) {
                if ($i >= $start && $i <= $end) {
                    print STDOUT $base;
                }
            }
            else {
                if ($i >= $start) {
                    print STDOUT $base;
                }
            }
        }
    }
}

