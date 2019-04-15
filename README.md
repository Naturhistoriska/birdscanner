# BirdScanner

- Last modified: Wed Apr 03, 2019  09:16AM
- Sign: JN

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
take approx 20 mins/genome, while the hmmer step will take ~30 h/per genome(!).
It would beneficiary to run the hmmer-step on, e.g., Uppmax.

    make init
    make plast
    make parseplast
    make hmmer
    make parsehmmer

### Results

Results are in folder `out`.
