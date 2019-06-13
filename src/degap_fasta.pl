#!/usr/bin/env perl
#===============================================================================
=pod

=head2

         FILE: degap_fasta.pl

        USAGE: ./degap_fasta.pl [--all] [--any] fasta_file(s)

  DESCRIPTION: Removes sites with all gaps from aligned FASTA files

      OPTIONS: --all option removes all gap characters (-) from the sequences, thus
               not preserving the alignment.

               --any option removes all columns containing any gaps from the
               sequences, while preserving the alignment.

               Default is to remove columns containing gaps-only, while preserving
               the alignment.

 REQUIREMENTS: ---

         BUGS: ---

        NOTES: Modified from fasta2stockholm.pl 02/22/2010 02:30:02 PM CET
               Note: reads only the first word in the fasta header!

       AUTHOR: Johan Nylander (JN), johan.nylander@nbis.se

      COMPANY: BILS/NRM

      VERSION: 1.0

      CREATED: 02/22/2010 07:12:32 PM CET

     REVISION: 2019 06 13 

=cut

#===============================================================================

use warnings;
use strict;
use Getopt::Long;
use Data::Dumper;

my $usage = "\nUsage: $0 [--all] [--any] FASTA_file(s)\n
  The --all option removes all gap characters (-) from the sequences, thus
  not preserving the alignment.
  The --any option removes all columns containing any gaps from the
  sequences, while preserving the alignment.
  Default is to remove columns containing gaps-only, while preserving
  the alignment.\n\n";

## Some defaults
my $all          = 0;
my $any          = 0;
my $suffix       = ".degap.fas";
my $gap          = '-';
my $print_length = 80;
my $verbose      = 0;
my $debug        = 0;

## Handle arguments
if (@ARGV < 1) {
    die $usage;
}
else {
    GetOptions('help'    => sub {print $usage; exit(0);},
               'all'     => \$all,
               'any'     => \$any,
               'verbose' => \$verbose,
               'debug'   => \$debug,
              );
}

## Loop through FASTA files
while ( my $fasta = shift(@ARGV) ) {

    ## Read FASTA file
    my %seq_hash    = ();
    my @names       = ();
    my $name        = q{};
    my $outfile     = q{};
    my @gap_columns = ();

    open my $FASTA, "<", $fasta or die "Couldn't open '$fasta': $!";
    print STDERR "$fasta: " if $verbose;
    while (<$FASTA>) {
        chomp();
        if (/^\s*>\s*(\S+)/) {
            $name = $1;
            die "Duplicate name: $name" if defined $seq_hash{$name};
            push @names, $name;
        }
        else {
            if ( /\S/ && !defined $name ) {
                warn "Ignoring: $_";
            }
            else {
                print STDERR "replacing white space in input\n" if $verbose;
                s/\s//g;
                print STDERR "splitting line in input\n" if $verbose;
                my @line = split //, $_;
                print STDERR "pushing lines in input\n" if $verbose;
                push ( @{$seq_hash{$name}}, @line );
            }
        }
    }
    close $FASTA;
    
    ## Check all seqs are same length
    my $length;
    my $lname;
    foreach my $name (@names) {
        my $l = scalar @{$seq_hash{$name}};
        if ( defined $length ) {
            die "Sequences not all same length ($lname is $length, $name is $l)"
              unless $length == $l;
        }
        else {
            $length = scalar @{$seq_hash{$name}};
            $lname  = $name;
        }
    }
    
    ## Do options
    if ($all) {
        ## Remove all gaps from the sequences
        foreach my $key (keys %seq_hash) {
            foreach my $l (@{$seq_hash{$key}}) {
                $l =~ s/$gap//g;
            }
        }
    }
    elsif ($any) {
        ## Remove columns containing any gaps 
        for (my $i = 0; $i < $length ; $i++) {
            OVER_TAX:
            foreach my $tax (keys %seq_hash) {
                my $pos = $seq_hash{$tax}->[$i];
                if ($pos eq $gap) {
                    push @gap_columns, $i;
                    last OVER_TAX;
                }
            }
        }
        print STDERR "Any gap in columns: ", @gap_columns, "\n" if $debug;
    }
    else {
        ## Remove gap-only columns
        for (my $i = 0; $i < $length ; $i++) {
            my @column = ();
            foreach my $tax (keys %seq_hash) {
                push ( @column, $seq_hash{$tax}->[$i] );
            }
            if (@column == grep { $_ eq $gap } @column) { # all equal and all gaps
                push @gap_columns, $i;
            }
        }
        print STDERR "All-gaps in columns: ", @gap_columns, "\n" if $debug;
    }

    ## Check if any gaps where found
    if(scalar(@gap_columns) > 0) {
        my $p = scalar(@gap_columns);
        print STDERR "removing $p positions, " if $verbose;
        foreach my $name (@names) {
            foreach my $pos (@gap_columns) {
                $seq_hash{$name}->[$pos] =~ s/\S//;
            }
        }
    }

    ## Print sequences
    $fasta =~ s/\.[^.]+$//;
    $outfile = $fasta . $suffix;
    open my $OUTFILE, ">", $outfile or die "could not open outfile : $! \n";
    print STDERR "writing $outfile\n" if $verbose;
    foreach my $name (@names) {
        print $OUTFILE ">$name\n";
        my $seq = join( '', @{$seq_hash{$name}} );
        $seq =~ s/\S{80}/$&\n/g;
        print $OUTFILE "$seq\n";
    }
    close $OUTFILE;
}

exit();

