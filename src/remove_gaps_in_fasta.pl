#!/usr/bin/env perl 
#===============================================================================
=pod

=head2

         FILE: remove_gaps_in_fasta.pl

        USAGE: ./remove_gaps_in_fasta.pl infile > stdout 

  DESCRIPTION: Removes (deletes) any gap character ('-') in FASTA sequence

      OPTIONS: ---
 REQUIREMENTS: ---
         BUGS: ---
        NOTES: ---
       AUTHOR: Johan Nylander (JN), jnylander@users.sourceforge.net
      COMPANY: UiO/SU
      VERSION: 1.0
      CREATED: 01/19/2012 01:19:45 PM
     REVISION: ---

=cut
#===============================================================================

use strict;
use warnings;
use Data::Dumper;

#exec("perldoc", $0) unless (@ARGV);

while(<>) {
    my $line = $_;
    chomp($line);
    if ($line =~ /^\s*>/) {
        print STDOUT $line, "\n";
    }
    elsif ($line =~ /-/) {
        $line =~ s/-//g;
        if ($line =~ /^$/) {
            # Effectively removing lines containing gaps only.
            # This might create output with FASTA entries having
            # the FASTA header only and no sequence part if the
            # input was gaps only.
        }
        else {
            print STDOUT $line, "\n";
        }
    }
    else {
        print STDOUT $line, "\n"; # Preserve original file structure having empty lines
    }
}

