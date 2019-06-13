# Reference data preparation

#### First, put reference alignments in fasta format (file ending `.fas`, no periods in file name) in `birdscanner/data/reference/fasta_files`

#### Setup (note hardcoded path! Need to change!)

    PROJECTDIR='/path/to/birdscanner' # <<<<<< Change path here!
    DATADIR="$PROJECTDIR/data"
    REFERENCEDIR="$DATADIR/reference"
    SELECTED="$REFERENCEDIR/selected"
    GENOMESDIR="$DATADIR/genomes"
    SRCDIR="$PROJECTDIR/src"

#### If needed, convert line breaks to unix

    find "${REFERENCEDIR}/fasta_files" -type f -name '*.fas' | \
        parallel "sed -i 's/.$//' {}"

#### Select which sequences, and which fasta files to be used ("selected"). If no filtering (as in example below), all files and sequences can be used.
    
    mkdir -p "${SELECTED}/fas"
    cp ${REFERENCEDIR}/fasta_files/*.fas "${SELECTED}/fas"

#### Replace '?' with 'N'

    find "${SELECTED}/fas" -type f -name '*.fas' | \
        parallel "sed -i 's/?/N/g' {}"

#### Remove "all-gap" columns

    find "${SELECTED}/fas" -type f -name '*.fas' | \
        parallel "${SRCDIR}/degap_fasta.pl {}"

#### Remove empty lines

    find "${SELECTED}/fas" -type f -name '*.degap.fas' | \
        parallel "sed -i '/^$/d' {}"

#### Fasta to Stockholm format conversion
    
    mkdir -p "${SELECTED}/sto"
    cd "${SELECTED}/fas"
    find . -type f -name '*.degap.fas' | \
        parallel "${SRCDIR}/fasta2stockholm.pl {} > ${SELECTED}/sto/{.}.sto"

#### Build hmms

    mkdir -p "${SELECTED}/hmm"
    cd "$SELECTED/sto"
    find . -type f -name '*.sto' | \
        parallel "hmmbuild ${SELECTED}/hmm/{.}.hmm {}"

#### Create concatenated fasta file for superficial searching
        
    cd "${SELECTED}"
    for f in fas/*.degap.fas ; do
        export f
        h=$(f=$f perl -e 'print"$1"if($ENV{f}=~/^fas\/(\w+)\./)')
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

#### Compress some files

    cd "${SELECTED}"
    tar czf fas.tgz fas && rm -r fas/
    tar czf sto.tgz sto && rm -r sto/
    gzip selected_shortlabel.fas

