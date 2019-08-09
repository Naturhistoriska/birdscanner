# Preapre data from Jarvis et al. 2015 for birdscanner

- Last modified: fre aug 09, 2019  04:25
- Sign: JN

## Description

Original data from Jarvis et al. 2014: <http://gigadb.org/dataset/101041>

File: `introns-filtered-sate-alignments-with-and-without-outgroups.tar.gz`

The files in `birdscanner/data/reference/fasta_files` where extracted from the
folder `FASTA_files_of_loci_datasets/Filtered_sequence_alignments/2516_Introns/2500orthologs`
by including only sequences containing headers "ACACH", "CORBR", "GEOFO",
"MANVI" (representing closest relatives to Bowerbirds):

## Commands used:

    PROJECTDIR='/home/nylander/run/pe/birdscanner'
    DATADIR="$PROJECTDIR/data"
    REFERENCEDIR="$DATADIR/reference"
    SELECTED="$REFERENCEDIR/selected"
    GENOMESDIR="$DATADIR/genomes"
    SRCDIR="$PROJECTDIR/src"

    JARVISDIR="/home/nylander/run/pe/Jarvis_et_al_2014/FASTA_files_of_loci_datasets/Filtered_sequence_alignments/2516_Introns/2500orthologs"
    cd "${JARVISDIR}"

    ## Split fasta files to parts. Output is in folder "${JARVISDIR}/fasta_files"
    perl ${SRCDIR}/extract_part_genes.pl

    ## Extract sequences for target species only
    DATADIR="$PROJECTDIR/data"
    cd "${DATADIR}"
    FILTFILE="filter.txt"
    perl -e 'print "ACACH\nCORBR\nGEOFO\nMANVI\n"' > "${FILTFILE}"
    FILTERED="${DATADIR}/reference/fasta_files"
    mkdir -p "${FILTERED}"
    export FILTERED
    export FILTFILE
    my_func() {
        g=$(basename "$1")
        partname="${g%%.*}"
        outfile="${FILTERED}/${partname}.fas"
        ${SRCDIR}/grepfasta.pl -f "${FILTFILE}" "$1" | sed '/^$/d' > "${outfile}"
    }
    export -f my_func
    find ${JARVISDIR}/fasta_files -name '*.fas' -print | \
        parallel my_func
    rm "${FILTFILE}"


## Example of filtering step

    ## Copy alignment with four taxa, and 100 &lt; positions &lt; 4,000
    cd ${REFERENCEDIR}
    mkdir -p ${SELECTED}/fas
    cp $(get_fasta_info.pl fasta_files/*.fas 2>/dev/null | \
        awk '$2<4e3' | \
        awk '$2>99' | \
        awk '$1==4' | \
        awk '{print $NF}') ${SELECTED}/fas/

