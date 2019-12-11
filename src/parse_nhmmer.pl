#!/usr/bin/env perl 
#===============================================================================

=pod

=head1

         FILE:  parse_nhmmer.pl

        USAGE: ./parse_nhmmer.pl -i nhmmer.out -g genome.fas [-d outdir] [-p prefix] [--nostats] [-f output-fasta-header]

               ./parse_nhmmer.pl \
                   -i run/hmmer/AbucgeM_genome.nhmmer.out \
                   -g run/plast/AbucgeM_genome.plast200.fas

               perl src/parse_nhmmer.pl \
                   -i run/hmmer/AbucgeM_genome.nhmmer.out \
                   -g run/plast/AbucgeM_genome.plast200.fas \
                   -d out/AbucgeM_genome_hmmer \
                   -p 'AbucgeM' \
                   -f 'AbucgeM' \
                   --nostats

  DESCRIPTION: Parse HMMER output from command:

               $ nhmmer --tblout nhmmer.out --cpu 10 markers.hmm genome.fas > log.nhmmer.log

               Input:
               HMMER-output file (from command above), Genome-fasta-file

               IMPORTANT: Expected header format (in fasta files used to create the
               markers.hmm file) for this version (will use "marker_id"):
               <marker_id>.the_rest
               Examples:
               1000.sate.default.pep2cds.removed.shortname.filtered
               14365.sate.removed.intron.noout.aligned-allgap.filtered.fas.degap
               
               Output:
               Will write separate fasta files to output directory, one for each marker.

      OPTIONS: -i <HMMER-output>       Output from nhmmer.
               -g <genome-fasta-file>  fasta file (same genomic file used in the nhmmer search).
               -d <output-directory>   Name of output directory. Default: `Parse-HMMer-output`.
               -p <prefix>             Prefix for fasta (marker) output file. Default name is
                                       based on marker ID (<marker_id.fas>).
               -f <output-header>      Provide string for fasta header: `>string`.
                                       Default is to have the marker ID.
               -s                      Give HMMer stats (default) in the output fasta header.
                                       Use `--nostats` to supress.
               -h                      Show help information.
               -v                      Be verbose (default), or not (`--noverbose`).


 REQUIREMENTS: ---

         BUGS: ---

        NOTES: --- 

       AUTHOR: Johan Nylander (JN), Johan.Nylander@nbis.se

      COMPANY: NBIS/NRM

      VERSION: 1.0

      CREATED: 09/17/2015 11:06:04 PM

     REVISION: Wed 11 Dec 2019 10:02:09 AM CET

=cut

#===============================================================================

use strict;
use warnings;
use Getopt::Long;

exec( 'perldoc', $0 ) unless (@ARGV);

my %HoH          = ();  # key:scaffold header, val:hash:key:query name, vals:
my %query_hash   = ();  # key: name, val: count
my $directory    = 'Parse-HMMer-output'; # Output directory
my $fastaheader  = q{}; # Output fasta header string
my $genome       = q{}; # Genome fasta file
my $infile       = q{}; # Hmmer file
my $prefix       = q{}; # File prefix for output fasta files
my $stats        = 1;   # HMMer stats in output fasta header
my $VERBOSE      = 1;

GetOptions(
    "directory=s"   => \$directory,
    "fastaheader=s" => \$fastaheader,
    "genome=s"      => \$genome,
    "help"          => sub { exec( "perldoc", $0 ); exit(0); },
    "infile=s"      => \$infile,
    "prefix=s"      => \$prefix,
    "stats!"        => \$stats,
    "verbose!"      => \$VERBOSE,
);

## Read HMM-output file
open my $INFILE, "<", $infile or die "$!\n";
print STDERR "Parsing HMMER output file $infile\n" if ($VERBOSE);
while (<$INFILE>) {
    chomp;
    next if /^#/;
    my (
        $target_name,     $target_accession, $query_name,
        $query_accession, $hmmfrom,          $hmm_to,
        $alifrom,         $ali_to,           $envfrom,
        $env_to,          $sq_len,           $strand,
        $E_value,         $score,            $bias,
        $description_of_target
    ) = split /\s+/, $_;

    ## Find first occurence of each query_name. This would be the best hit (assuming no ties!)
    if ( $query_hash{$query_name}++ ) {
        next;
    }
    else {
        my $details = "/target name=$target_name /accession=$target_accession /query name=$query_name /accession=$query_accession /hmmfrom=$hmmfrom /hmm to=$hmm_to /alifrom=$alifrom /ali to=$ali_to /envfrom=$envfrom /env to=$env_to /sq len=$sq_len /strand=$strand /E-value=$E_value /score=$score /bias=$bias /description of target=$description_of_target";
        my $scaffold = $target_name;
        $HoH{$scaffold}{$query_name}{'alifrom'} = $alifrom;
        $HoH{$scaffold}{$query_name}{'ali to'}  = $ali_to;
        $HoH{$scaffold}{$query_name}{'strand'}  = $strand;
        $HoH{$scaffold}{$query_name}{'details'} = $details;
    }
}
close($INFILE);

