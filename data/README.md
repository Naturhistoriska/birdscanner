# README in data birdscanner/data folder

- Last modified: tor aug 08, 2019  04:26
- Sign: JN

## Description

1. Genomes

Add compressed (gzip) genome files (contig files in fasta format, nt data) to
the folder `data/genomes/`.  Files need to be named named (example) <name>.gz.
The <name> should be unique and will be used in the output as label for the
extracted sequences.

2. Reference alignments

Add reference sequence alignments (nt, fasta format, file suffix `.fas`) in the
folder `data/reference/fasta_files`. Each alignment file would represent one
genomic region ("gene").  The name of the alignment file will be used in
downstream analyses, so they should have names that are easy to parse.
Examples: `myo.fas`, `odc.fas`, `988.fas`, `999.fas`, etc. Do not use spaces or
special characters in the file names. The fasta headers are also used in
downstream analyses and should also be easy to parse. For example, `>Passe`,
`>Ploceu`, `>Prunell`. Fasta headers needs to be unique, but the number of
sequences doesn't need to be the same in all files.

From the pool of files in `data/reference/fasta_files`, a filtered selection is
placed in the `data/reference/selected` folder by the pipeline. These steps
where designed specifically for "The Jarvis data", and is currently carried
out using the commands in the `birdscanner/data/reference/Makefile` (and
executed by `make refdata`). It may be possible to circumvent that step by
manually creating the necessary files (untested).

