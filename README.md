# BirdScanner

- Last modified: fre apr 26, 2019  08:41
- Sign: JN

**Disclaimer:** Work in progress, this is not the final version of the instructions.

## Description

Extract known genomic regions from scaffold-files.

![Workflow](doc/workflow/Diagram1.png)

## Suggested usage

### Add genome data

Add compressed (`gzip`) genome files to the folder `data/genomes/`.
Files need to be named named (example) `<name>.gz`. The `<name>` should
be unique and will be used in the output as label for the extracted
sequences.

### Run the workflow

I would recommend running the pipeline in steps. The "plast" step will
take approx 20 mins/genome, while the "nhmmer" step will take > ~30 h/per genome(!).
It would recommend to run the nhmmer-step on, e.g., Uppmax.

    make init
    make plast
    make parseplast

Current ad-hoc step: transfer files and run the nhmmer step on Uppmax

    #make hmmer
    make parsehmmer

### Results

Genome-specific results from the hmmer step are in folder `out/genomes/`,
gathered genes are in `out/genes/`.

## Further analysis

The gene files in `out/genes/` can be further analyzed (multiple sequence alignments,
phylogenetic tree reconstruction, etc). One such approach is described in the file
`run/README.trees.md`.
