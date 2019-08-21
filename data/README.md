# README in data birdscanner/data folder

- Last modified: ons aug 21, 2019  10:21
- Sign: JN

## Description

**Note:** The pipeline is, unfortunately, very picky about the format of both
file names and file content. Safest option is to make sure they are OK before
trying to run the analyses.

#### 1. Genomes

Add compressed (gzip) genome files (contig files in fasta format, nucleotide
data) to the folder `data/genomes/`. Files need to be named `<name>.gz`. The
`<name>` should contain no periods, and will be used in the output as part of
the fasta header for the extracted sequences. Examples: `apa_genome.gz`,
`bpa.gz` (but not, e.g., `apa.genome.fas.gz`, `bpa.tar.gz`, etc).

#### 2. Reference alignments

Add reference sequence alignments (nucleotides, fasta format, file suffix
`.fas`) in the folder `data/reference/fasta_files`. Each alignment file would
represent one genomic region ("gene"). The name of the alignment file will be
used in downstream analyses, so they should have names that are easy to parse
(do not use spaces or special characters in the file names). Examples:
`myo.fas`, `odc.fas`, `988.fas`, `999.fas`, etc. The fasta headers are also
used in downstream analyses and should also be easy to parse. Examples,
`>Passe`, `>Ploceu`, `>Prunell`. Fasta headers needs to be unique, but the
number of sequences doesn't need to be the same in all files.

From the pool of files in `data/reference/fasta_files`, a filtered selection is
placed in the `data/reference/selected` folder by the pipeline. These steps
where designed specifically for "The Jarvis data" (see below), and is currently
carried out using the commands in the
[`data/reference/Makefile`](data/reference/Makefile) (and executed by `make
refdata`). It may be possible to circumvent that step by manually creating the
necessary files (mostly untested).

We also provide filtered versions of the "Jarvis data". Please see the file
[`doc/Jarvis_et_al_2015/README.md`](../doc/Jarvis_et_al_2015/README.md).