## Create output directory for fasta files
if ( -e $directory ) {
    die "Warning. Directory $directory already exists.\n";
}
else {
    unless ( mkdir $directory ) {
        die "Unable to create $directory\n";
    }
}
print STDERR "Created output directory $directory\n" if ($VERBOSE);

## Read genome file
open my $FASTA, "<", $genome or die "Cannot open fasta file: $genome $! \n";
print STDERR "Reading fasta file $genome\n" if ($VERBOSE);
my $def = $/;
$/ = ">";
while (<$FASTA>) {
    chomp;
    next if ( $_ eq '' );
    my ( $id, @sequencelines ) = split /\n/;
    $id =~ s/(\S+).*$/$1/;
    if ( exists( $HoH{$id} ) ) {
        my $sequence = '';
        foreach my $line (@sequencelines) {
            $sequence .= $line;
        }
        foreach my $key ( keys %{ $HoH{$id} } ) {
            my ( $geneid, @rest ) = split /\./, $key; # highly format dependent!
            ## Set fasta file name
            my $outfastafile = q{};
            if ($prefix) {
                $outfastafile = $prefix . ".$geneid.fas";
            }
            else {
                $outfastafile =  "$geneid.fas";
            }
            open my $OUTFILE, ">", "$directory/$outfastafile"
              or die "Could not open fasta file for writing: $! \n";
            print STDERR "    writing $outfastafile\n" if ($VERBOSE);
            ## Print fasta header
            print $OUTFILE ">";
            if ($fastaheader) {
                print $OUTFILE $fastaheader;
            }
            else {
                print $OUTFILE $geneid;
            }
            if ($stats) {
                print $OUTFILE " ", $HoH{$id}{$key}{'details'}, "\n";
            }
            else {
                print $OUTFILE "\n";
            }
            ## Print sequence
            my ( $from, $to ) = q{};
            if ( $HoH{$id}{$key}{'strand'} eq '+' ) {
                $from = $HoH{$id}{$key}{'alifrom'} - 1;
                $to   = $HoH{$id}{$key}{'ali to'};
            }
            elsif ( $HoH{$id}{$key}{'strand'} eq '-' ) {
                $from = $HoH{$id}{$key}{'ali to'} - 1;
                $to   = $HoH{$id}{$key}{'alifrom'};
            }
            my $len = $to - $from;
            my $seq = substr( $sequence, $from, $len );
            if ( $HoH{$id}{$key}{'strand'} eq '-' ) {
                $seq = revcomp_iupac($seq);
            }
            $seq =~ s/(.{60})/$1\n/g;
            print $OUTFILE $seq, "\n";
            close($OUTFILE);
        }
    }
}
close($FASTA);
$/ = $def;
print STDERR "\nEnd of script\n" if ($VERBOSE);

sub revcomp {
    my $seq = shift;
    $seq = uc($seq);
    $seq = scalar reverse $seq;
    $seq =~ tr/GATC/CTAG/;
    return $seq;
}

sub revcomp_iupac {
    ## revcomp_iupac
    ## Version: Wed 20 Mar 2019 10:59:00 AM CET
    ## Input: DNA string
    ## Returns: string, reversed and complemented
    ## Tries to handle IUPAC ambiguity symbols:
    ## IUPAC Code  Meaning           Complement
    ## A           A                 T
    ## C           C                 G
    ## G           G                 C
    ## T/U         T                 A
    ## M           A or C            K
    ## R           A or G            Y
    ## W           A or T            W
    ## S           C or G            S
    ## Y           C or T            R
    ## K           G or T            M
    ## V           A or C or G       B
    ## H           A or C or T       D
    ## D           A or G or T       H
    ## B           C or G or T       V
    ## N           G or A or T or C  N
    my $seq = shift;
    $seq = uc($seq);
    $seq = scalar reverse $seq;
    $seq =~ tr/ACGTMRWSYKVHDBN/TGCAKYWSRMBDHVN/;
    return $seq;
}

__END__
