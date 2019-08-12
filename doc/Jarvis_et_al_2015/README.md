# Phylogenomic analyses data of the avian phylogenomics project.

- Last modified: 08/12/2019 10:05:26 AM
- Sign: JN

## Description

Genomic data sets from the publication [Jarvis et al. (2014)] [1], was downloaded and
polished into two sets; **Introns** and **Exons**.

These two data sets are avaialble for download here:

- [Exons, compressed folder "fasta_files.tgz", 70 MB](https://owncloud.nrm.se/index.php/s/HaHin085YXvDQIf)

        wget -O fasta_files.tgz "https://owncloud.nrm.se/index.php/s/HaHin085YXvDQIf/download"

- [Introns, compressed folder "fasta_files.tgz" 164 MB](https://owncloud.nrm.se/index.php/s/AJ2jgQl3DZr6cs9)

        wget -O fasta_files.tgz "https://owncloud.nrm.se/index.php/s/AJ2jgQl3DZr6cs9/download"


Description of the original data can be found here <http://gigadb.org/dataset/101041>,
and here <ftp://parrot.genomics.cn/gigadb/pub/10.5524/101001_102000/101041/readme.txt>.

The final data includes many fasta files with number of sequences per file in
the range 38--48 for Introns, and 42--48 for Exons. The sequence length varies
from 58--38,848 bp for Introns, and 99--15,777 bp for Exons.

When using sequences in searches using HMMer, it might be beneficial to filter
the files based on sequence length. This can be done in many ways. Here is an
example using the combination of
[`get_fasta_info.pl`](https://github.com/nylander/get_fasta_info)
and `awk`:

    get_fasta_info.pl fasta_files/*.fas  2>/dev/null | \
        awk '$2 >= 200 && $2 <= 5000 {print $5}'


## Data preparation

Custom scripts are from [https://github.com/Naturhistoriska/birdscanner](https://github.com/Naturhistoriska/birdscanner).

    SCRDIR=/path/to/birdscanner/src

### Exons (download file link [2])

    wget ftp://parrot.genomics.cn/gigadb/pub/10.5524/101001_102000/101041/FASTA_files_of_loci_datasets/Filtered_sequence_alignments/8295_Exons/pep2cds-filtered-sate-alignments-noout.tar.gz

    tar -I pigz -xvf pep2cds-filtered-sate-alignments-noout.tar.gz

    cd 8000orthologs

    mkdir -p fasta_files

    find * -name 'sate.default.pep2cds.removed.noout.aligned' | \
        parallel "cp {} fasta_files/{//}.{/}"

    find fasta_files -type f -name '*.aligned' | \
        parallel "sed -i 's/?/N/g' {}"

    find fasta_files -type f -name '*.aligned' | \
        parallel "${SRCDIR}/remove_gapped_seqs_in_fasta.pl -N {} ; rm {}"

    find fasta_files -type f -name '*.degapped.fas' | \
        parallel "${SRCDIR}/degap_fasta.pl {} ; rm {}"

    find fasta_files -type f -name '*.degapped.degap.fas' | \
        parallel "sed -i '/^$/d' {}"

    find fasta_files -type f -name '*.degapped.degap.fas' | \
        parallel "mv {} {= s:\.degapped\.degap\.fas$:: =}.fas"


### Introns (download file link [3])

    wget ftp://parrot.genomics.cn/gigadb/pub/10.5524/101001_102000/101041/FASTA_files_of_loci_datasets/Filtered_sequence_alignments/2516_Introns/introns-filtered-sate-alignments-with-and-without-outgroups.tar.gz

    tar -I pigz -xvf introns-filtered-sate-alignments-with-and-without-outgroups.tar.gz

    cd 2500orthologs

    # Intron files comes in one fasta file ("sate.removed.intron.noout.aligned-allgap.filtered"),
    # with partitions defined in another ("sate.removed.intron.noout-allgap.filtered.part").
    # Here we split the fasta file in parts. Output are named <part_id>.<intron_id>.fas

    perl ${SRCDIR}/extract_part_genes.pl
 
    find "fasta_files" -type f -name '*.fas' | \
        parallel "sed -i 's/?/N/g' {}"

    find fasta_files -type f -name '*.fas' | \
        parallel "${SRCDIR}/remove_gapped_seqs_in_fasta.pl -N {} ; rm {}"

    find fasta_files -type f -name '*.degapped.fas' | \
        parallel "${SRCDIR}/degap_fasta.pl {} ; rm {}"

    find fasta_files -type f -name '*.degapped.degap.fas' | \
        parallel "sed -i '/^$/d' {}"
    
    find fasta_files -type f -name '*.degapped.degap.fas' | \
        parallel "mv {} {= s:\.degapped\.degap\.fas$:: =}"


## References

[1]: Jarvis ED; Mirarab S; Aberer AJ; Houde P; Li C; Ho SYW; Faircloth BC; Nabholz B; Howard JT; Suh A; Weber CC; da Fonseca RR; Alfaro-Nunez A; Narula N; Liu L; Burt DW; Ellegren H; Edwards SV; Stamatakis A; Mindell DP; Cracraft J; Braun EL; Warnow T; Wang J; Gilbert MTP; Zhang G (2014): Phylogenomic analyses data of the avian phylogenomics project. GigaScience Database. <http://dx.doi.org/10.5524/101041>
[2]: <ftp://parrot.genomics.cn/gigadb/pub/10.5524/101001_102000/101041/FASTA_files_of_loci_datasets/Filtered_sequence_alignments/8295_Exons/pep2cds-filtered-sate-alignments-noout.tar.gz>
[3]: <ftp://parrot.genomics.cn/gigadb/pub/10.5524/101001_102000/101041/FASTA_files_of_loci_datasets/Filtered_sequence_alignments/2516_Introns/introns-filtered-sate-alignments-with-and-without-outgroups.tar.gz>
