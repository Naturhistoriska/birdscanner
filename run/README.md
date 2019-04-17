# Run

    # - Last modified: ons apr 17, 2019  04:31
    # - Sign: JN
    # - Note: These commands are for running one genome at a time.
    #         Iterateive/parallel runs on several genomes may be attempted
    #         using the `make` pipeline.


    # The commands used here are to be repeated for each genome (scaffolds) file.
    #
    # The steps include:
    #
    #  - Run PLAST 
    #  - Parse PLAST output
    #  - Run nhmmer
    #  - Parse nhmmer output
    # 
    # Compressed (gzip) genome (scaffold) fasta files should be placed in the `data/genomes` folder,
    # and be named `<uniqeshortname>.some_suffix`, for example: `AbucgeM_genome.fa.gz`.
    # The important part is that the `<uniqeshortname>` should not collide with any
    # other file name in the `data/genomes` folder. And, `<uniqeshortname>` should not
    # contain periods (`.`).
    #
    ## Prerequisites
    #
    # The commands are tested on Linux.
    # The custom scripts and software used are located in the `src` folder.
    # In addition, these programs needs to be present
    #
    #   - makeblastdb (v.2.6.0+)
    #   - plast (v.2.3.1)
    #   - hmmpress (v.3.2.1)
    #   - nhmmer (v.3.2.1)
    #

#### Set up

    GENOMEFILE='AbucgeM_genome.fa.fa.gz'
    GENOME=${GENOMEFILE%%.*}

    PROJECTDIR='/home/nylander/run/pe/birdscanner'

    DATADIR="$PROJECTDIR/data"
    REFERENCEDIR="$DATADIR/reference"
    SELECTED="$REFERENCEDIR/selected"
    GENOMESDIR="$DATADIR/genomes"
    RUNDIR="$PROJECTDIR/run"
    SRCDIR="$PROJECTDIR/src"

    NCPU=10

## Run PLAST

    cd $RUNDIR/plast

    ln -sf $GENOMESDIR/$GENOMEFILE $GENOMEFILE

    ln -sf $SELECTED/selected_shortlabel.degap.fas selected_shortlabel.degap.fas

    #time $SRCDIR/splitfast-100K $GENOMEFILE > ${GENOME}.split.fas
    time $SRCDIR/splitfast-100K <(gunzip -c $GENOMEFILE) > ${GENOME}.split.fas
    #real	0m7.663s
    #user	0m13.235s
    #sys	0m1.186s

    time makeblastdb -dbtype nucl -in ${GENOME}.split.fas
    # real	0m14.044s
    # user	0m12.876s
    # sys	0m0.353s

    time plast -p plastn \
        -i selected_shortlabel.degap.fas \
        -d ${GENOME}.split.fas \
        -o ${GENOME}.selected.plast.tab \
        -a ${NCPU} \
        -max-hit-per-query 1 \
        -bargraph
    # real	21m56.511s
    # user	195m36.639s
    # sys	0m5.809s


## Parse PLAST output

#### Get a managable sized fasta file from where to extract genes using hmmer

    cd $RUNDIR/plast

    # PLAST output format (`-outfmt 1`) for file ${GENOME}.selected.plast.tab (tab delim):
    # query ID, subject ID, percent identities, alignment length, nb. misses, nb. gaps,
    # query begin, query end, subject begin, subject end, e-value, bit score
    
    # Which scaffolds have plast best hits (highest bit score) with alignments longer than 200 (N=1187)
    awk '$4>200' ${GENOME}.selected.plast.tab | \
        perl -npe 's/-\w+//' | \
        sort -t$'\t' -k1g -k12rg | \
        awk -F $'\t' '!x[$1]++' | \
        awk -F $'\t' '{print $2}' | \
        sort -u | \
        tee ${GENOME}.plast200.scaffold.ids | \
        wc -l

    # Extract the splitted scaffolds
    sed -e 's/$/\$/' -e 's/^/\^>/' ${GENOME}.plast200.scaffold.ids > searchfile

    time $SRCDIR/grepfasta.pl -f searchfile ${GENOME}.split.fas > ${GENOME}.plast200.fas
    # real	0m31.541s
    # user	0m31.254s
    # sys	0m0.280s

    rm searchfile

    $SRCDIR/get_fasta_info.pl ${GENOME}.plast200.fas
    # Nseqs	Min.len	Max.len	Avg.len	File
    # 1187	2874	100000	99418	AbucgeM_genome.plast200.fas


    # We now have a fasta file from where we want to extract genes using hmmer: `AbucgeM_genome.plast200.fas`


#### Concatenate only those hmms indicated by plast

    cd $RUNDIR/plast

    # Which query alignments, and how many, does have a longer (>200) best hit (highest bit score) match? (1450)

    awk '$4>200' ${GENOME}.selected.plast.tab | \
        perl -npe 's/-\w+//' | \
        sort -t$'\t' -k1g -k12rg | \
        awk -F $'\t' '!x[$1]++' | \
        awk -F $'\t' '{print $1}' | \
        tee ${GENOME}.plast200.ref.ids | \
        wc -l

    # Make selection here based on ids in file AbucgeM_genome.selected_shortlabel.degap.200.plast.alignment.ids
    sed -e 's/\([0-9]\+\)/hmm\/\1\.sate/' ${GENOME}.plast200.ref.ids > searchfile

    time cat $(find $SELECTED/hmm -type f -name \*.hmm | grep -f searchfile) > ${RUNDIR}/hmmer/${GENOME}.selected_concat.hmm
    # real	0m3.931s
    # user	0m0.348s
    # sys	0m0.653s

    rm searchfile

    cd ${RUNDIR}/hmmer

    time hmmpress ${GENOME}.selected_concat.hmm
    # real	0m17.024s
    # user	0m16.104s
    # sys	0m0.920s


