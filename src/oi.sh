#!/bin/bash

## Iterative OD-seq
## Last modified: ons apr 17, 2019  03:02
## Sign: JN

ncpu=10
nbootrep=10000


hash odseq 2>/dev/null || { echo >&2 "I require odseq but it's not installed in PATH. Aborting."; exit 1; }
odseq=$(which odseq)

hash grepfasta.pl 2>/dev/null || { echo >&2 "I require grepfasta.pl but it's not installed in PATH. Aborting."; exit 1; }
grepfasta=$(which grepfasta.pl)

if [[ $# -eq 0 ]] ; then
    echo "Usage: $0 fasta.file"
    exit 0
else
    infile="$1"
    if [ ! -e "${infile}" ]; then
        echo "File ${infile} not found."
        exit
    fi
fi

echo ""
echo -n "## "
date
echo "## Run iterative odseq on ${infile}"

i=0
j=1

fastafile="${infile}.ODSEQ.${i}"

if [ -e "${fastafile}" ] ; then
    echo "File $fastafile already exists. Exiting"
else
    #cp "${infile}" "$fastafile"
    ln -s "${infile}" "${fastafile}"
fi

while true ; do
    echo ""
    echo "## filtering: $fastafile"
    outliersfile="${fastafile}-outliers.txt"
    #$odseq -i $fastafile -o $outliersfile
    $odseq --boot-rep "${nbootrep}"  -t "${ncpu}" --full -i "${fastafile}" -o "${outliersfile}"
    FOUND=$(grep -c '>' "${outliersfile}")
    if [ "${FOUND}" -eq 0 ]; then
        if [ "${infile##*.}" = "fas" ] ; then
            newfile="${infile%.fas}.odseq-filtered.fas"
        else
            newfile="${infile}-odseq-filtered"
        fi
        mv "${fastafile}" "${newfile}"
        rm "${outliersfile}"
        break
    fi  
    grep '>' "${outliersfile}" | sed 's/>//' > ODSEQ.outl.list
    newfastafile="${fastafile%.*}.${j}"
    $grepfasta -f ODSEQ.outl.list -i "${fastafile}" > "${newfastafile}"
    rm ODSEQ.outl.list
    rm "${fastafile}"
    rm "${outliersfile}"
    fastafile="${newfastafile}"
    ((i++))
    ((j++))
done

echo ""
echo -n "## "
date
echo "## End of script"
echo "##"
echo -n "## Nseq in original file: "
grep -c '>' "${infile}"
echo -n "## Nseq in filtered file: "
grep -c '>' "${newfile}"
echo "##"
echo "## See file ${newfile}"

