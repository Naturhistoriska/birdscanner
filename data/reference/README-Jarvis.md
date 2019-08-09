# Prepare reference data

    # - Last modified: fre aug 09, 2019  04:01
    # - Sign: JN

## Data preparation and data reduction

    # The following commands only needs to be done once for the reference set of alignments.
    # 
    # Any genome (scaffold) fasta files should be placed in the `data/genomes` folder,
    # and be named `<uniqeshortname>.fasta`, for example: `AbucgeM_genome.fasta`.
    # The important part is that the `<uniqeshortname>` should not collide with any
    # other file name in the `data/genomes` folder.
    #
    # **Note** Wed 27 Mar 2019 12:47:07 PM CET: All genomes are now on
    # `msl1.nrm.se:/home/pererics/For_Johan/`
    # 
    # The repeatable parts are over in the `run` folder (see the `run/README.md` file).
    #
    # Original data from Jarvis et al. 2014: <http://gigadb.org/dataset/101041>
    #
    # File: introns-filtered-sate-alignments-with-and-without-outgroups.tar.gz
    # The files in birdscanner/data/reference/fasta_files where extracted from
    # the folder "FASTA_files_of_loci_datasets/Filtered_sequence_alignments/2516_Introns/2500orthologs" 
    # by including only sequences containing headers "ACACH", "CORBR", "GEOFO", "MANVI"
    # (representing closest relatives to Bowerbirds):


#### Setup

    PROJECTDIR='/home/nylander/run/pe/birdscanner'
    DATADIR="$PROJECTDIR/data"
    REFERENCEDIR="$DATADIR/reference"
    SELECTED="$REFERENCEDIR/selected"
    GENOMESDIR="$DATADIR/genomes"
    SRCDIR="$PROJECTDIR/src"


#### Extract From Jarvis data

    JARVISDIR="/home/nylander/run/pe/Jarvis_et_al_2014/FASTA_files_of_loci_datasets/Filtered_sequence_alignments/2516_Introns/2500orthologs"
    cd "${JARVISDIR}"
    FILTFILE="filter.txt"
    perl -e 'print "ACACH\nCORBR\nGEOFO\nMANVI\n"' > "${FILTFILE}"
    FILTERED="${DATADIR}/reference/fasta_files"
    mkdir -p "${FILTERED}"
    for f in $(find -name 'sate.removed.intron.noout.aligned-allgap.filtered') ; do
        d=$(dirname "${f}" | sed 's/^\.\///')
        g=$(basename "${f}")
        h="${FILTERED}/${d}.${g}.fas"
        ${SRCDIR}/grepfasta.pl -f "${FILTFILE}" "${f}" | sed '/^$/d' > "${h}"
    done
    rm "${FILTFILE}"


#### Create fasta file with degapped selected genes (4 taxa, less than 10,000 bp)

    #cd $REFERENCEDIR

    #cat $($SRCDIR/get_fasta_info.pl fasta_files/*.fas 2>/dev/null | \
    #    awk '$2<10e3' | \
    #    awk '$1==4' | \
    #    awk '{print $NF}') | \
    #    $SRCDIR/remove_gaps_in_fasta.pl -a | \
    #    $SRCDIR/fasta_unwrap.pl | \
    #    $SRCDIR/fasta_wrap.pl | \
    #    awk '/>/{$0=">Seq_"++n}1' > 1485.fasta


#### Copy alignment with four taxa, and less than 10,000 positions

    mkdir -p ${SELECTED}/fas
    cd ${REFERENCEDIR}
    cp $(get_fasta_info.pl fasta_files/*.fas 2>/dev/null | \
        awk '$2<10e3' | \
        awk '$1==4' | \
        awk '{print $NF}') ${SELECTED}/fas/


#### Replace '?' with 'N'

    cd ${SELECTED}/fas
    find . -type f -name '*.fas' | \
        parallel "sed -i 's/?/N/g' {}"


#### Remove "all-gap" columns

    cd ${SELECTED}/fas
    find . -type f -name '*.fas' | \
        parallel "${SRCDIR}/degap_fasta.pl {}"


#### Remove empty lines

    cd ${SELECTED}/fas
    find . -type f -name '*.degap.fas' | \
        parallel "sed -i '/^$/d' {}"


#### Remove unedited fasta

    cd ${SELECTED}/fas
    find . -name '*.filtered.fas' -exec rm {} \;


#### Fasta to Stockholm format conversion
    
    cd ${SELECTED}/fas
    mkdir -p ${SELECTED}/sto
    find . -type f -name '*.degap.fas' | \
        parallel "${SRCDIR}/fasta2stockholm.pl {} > ${SELECTED}/sto/{.}.sto"


#### Build hmms

    cd $SELECTED/sto
    mkdir -p ${SELECTED}/hmm
    find . -type f -name '*.sto' | \
        parallel "hmmbuild ${SELECTED}/hmm/{.}.hmm {}"


#### Create concatenated fasta file for superficial searching

    cd ${SELECTED}
    for f in fas/*.fas ; do
        export f
        h=$(f=$f perl -e 'print"$1"if($ENV{f}=~/^fas\/(\d+)\./)')
        echo $h
        h=$h f=$f \
        perl -e '$f=shift;
                 open(F,"<",$ENV{f});
                 while(<F>){
                   if(/>/){
                       $_ =~ s/>(\w+)$/>$ENV{h}-$1/;
                       print;
                   }
                   else{
                       print;
                   };
                 };
                 close(F);' >> selected_shortlabel.fas
    done

    ${SRCDIR}/remove_gaps_in_fasta.pl selected_shortlabel.fas | \
        ${SRCDIR}/fasta_unwrap.pl | \
        ${SRCDIR}/fasta_wrap.pl > selected_shortlabel.degap.fas


### Compress directories

    cd ${SELECTED}
    #for d in fas sto hmm ; do
    for d in fas sto ; do
        tar -c -I pigz -f "${d}.tar.gz" "${d}"
        rm -r "$d"
    done

