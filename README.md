# BirdScanner

- Last modified: mån jun 17, 2019  04:40
- Sign: JN

**Disclaimer:** Work in progress, this is not the final version of the instructions.

## Description

Extract known genomic regions (based on multiple sequence alignments and HMMs) from genome- (scaffold) files.

![Workflow](doc/workflow/Diagram1.png)

## Suggested usage

### 0. Install prerequisites

The workflow is tested on Linux (Ubuntu 18.04, and CentOS Linux 7).
Specific packages that needs to be installed (in the `PATH`) are:
- nhmmer, hmmpress (HMMER 3.1b2)
- plast (v.2.3.1)
- makeblastdb (v.2.6.0+)
- grepfasta.pl (https://github.com/nylander/grepfasta)

### 1. Add genome data

Add compressed (`gzip`) genome files to the folder `data/genomes/`.
Files need to be named named (example) `<name>.gz`. The `<name>` should
be unique and will be used in the output as label for the extracted
sequences.

### 2. Add reference data

Reference data are a number of nucleotide sequence alignments in fasta format.
Please see the file `data/reference/README.md` for details.
When necessary files are in place, run (in the `/path/to/birdscanner` directory):

    [local]$ make refdata

### 3. Run the search workflow

I would recommend running the pipeline in steps. The "plast" step will
take approx 20 mins/genome, while the "nhmmer" step will take > ~30 h/per genome(!).
It would be recommend to run the nhmmer-step on, e.g., Uppmax.

Run initial similarity search:

    [local]$ make init
    [local]$ make plast
    [local]$ make parseplast

Run hmmer:

**Current ad-hoc steps**: Run hmmer on uppmax.uu.se!

Create files to be transferred:

    [local]$ make slurm

Copy file to uppmax:

    [local]$ scp run4uppmax.tgz rackham.uppmax.uu.se:.

Then log in to uppmax, clone the "birdscanner" repo:

    [uppmax]$ git clone https://github.com/Naturhistoriska/birdscanner.git

Move the run4uppmax.tgz to the "birdscanner" directory, and uncompress.

    [uppmax]$ mv ~/run4uppmax.tgz path/to/birdscanner
    [uppmax]$ tar xvzf path/to/birdscanner/run4uppmax.tgz

Run hmmer using the slurm files:

    [uppmax]$ cd path/to/birdscanner/run/hmmer
    [uppmax]$ for f in *.slurm.sh ; do sbatch "$f" /path/to/birdscanner; sleep 1 ; done

Parse hmmer output:

    [uppmax]$ make parsehmmer

### Results

Genome-specific results from the hmmer step are in folder `out/genomes/`,
gathered genes are in `out/genes/`.

## Further analysis

The gene files in `out/genes/` can be further analyzed (multiple sequence alignments,
phylogenetic tree reconstruction, etc). One such approach is described in the file
`run/README.trees.md`.

## Clean up

To remove all input- and output files (including the fasta files and the genome files):

    [uppmax]$ make distclean

