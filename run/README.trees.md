# Trres from the output of birdscanner

    # - Last modified: ons apr 24, 2019  08:34
    # - Sign: JN

## Setup

    PROJECTDIR='/home/nylander/run/pe/birdscanner'
    DATADIR="$PROJECTDIR/data"
    REFERENCEDIR="$DATADIR/reference"
    GENESDIR="${PROJECTDIR}/out/genes"
    ALIDIR="${PROJECTDIR}/run/alignments"
    TREEDIR="${PROJECTDIR}/run/trees"
    ASTRALDIR="${PROJECTDIR}/run/astral"
    SRCDIR="$PROJECTDIR/src"
    JARVISDIR="/home/nylander/run/pe/Jarvis_et_al_2014/FASTA_files_of_loci_datasets/Filtered_sequence_alignments/2516_Introns/2500orthologs"
    NCPU=10

## Get outgroup

    # Need to look for
    #   "ACACH	Rifleman	Acanthisitta_chloris"
    #   "MANVI	Golden-collared_Manakin	Manacus_vitellinus"
    # cd "${JARVISDIR}"
    # OUTGRPFILE="filter.txt"
    # perl -e 'print "ACACH\nMANVI\n"' > "${FILTFILE}"
    # FILTERED="${DATADIR}/reference/fasta_files"
    # mkdir -p "${FILTERED}"
    # for f in $(find -name 'sate.removed.intron.noout.aligned-allgap.filtered') ; do
    #     d=$(dirname "${f}" | sed 's/^\.\///')
    #     g=$(basename "${f}")
    #     h="${FILTERED}/${d}.${g}.fas"
    #     fastagrep -t -f "${OUTGRPFILE}" "${f}" | sed '/^$/d' > "${h}"
    # done
    # rm "${OUTGRPFILE}"


## Add outgroup

    # Need to look for
    #   "ACACH	Rifleman	Acanthisitta_chloris"
    #   "MANVI	Golden-collared_Manakin	Manacus_vitellinus"

    cd ${PROJECTDIR}
    mkdir -p "${ALIDIR}" 
    outg="${ALIDIR}/tmp.outgroups.txt"
    perl -e 'print "ACACH\nMANVI\n"' > "${outg}"
    for f in ${GENESDIR}/*.fas ; do
        nr=$(basename "${f}" .fas)
        reffas="${REFERENCEDIR}/fasta_files/${nr}.sate.removed.intron.noout.aligned-allgap.filtered.fas"
        fastagrep -t -f "${outg}" "${reffas}" | \
            sed '/^$/d' | \
            ${SRCDIR}/remove_gaps_in_fasta.pl > "${ALIDIR}/tmp.${nr}.outgrp.seq"
        aliin="${ALIDIR}/${nr}.outgrp.input"
        cat "${ALIDIR}/tmp.${nr}.outgrp.seq" "${f}" | \
            "${SRCDIR}/fasta_unwrap.pl" | \
            "${SRCDIR}/fasta_wrap.pl" > "${aliin}"
        rm "${ALIDIR}/tmp.${nr}.outgrp.seq"
    done
    rm "${outg}"

##  Align gene files

    # Try mafft (MAFFT v7.310)
    cd "${ALIDIR}"
    time for f in *.input ; do
        g="${f%.input}.mafft.ali"
        aliout="${ALIDIR}/$(basename "$g")"
        mafft --auto --thread ${NCPU} "${f}" > "${aliout}"
    done
    # real	55m22,108s
    # user	231m26,448s
    # sys	48m37,191s


### Evaluate alignments

    # $ get_fasta_info.pl 10011.fas
    # Nseqs	Min.len	Max.len	Avg.len	File
    # 32	1507	4710	4317	10011.fas
    # $ get_fasta_info.pl 10011.mafft.ali
    # Nseqs	Min.len	Max.len	Avg.len	File
    # 32	4710	4710	4710	10011.mafft.ali

    mkdir -p ${PROJECTDIR}/tmp
    cd ${ALIDIR}
    get_fasta_info.pl *.input 2>/dev/null | \
        sed 's/\.outgrp\.input//' > ${PROJECTDIR}/tmp/unaligned.info
    get_fasta_info.pl *.ali 2>/dev/null | \
        sed 's/\.outgrp\.mafft.ali//' > ${PROJECTDIR}/tmp/aligned.info

    cd ${PROJECTDIR}/tmp
    join -j 5 unaligned.info aligned.info | \
        awk '{print $1,$3/$NF,$4/$NF,$5/$NF}' | \
        sort -r -k4

#### Try (iterative) OD-Seq

# ons 24 apr 2019 08:34:45:

    cd ${ALIDIR}
    time for f in *.mafft.ali ; do
        ${SRCDIR}/oi.sh "$f";
    done
    grep -h '>' *-odseq-filtered | \
        sort | \
        uniq -c | \
        sort -n -r
    # 1422 >CnucorF
    # 1418 >CnucnuF
    # 1418 >CmacF
    # 1413 >CnucorM
    # 1410 >CgutcM
    # 1410 >CcervNGM
    # 1407 >CgutgM
    # 1405 >AsubF
    # 1402 >CcervF
    # 1401 >CcervAM
    # 1397 >AmacnuM
    # 1397 >Ainor
    # 1395 >Amacger
    # 1393 >Claut
    # 1392 >PnewM
    # 1391 >PnewF
    # 1384 >PvioviF
    # 1382 >Apapu
    # 1377 >SchryM
    # 1372 >SchryF
    # 1366 >PviomiM
    # 1337 >Aflavi
    # 1329 >SaureNRM
    # 1311 >SdenM
    # 1295 >AbucgeM
    # 1293 >AmeljoF
    # 1291 >AmelmeM
    # 1288 >AcrasF
    # 1277 >Amelas
    # 1194 >SbakeAMNH
    # 1109 >SaureAMNH
    #  868 >SardeRMNH

    # TODO: realign the .mafft.ali-odseq-filtered files?

## Trees

    mkdir -p ${TREEDIR}
    cd ${TREEDIR}
    time for f in {ALIDIR}/*.mafft.ali-odseq-filtered ; do
        g=$(basename "$f")
        echo "iqtree.${g}"
        iqtree -s "$f" \
            -nt AUTO \
            -ntmax ${NCPU} \
            -m TEST \
            -pre "iqtree.${g}"
    done


### ASTRAL III

    mkdir -p ${ASTRALDIR}
    cd ${ASTRALDIR}
    cat ${TREEDIR}/*.mafft.ali-odseq-filtered.treefile > all.mafft.ali-odseq-filtered.trees
    time astral -i all.mafft.ali-odseq-filtered.trees -o all.mafft.ali-odseq-filtered.astral
    # real	0m18,594s
    # user	0m28,208s
    # sys	0m0,312s


