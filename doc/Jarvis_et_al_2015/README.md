# Phylogenomic analyses data of the avian phylogenomics project.

- Last modified: tor aug 15, 2019  01:20
- Sign: JN

## Description

Genomic data sets from the publication [Jarvis et al. (2014)] [1], was downloaded and
polished into two sets; **Introns** and **Exons**.

These two data sets are avaialble for download here:

- [Exons, compressed folder "fasta_files.tgz", 70
  MB](https://owncloud.nrm.se/index.php/s/HaHin085YXvDQIf): 8,253 fasta files
  with 42--48 sequences per file, and seq length in the range of 99--15,777 bp.

        $ wget -O fasta_files.tgz "https://owncloud.nrm.se/index.php/s/HaHin085YXvDQIf/download"

- [Introns, compressed folder "fasta_files.tgz" 164
  MB](https://owncloud.nrm.se/index.php/s/AJ2jgQl3DZr6cs9): 11,013 fasta files
  with 38--48 sequences per file, and seq length in the range of 58--38,848 bp.

        $ wget -O fasta_files.tgz "https://owncloud.nrm.se/index.php/s/AJ2jgQl3DZr6cs9/download"


Description of the original data can be found here <http://gigadb.org/dataset/101041>,
and here <ftp://parrot.genomics.cn/gigadb/pub/10.5524/101001_102000/101041/readme.txt>.


## Further filtering and selection of alignments

When using sequences in searches using HMMer, it might be beneficial to filter
the files based on sequence length. This can be done in many ways. Here are
some examples using the combination of
[`get_fasta_info.pl`](https://github.com/nylander/get_fasta_info),
[`grepfasta.pl`](https://github.com/nylander/grepfasta),
`degap_fasta.pl`, `parallel`, and `awk`:

#### Example 1. Select alignments of certain lengths

Here we copy alignments of min. length 200, and max length 5,000 to a new folder.

    $ mkdir -p selected/one
    $ cp $(get_fasta_info.pl fasta_files/*.fas 2>/dev/null | \
        awk '$2 >= 200 && $2 <= 5000 {print $NF}') selected/one

#### Example 2. Select a subset of fasta headers

If you wish to select a subset of the taxa in the alignments,
one may do so by using, for example:

First, find all fasta headers

    $ grep -h '>' fasta_files/*.fas | sort -u | paste - - - -
    >ACACH	>ANAPL	>APAVI	>APTFO
    >BALRE	>BUCRH	>CALAN	>CAPCA
    >CARCR	>CATAU	>CHAPE	>CHAVO
    >CHLUN	>COLLI	>COLST	>CORBR
    >CUCCA	>EGRGA	>EURHE	>FALPE
    >FULGL	>GALGA	>GAVST	>GEOFO
    >HALAL	>HALLE	>LEPDI	>MANVI
    >MELGA	>MELUN	>MERNU	>MESUN
    >NESNO	>NIPNI	>OPHHO	>PELCR
    >PHACA	>PHALE	>PHORU	>PICPU
    >PODCR	>PTEGU	>PYGAD	>STRCA
    >TAEGU	>TAUER	>TINMA	>TYTAL

Create a file with the headers you wish to extract:

    $ echo -e "FULGL\nGALGA\nGAVST\nGEOFO" > searchfile.txt

Create output folder:

    $ mkdir -p selected/two

Get the selected sequences from the files:

    $ find fasta_files -name '*.fas' | \
        parallel "grepfasta.pl -f=searchfile.txt {} > selected/two/{/}"

Note that not all original files contains all headers!

    $ get_fasta_info.pl selected/two/*.fas

Keep only files with four sequences:

    $ rm -v $(get_fasta_info.pl selected/two/*.fas 2>/dev/null | \
        awk '$1 != 4 {print $NF}')

Note that many/most of the alignments now contain "all-gap" columns!
Those can be removed using, for example:

    $ find selected/two -name '*.fas' | \
        parallel "degap_fasta.pl -o={.}.degap {}"
    $ find selected/two -name '*.degap' | \
        parallel "mv {} {.}.fas"

#### Example 3. Combine the above (examples 1. and 2.)

    $ mkdir -p selected/fas
    $ echo -e "FULGL\nGALGA\nGAVST\nGEOFO" > searchfile.txt
    $ find fasta_files -name '*.fas' | \
        parallel "grepfasta.pl -f=searchfile.txt {} > selected/fas/{/}"
    $ find selected/fas -name '*.fas' | \
        parallel "degap_fasta.pl -o={.}.degap {}"
    $ find selected/fas -name '*.degap' | \
        parallel "mv {} {.}.fas"
    $ rm -v $(get_fasta_info.pl selected/fas/*.fas 2>/dev/null | \
        awk '$1 != 4 || $2 < 200 || $2 > 5000  {print $NF}')


## How the Introns and Exons data sets were prepared

Custom scripts are from [https://github.com/Naturhistoriska/birdscanner](https://github.com/Naturhistoriska/birdscanner).

    SCRDIR=/path/to/birdscanner/src

### Exons (download file link [2])

    $ wget ftp://parrot.genomics.cn/gigadb/pub/10.5524/101001_102000/101041/FASTA_files_of_loci_datasets/Filtered_sequence_alignments/8295_Exons/pep2cds-filtered-sate-alignments-noout.tar.gz

    $ tar -I pigz -xvf pep2cds-filtered-sate-alignments-noout.tar.gz

    $ cd 8000orthologs

    $ mkdir -p fasta_files

    $ find * -name 'sate.default.pep2cds.removed.noout.aligned' | \
        parallel "cp {} fasta_files/{//}.{/}"

    $ find fasta_files -type f -name '*.aligned' | \
        parallel "sed -i 's/?/N/g' {}"

    $ find fasta_files -type f -name '*.aligned' | \
        parallel "${SRCDIR}/remove_gapped_seqs_in_fasta.pl -N {} ; rm {}"

    $ find fasta_files -type f -name '*.degapped.fas' | \
        parallel "${SRCDIR}/degap_fasta.pl -o={.} {} ; rm {}"

    $ find fasta_files -type f -name '*.degapped' | \
        parallel "sed -i '/^$/d' {}"

    $ find fasta_files -type f -name '*.degapped' | \
        parallel "mv {} {.}.fas"


### Introns (download file link [3])

    $ wget ftp://parrot.genomics.cn/gigadb/pub/10.5524/101001_102000/101041/FASTA_files_of_loci_datasets/Filtered_sequence_alignments/2516_Introns/introns-filtered-sate-alignments-with-and-without-outgroups.tar.gz

    $ tar -I pigz -xvf introns-filtered-sate-alignments-with-and-without-outgroups.tar.gz

    $ cd 2500orthologs

    # Intron files comes in one fasta file ("sate.removed.intron.noout.aligned-allgap.filtered"),
    # with partitions defined in another ("sate.removed.intron.noout-allgap.filtered.part").
    # Here we split the fasta file in parts. Output are named <part_id>.<intron_id>.fas

    $ perl ${SRCDIR}/extract_part_genes.pl
 
    $ find "fasta_files" -type f -name '*.fas' | \
        parallel "sed -i 's/?/N/g' {}"

    $ find fasta_files -type f -name '*.fas' | \
        parallel "${SRCDIR}/remove_gapped_seqs_in_fasta.pl -N {} ; rm {}"

    $ find fasta_files -type f -name '*.degapped.fas' | \
        parallel "${SRCDIR}/degap_fasta.pl -o={.} {} ; rm {}"

    $ find fasta_files -type f -name '*.degapped' | \
        parallel "sed -i '/^$/d' {}"
    
    $ find fasta_files -type f -name '*.degapped' | \
        parallel "mv {} {.}.fas"


## References

[1]: Jarvis ED; Mirarab S; Aberer AJ; Houde P; Li C; Ho SYW; Faircloth BC; Nabholz B; Howard JT; Suh A; Weber CC; da Fonseca RR; Alfaro-Nunez A; Narula N; Liu L; Burt DW; Ellegren H; Edwards SV; Stamatakis A; Mindell DP; Cracraft J; Braun EL; Warnow T; Wang J; Gilbert MTP; Zhang G (2014): Phylogenomic analyses data of the avian phylogenomics project. GigaScience Database. <http://dx.doi.org/10.5524/101041>
[2]: <ftp://parrot.genomics.cn/gigadb/pub/10.5524/101001_102000/101041/FASTA_files_of_loci_datasets/Filtered_sequence_alignments/8295_Exons/pep2cds-filtered-sate-alignments-noout.tar.gz>
[3]: <ftp://parrot.genomics.cn/gigadb/pub/10.5524/101001_102000/101041/FASTA_files_of_loci_datasets/Filtered_sequence_alignments/2516_Introns/introns-filtered-sate-alignments-with-and-without-outgroups.tar.gz>
