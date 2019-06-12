# Reference data preparation

## First, put reference alignments in fasta format (file ending '.fas) in `birdscanner/data/reference/fasta_files`

#### Setup (note hardcoded path! Need to change!)

    PROJECTDIR='/path/to/birdscanner' ### <<<<<< Change path here
    DATADIR="$PROJECTDIR/data"
    REFERENCEDIR="$DATADIR/reference"
    SELECTED="$REFERENCEDIR/selected"
    GENOMESDIR="$DATADIR/genomes"
    SRCDIR="$PROJECTDIR/src"

#### Select which sequences, and which fasta files to be used ("selected"). If no filtering (as in example below), all files and sequences can be used.
    
    cd "${DATADIR}"
    mkdir -p "${SELECTED}/fas"
    cp ${REFERENCEDIR}/fasta_files/*.fas "${SELECTED}/fas"

#### Replace '?' with 'N'

    cd "${SELECTED}/fas"
    find . -type f -name '*.fas' | \
        parallel "sed -i 's/?/N/g' {}"

#### Remove "all-gap" columns

    cd "${SELECTED}/fas"
    find . -type f -name '*.fas' | \
        parallel "${SRCDIR}/degap_fasta.pl {}"

#### Remove empty lines

    cd "${SELECTED}/fas"
    find . -type f -name '*.degap.fas' | \
        parallel "sed -i '/^$/d' {}"

#### Fasta to Stockholm format conversion
    
    cd "${SELECTED}/fas"
    mkdir -p "${SELECTED}/sto"
    find . -type f -name '*.degap.fas' | \
        parallel "${SRCDIR}/fasta2stockholm.pl {} > ${SELECTED}/sto/{.}.sto"

#### Build hmms

    cd "$SELECTED/sto"
    mkdir -p "${SELECTED}/hmm"
    find . -type f -name '*.sto' | \
        parallel "hmmbuild ${SELECTED}/hmm/{.}.hmm {}"

#### Create concatenated fasta file for superficial searching

    cd "${SELECTED}"
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
                 close(F);' >> "${SELECTED}/selected_shortlabel.fas"
    done

#### Degap and wrap

    ${SRCDIR}/remove_gaps_in_fasta.pl "${SELECTED}/selected_shortlabel.fas" | \
        ${SRCDIR}/fasta_unwrap.pl | \
        ${SRCDIR}/fasta_wrap.pl > "${SELECTED}/selected_shortlabel.degap.fas"