## Run nhmmer. Note: this is preferably done on uppmax (see ${SRCDIR}/create-slurm-file.pl)

    cd ${RUNDIR}/hmmer

    ln -s $RUNDIR/plast/${GENOME}.plast200.fas ${GENOME}.plast200.fas
    
#### Search scaffolds using the hmms

    time nhmmer \
        --tblout ${GENOME}.hmmer.out \
        --notextw \
        --cpu 10 \
        ${GENOME}.selected_concat.hmm \
        ${GENOME}.plast200.fas \
        &> /dev/null &

#### Alt. Search scaffolds using the hmms on Uppmax

    ./create-slurm-file.pl -a snicXXXX-X-XX -g ${GENOME}  > ${GENOME}.nhmmer.slurm.sh
    scp ${GENOME}.nhmmer.slurm.sh rackham.uppmax.uu.se:/proj/xxxxx/johan/run/hmmer/.
    scp ${GENOME}.plast200.fas rackham.uppmax.uu.se:/proj/xxxxx/johan/run/plast/.
    scp ${GENOME}.selected_concat.hmm rackham.uppmax.uu.se:/proj/xxxxx/johan/run/hmmer/.
    ssh rackham
    cd /proj/xxxxx/johan/run/hmmer
    # Need to manually substitute or reassign GENOME variable on rackham!
    sbatch -M rackham,snowy ${GENOME}.nhmmer.slurm.sh
    jobinfo -M rackham,snowy -u $USER
   

#### Parse nhmmer output

    cd ${PROJECTDIR}

    time perl ${SRCDIR}/parse-nhmmer.pl \
        -i ${RUNDIR}/hmmer/${GENOME}.hmmer.out \
        -g ${RUNDIR}/plast/${GENOME}.plast200.fas \
        -d ${PROJECTDIR}/out/${GENOME}_hmmer_output \
        -f ${GENOME}\
        -p ${GENOME}
    # real	0m6.461s
    # user	0m6.360s
    # sys	0m0.101s

#### Alt. Parse nhmmer output on Uppmax

	cd /proj/uppstore2018005/johan
	GENOME="PviomiM"
	perl src/parse-nhmmer.pl \
		-i "run/hmmer/${GENOME}_genome.nhmmer.out" \
		-g "run/plast/${GENOME}_genome.plast200.fas" \
		-d "out/${GENOME}_genome_hmmer" \
		-p "${GENOME}" \
		-f "${GENOME}" \
		--nostats

## Gather genes

    cd ${PROJECTDIR}
    perl ${SRCDIR}/gather-genes.pl --outdir=genes $(find out -mindepth 1 -type d)

## Align gene files

    cd ${PROJECTDIR}
    mkdir -p alignments
    # Try mafft (MAFFT v7.310)
    for f in genes/*.fas ; do
        g="${f%.fas}.mafft.ali"
        h="alignments/$(basename "$g")"
        mafft --auto --thread ${NCPU} "$f" > "$h"
    done

### Evaluate alignments

    # $ get_fasta_info.pl 10011.fas
    # Nseqs	Min.len	Max.len	Avg.len	File
    # 32	1507	4710	4317	10011.fas
    # $ get_fasta_info.pl 10011.mafft.ali
    # Nseqs	Min.len	Max.len	Avg.len	File
    # 32	4710	4710	4710	10011.mafft.ali

    cd ${PROJECTDIR}/genes
    get_fasta_info.pl *.fas 2>/dev/null | \
        sed 's/.fas//' > ../tmp/unaligned.info
    cd ${PROJECTDIR}/alignments
    get_fasta_info.pl *.ali 2>/dev/null | \
        sed 's/\.mafft.ali//' > ../tmp/aligned.info

    cd ${PROJECTDIR}/tmp
    join -j 5 unaligned.info aligned.info | \
        awk '{print $1,$3/$NF,$4/$NF,$5/$NF}' | \
        sort -r -k4
    # File  min/ali.len max/ali.len avg./ali.len
    # 10011 0.319958    1           0.916561

    # The idea is to see if, e.g., the ratio avg.len/ali.len is low

#### Try (iterative) OD-Seq

    cd ${PROJECTDIR}/alignments
    for f in *.mafft.ali ; do
        ${SRCDIR}/oi.sh "$f";
    done

    grep -h '>' *-odseq-filtered | sort | uniq -c | sort -n -r

    # TODO: realign the .mafft.ali-odseq-filtered files?

## Trees

    cd ${PROJECTDIR}/trees
    for f in ../alignments/*.mafft.ali-odseq-filtered ; do
        g=$(basename "$f")
        echo "iqtree.${g}"
        iqtree -s "$f" \
            -nt AUTO \
            -ntmax 10 \
            -m TEST \
            -pre "iqtree.${g}"
    done



