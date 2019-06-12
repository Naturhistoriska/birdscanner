# README in data birdscanner/data folder

- Last modified: ons jun 12, 2019  01:35
- Sign: JN

## Description

1. Genomes

Add compressed (gzip) genome files (contig files in fasta format, nt data) to the folder `data/genomes/`.
Files need to be named named (example) <name>.gz.
The <name> should be unique and will be used in the output as label for the extracted sequences.

2. Reference alignments

Add reference sequence alignments (nt) in the folder `data/reference/fasta_files`.
The files can be further manipulated (filtered), and the files/sequences to actually be
used are to be placed in the `data/reference/selected` folder.
Documentation on how this can be done is currently work in progress.
Please see the file `data/reference/README.md`.

