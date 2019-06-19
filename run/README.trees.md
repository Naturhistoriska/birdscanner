# Trees from the output of birdscanner

    # Last modified: ons jun 19, 2019  01:28
    # Sign: JN

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
        grepfasta.pl -f "${outg}" "${reffas}" | \
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

    cd ${ALIDIR}
    time for f in *.mafft.ali ; do
        ${SRCDIR}/oi.sh "$f";
    done
    # real	11m19,422s
    # user	24m24,693s
    # sys	38m42,497s

    grep -h '>' *-odseq-filtered | \
        sort | \
        uniq -c | \
        sort -n -r
    #   1422 >CnucorF
    #   1419 >CmacF
    #   1418 >CnucnuF
    #   1414 >CnucorM
    #   1410 >CcervNGM
    #   1409 >CgutcM
    #   1407 >CgutgM
    #   1404 >AsubF
    #   1401 >CcervF
    #   1401 >CcervAM
    #   1396 >AmacnuM
    #   1396 >Ainor
    #   1394 >Amacger
    #   1393 >Claut
    #   1391 >PnewM
    #   1390 >PnewF
    #   1384 >PvioviF
    #   1383 >Apapu
    #   1378 >SchryM
    #   1374 >SchryF
    #   1368 >PviomiM
    #   1338 >Aflavi
    #   1330 >SaureNRM
    #   1311 >SdenM
    #   1296 >AbucgeM
    #   1294 >AmeljoF
    #   1293 >AmelmeM
    #   1289 >AcrasF
    #   1279 >Amelas
    #   1195 >SbakeAMNH
    #   1110 >SaureAMNH
    #    872 >SardeRMNH
    #     20 >MANVI
    #     17 >ACACH


#### Remove "all-gap" positions

    cd ${ALIDIR}
    find -name '*.ali-odseq-filtered' | \
        parallel "${SRCDIR}/degap_fasta.pl {}"


## Trees

    mkdir -p ${TREEDIR}
    cd ${TREEDIR}
    time for f in ${ALIDIR}/*.mafft.ali-odseq-filtered.degap.fas ; do
        g=$(basename "$f" .fas)
        echo $g
        echo "iqtree.${g}"
        iqtree -s "$f" \
            -nt AUTO \
            -ntmax ${NCPU} \
            -m TEST \
            -pre "iqtree.${g}"
    done
    # real	1360m25,347s
    # user	2766m8,775s
    # sys	7m35,787s


## ASTRAL III

    mkdir -p ${ASTRALDIR}
    cd ${ASTRALDIR}
    indata=all.mafft.ali-odseq-filtered.degap.trees
    outdata=all.mafft.ali-odseq-filtered.degap.astral
    cat ${TREEDIR}/*.mafft.ali-odseq-filtered.degap.treefile > "${indata}"
    time astral -i "${indata}" -o "${outdata}"
    # real	0m18,594s
    # user	0m28,208s
    # sys	0m0,312s

