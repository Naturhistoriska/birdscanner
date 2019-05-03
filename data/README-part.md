# Prepare reference data

    # - Last modified: fre maj 03, 2019  08:34
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
    SELECTED="$REFERENCEDIR/selected-part"
    GENOMESDIR="$DATADIR/genomes"
    SRCDIR="$PROJECTDIR/src"


#### Extract From Jarvis data

    JARVISDIR="/home/nylander/run/pe/Jarvis_et_al_2014/FASTA_files_of_loci_datasets/Filtered_sequence_alignments/2516_Introns/2500orthologs"
    cd "${JARVISDIR}"

    ## Split fasta files to parts. Output is in folder "${JARVISDIR}/part_fasta_files"
    time perl ${SRCDIR}/extract_part_genes.pl
    # real	59m18,837s
    # user	17m19,957s
    # sys	0m2,416s

    
    ## Extract sequences for target species only
    DATADIR="$PROJECTDIR/data"
    cd "${DATADIR}"
    FILTFILE="filter.txt"
    perl -e 'print "ACACH\nCORBR\nGEOFO\nMANVI\n"' > "${FILTFILE}"
    FILTERED="${DATADIR}/reference/part_fasta_files"
    mkdir -p "${FILTERED}"

    #time for f in $(find ${JARVISDIR}/part_fasta_files -name '*.fas') ; do
    #    g=$(basename "${f}")
    #    partname=${g%%.*}
    #    outfile="${FILTERED}/${partname}.fas"
    #    fastagrep -t -f "${FILTFILE}" "${f}" | sed '/^$/d' > "${outfile}"
    #done
    # real	3m42,507s
    # user	3m10,644s
    # sys	0m52,036s

    export FILTERED
    export FILTFILE
    my_func() {
        g=$(basename "$1")
        partname="${g%%.*}"
        outfile="${FILTERED}/${partname}.fas"
        fastagrep -t -f "${FILTFILE}" "$1" | sed '/^$/d' > "${outfile}"
    }
    export -f my_func
    time find ${JARVISDIR}/part_fasta_files -name '*.fas' -print | \
        parallel my_func
    rm "${FILTFILE}"


#### Copy alignment with four taxa, and 100 &lt; positions &lt; 4,000

    cd ${REFERENCEDIR}
    mkdir -p ${SELECTED}/fas
    cp $(get_fasta_info.pl part_fasta_files/*.fas 2>/dev/null | \
        awk '$2<4e3' | \
        awk '$2>99' | \
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
                 close(F);' >> part_selected_shortlabel.fas
    done

    ${SRCDIR}/remove_gaps_in_fasta.pl part_selected_shortlabel.fas | \
        ${SRCDIR}/fasta_unwrap.pl | \
        ${SRCDIR}/fasta_wrap.pl > part_selected_shortlabel.degap.fas


### Compress directories

    cd ${SELECTED}
    #for d in fas sto hmm ; do
    for d in fas sto ; do
        tar -c -I pigz -f "${d}.tar.gz" "${d}"
        rm -r "$d"
    done

