#!/usr/bin/env perl 
#===============================================================================
=pod


=head2

         FILE: extract_part_genes.pl

        USAGE: ./extract_part_genes.pl  

  DESCRIPTION: Extracts the parts from sate.removed.intron.noout.aligned-allgap.filtered
               based on region definitions in sate.removed.intron.noout-allgap.filtered.part

               Content of sate.removed.intron.noout-allgap.filtered.part is (example):

               DNA, 39861 = 1-2851
               DNA, 39862 = 2852-3714

               Two output files will be created from the example above:

               39861.<foldername>.fas, 39862.<foldername>.fas

               where <foldername> is a numeric value.

      OPTIONS: ---

 REQUIREMENTS: ---

         BUGS: ---

        NOTES: Should be run inside /home/nylander/run/pe/Jarvis_et_al_2014/FASTA_files_of_loci_datasets/Filtered_sequence_alignments/2516_Introns/2500orthologs
               or passed the path to that folder as argument

       AUTHOR: Johan Nylander (JN), johan.nylander@nrm.se

      COMPANY: NBIS/NRM

      VERSION: 1.0

      CREATED: 2019-04-30 15:26:30

     REVISION: Wed 12 Feb 2020 06:09:19 PM CET

=cut


#===============================================================================

use strict;
use warnings;
use Cwd;
use File::Path qw( make_path );
use File::Slurp;
use Parallel::ForkManager;
use Getopt::Long;

my $verbose = 1;
my $cpu = 10;

GetOptions(
    "verbose!" => \$verbose,
    "help"     => sub { exec("perldoc", $0); exit(0); },
);


my $partfile = 'sate.removed.intron.noout-allgap.filtered.part';
my $seqfile = 'sate.removed.intron.noout.aligned-allgap.filtered';

my $wd = q{};

if (@ARGV) {
    $wd = shift(@ARGV);
    if ($wd eq '.') {
        $wd = getcwd;
    }
}
else {
    $wd = getcwd;
}

my @dirs = read_dir($wd);

#my $outfolder = $wd . '/' . 'part_fasta_files';
my $outfolder = $wd . '/' . 'fasta_files';

make_path($outfolder);

#my $pm = new Parallel::ForkManager($cpu);

foreach my $dir (@dirs) {

    next unless -d $dir;
    next if $dir =~ /fasta/;

    #my $pid = $pm->start and next;

    ## Begin Parallel block
        open my $PFILE, "$dir/$partfile" or die "$!";
        sleep(1);
        while (<$PFILE>) {
            chomp:
            my @F = split /\s+/, $_;
            my $id = $F[1];
            my ($start, $end) = split /-/, $F[3];
            print STDERR "dir:$dir id:$id start:$start end:$end\n" if $verbose;
            extract_fasta_coordinates($outfolder, $dir, $id, $seqfile, $start, $end);
            #extract_fasta_coordinates($outfolder, $dir, $id, $seqfile, $start, $end, $id);
        }
        close($PFILE);
    ## End Parallel block

    #$pm->finish;
}

#$pm->wait_all_children;


sub extract_fasta_coordinates {
    my ($outfolder, $dir, $id, $seqfile, $start, $end) = @_;
    #my ($outfolder, $dir, $id, $seqfile, $start, $end, $outname) = @_;
    my $fastafilepath = $outfolder . '/' . $id . '.' . $dir . '.fas';
    my $seqfilepath = $dir . '/' . $seqfile;
    open my $FAS, ">", $fastafilepath or die "$!";
    open my $SEQ, "<", $seqfilepath or die "$!";
    my $i = 0;
    my $first = 0;
    while (<$SEQ>) {
        chomp;
        if ($_ =~ /^\s*$/) {
            next;
        }
        if (/^>/) {
            if ($first) {
                print $FAS "\n";
            }
            #if ($outname) {
            #    print $FAS ">$outname\n";
            #}
            #else {
                print $FAS $_, "\n";
            #}
            $i = 0;
            $first = 1;
        }
        else {
            my (@sequenceline) = split //;
            foreach my $base (@sequenceline) {
                $i++;
                if ($end) {
                    if ($i >= $start && $i <= $end) {
                        print $FAS $base;
                    }
                }
                else {
                    if ($i >= $start) {
                        print $FAS $base;
                    }
                }
            }
        }
    }
    close($SEQ);
    close($FAS);
}

__END__
