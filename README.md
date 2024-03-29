# Birdscanner (UPPMAX version)

- Last modified: fre dec 01, 2023  02:48
- Sign: JN

---
# *Note: A revised version of this workflow is available in another repository: [birdscanner2](https://github.com/nylander/birdscanner2)*
---

## Description

The workflow (Fig. \ref{workflow}) will try to extract known genomic regions
(based on multiple- sequence alignments and HMMs) from genome files. The
approach taken is essentially a search with HMM's against a reference genome,
with an extra step where an initial similarity search is used to reduce the
input data down to matching HMM's and genomic regions. Both the known genomic
regions (multiple nucleotide-sequence alignments in fasta format), and the
genome files (fasta format, one or several scaffolds) must be provided by the
user.

![Birdscanner workflow\label{workflow}](doc/workflow/Diagram1.png){width=60%}

The current version is made for running on "UPPMAX" (compute clusters Rackham
and Snowy, <https://www.uppmax.uu.se>).

The workflow is managed by the `make` program, and tasks are send to compute
units using the SLURM batch system implemented on UPPMAX.

## Prerequisites

The workflow is tested on GNU/Linux (Ubuntu 18.04 and CentOS 7), and uses
standard Linux (bash) tools. The current version is aimed for running on
UPPMAX, and hence it will load necessary software using the `module` system.
In addition, the software `plast` needs to be installed **by the user** from
the developer's site. Please see section [Software used](#software-used) below.

## Results

Individual gene files (fasta format) for each `genome` are written to the
folder `birdscanner/out/<genome>_nhmmer_output/`. If several genome-files are
used as input, a set of (unaligned) data matrices can also be extracted.

## Further analysis

The gene files in `out/<genome>_nhmmer_output/` can be further analyzed
(multiple sequence alignments, phylogenetic tree reconstruction, etc). One such
approach is described in the file [`run/README.trees.md`](run/README.trees.md).
Note that the exact approach needs to be tailored to your own needs.

## Steps to run the pipeline

The pipeline is currently run in steps. Each step will utilize multiple cores
on a compute cluster. Each step is described below. A couple of [Worked
Examples](#worked-examples) are given in the end.

### 1. Start by cloning birdscanner:

    [user@rackham ~]$ git clone https://github.com/Naturhistoriska/birdscanner.git
    [user@rackham ~]$ cd birdscanner

### 2. Add correctly named and formatted genome files and reference data to the `data` folder

See instructions in section [Indata](#indata) below.

### 3. Set your compute account number (e.g. 'snic1234-5-678') by running

    [user@rackham birdscanner]$ make account UPPNR=snic1234-5-678

### 4. Change directory to the `slurm` directory.

    [user@rackham birdscanner]$ cd slurm

Here you need to manually adjust (text edit) the time-asked-for in the SLURM
scripts.

As a rough estimate, the "plast" step will take approx 20-60 mins/genome, while
the "HMMer" step will take > ~30 h/per genome. This might be a starting point:

|Script                               |Current `-t` setting|Comment|
|-------------------------------------|--------------------|-------|
|`refdata_and_init_and_plast.slurm.sh`|01:00:00            |Change. Allow, say, 60 min x number of genomes?|
|`hmmer.slurm.sh`                     |40:00:00            |The time asked for is per genome and is *not* set by the `-t` option,|
|                                     |                    |but in the call to `make` (variable `HMMERTIME`)|
|`parsehmmer.slurm.sh`                |00:30:00            |30 min should be OK?|

### 5. Submit the first SLURM script:

    [user@rackham slurm]$ sbatch refdata_and_init_and_plast.slurm.sh

This step will attempt to read and reformat the reference data, create HMM's
for all alignments, perform a similarity search using plast, and finally
prepare a more restricted data for the next step. A brief progress report (as
well as any error messages) is printed to the file
`refdata_and_init_and_plast.err`. More details are written in the file
`refdata_and_init_and_plast.out`.

**Note:** as a default, only target scaffolds with plast hits longer than 200
bp will be used in consecutive steps. Depending on the quality of the genomes,
the user may want to lower this threshold (by changing the `ALILENGTH` parameter
in the main [`Makefile`](Makefile)). We have used a value of '50' with some
success.

### 6. When finished, submit the next:

    [user@rackham1 slurm]$ sbatch hmmer.slurm.sh

This step will attempt to submit several SLURM jobs to the scheduler, one for
each genome. This step is probably time consuming. A final report (as well as
any error messages) are printed to the file `hmmer.err`.

### 7. When finished, submit the last:

    [user@rackham1 slurm]$ sbatch parsehmmer.slurm.sh

This step will attempt to parse the results from HMMer and create separate
folders with found genomic regions in the `birdscanner/out` folder, one for
each genome. A final report (as well as any error messages) are printed to the
file `parsehmmer.err`.

### 8. Results

Individual gene files (fasta format) for each `genome` are written to the
folder `out/<genome>_nhmmer_output/`.

### 9. Clean up (optional)

All files generated by the different steps can be deleted using

    [user@rackham1 birdscanner]$ make clean

If you wish to remove all generated files, including your reference data and
genome files, use:

    [user@rackham1 birdscanner]$ make distclean

## Worked Examples

### 1. Using your own reference data set

This example assumes that you have your own reference data set, and genome
files available in local folder on UPPMAX. Note that genome files need to be
named "some_name.gz", e.g., "Otis_tarda.gz". Most importantly, the reference
data need to be formatted correctly. See the section [Reference
alignments](#2-reference-alignments) below.
Project directory `/proj/xyz123` needs to be substituted, as
well as the UPPMAX account ID `snic1234-5-678`.

    # Get birdscanner code
    [uppmax]$ cd /proj/xyz123
    [uppmax]$ git clone https://github.com/Naturhistoriska/birdscanner.git

    # Get (link or copy) genome files 
    [uppmax]$ cd /proj/xyz123/birdscanner/data/genomes
    [uppmax]$ ln -s /proj/xyz123/assemblies/*.gz .

    # Get (link or copy) the reference fasta alignments
    [uppmax]$ cd /proj/xyz123/birdscanner/data/reference/fasta_files
    [uppmax]$ ln -s /proj/xyz123/alignments/*.fas .

    # Run first step, changing some default parameters
    [uppmax]$ cd /proj/xyz123/birdscanner
    [uppmax]$ make account UPPNR=snic1234-5-678
    [uppmax]$ sed -i -e "s/ALILENGTH := 200/ALILENGTH := 50/" Makefile
    [uppmax]$ cd slurm
    [uppmax]$ sed -i -e 's/#SBATCH -t 01:00:00/#SBATCH -t 10:00:00/' refdata_and_init_and_plast.slurm.sh
    [uppmax]$ sbatch refdata_and_init_and_plast.slurm.sh
    # wait...

    # Run second step
    [uppmax]$ cd /proj/xyz123/birdscanner/slurm
    [uppmax]$ sbatch hmmer.slurm.sh
    # wait...

    # Run third step
    [uppmax]$ cd /proj/xyz123/birdscanner/slurm
    [uppmax]$ sbatch parsehmmer.slurm.sh
    # wait...

    # Gather genes from the out folder
    [uppmax]$ cd /proj/xyz123/birdscanner/
    [uppmax]$ perl src/gather_genes.pl --outdir=genes $(find out -mindepth 1 -type d)

### 2. Using a pre-formatted (Bird) reference data set

This example will use the pre-formatted ["Jarvis exons
data"](doc/Jarvis_et_al_2015/README.md), and genome files available in local
folder on UPPMAX. Note that genome files need to be named "some_name.gz", e.g.,
"Otis_tarda.gz". Project directory `/proj/xyz123` needs to be substituted, as
well as the UPPMAX account ID `snic1234-5-678`. Note that in contrast to the
previous example, we don't need to format fasta files and create hmms, so we
can directly go to the plast step (by using another SLURM script).

    # Get birdscanner code
    [uppmax]$ cd /proj/xyz123
    [uppmax]$ git clone https://github.com/Naturhistoriska/birdscanner.git

    # Get (link or copy) genome files 
    [uppmax]$ cd /proj/xyz123/birdscanner/data/genomes
    [uppmax]$ ln -s /proj/xyz123/assemblies/*.gz .

    # Get the reference genes (Jarvis exons)
    [uppmax]$ cd /proj/xyz123/birdscanner/data/reference
    [uppmax]$ rm -r selected
    [uppmax]$ wget -O selected.tgz "https://nrmcloud.nrm.se/s/QWqB2xASW4XDTFN/download"
    [uppmax]$ tar xfz selected.tgz && rm selected.tgz

    # Run first step, changing some default parameters
    [uppmax]$ cd /proj/xyz123/birdscanner
    [uppmax]$ make account UPPNR=snic1234-5-678
    [uppmax]$ sed -i -e "s/ALILENGTH := 200/ALILENGTH := 50/" Makefile
    [uppmax]$ cd slurm
    [uppmax]$ sed -i -e 's/#SBATCH -t 01:00:00/#SBATCH -t 10:00:00/' init_and_plast.slurm.sh
    [uppmax]$ sbatch init_and_plast.slurm.sh
    # wait...

    # Run second step
    [uppmax]$ cd /proj/xyz123/birdscanner/slurm
    [uppmax]$ sbatch hmmer.slurm.sh
    # wait...

    # Run third step
    [uppmax]$ cd /proj/xyz123/birdscanner/slurm
    [uppmax]$ sbatch parsehmmer.slurm.sh
    # wait...

    # Gather genes from the out folder
    [uppmax]$ cd /proj/xyz123/birdscanner/
    [uppmax]$ perl src/gather_genes.pl --outdir=genes $(find out -mindepth 1 -type d)

## Notes:

- Most problems in the run will probably be associated with file names and file
  formats.  Please pay close attention to any error messages, especially in the
  file `refdata_and_init_and_plast.out`.
- The [`Makefile`](Makefile) also have settings that may be changed before the
  run. Please see the first 60 lines if anything specific applies for your
  data.

## Indata

**Note:** The pipeline is, unfortunately, very picky about the format of both
file names and file content. Safest option is to make sure they are OK before
trying to run the analyses.

### 1. Genomes

Add compressed (gzip) genome files (contig files in fasta format, nucleotide
data) to the folder `data/genomes/`. Files need to be named `<name>.gz`. The
`<name>` should contain no periods, and will be used in the output as part of
the fasta header for the extracted sequences. Examples: `apa_genome.gz`,
`bpa.gz` (but not, e.g., `apa.genome.fas.gz`, `bpa.tar.gz`, etc).

### 2. Reference alignments

Add reference sequence alignments (nucleotides, fasta format, file suffix
`.fas`) in the folder `data/reference/fasta_files`. Each alignment file would
represent one genomic region ("gene"). The name of the alignment file will be
used in downstream analyses, so they should have names that are easy to parse
(do not use spaces or special characters, not even hyphens (`-`) in the file
names). Examples: `myo.fas`, `odc.fas`, `988.fas`, `999.fas`, etc. The fasta
headers are also used in downstream analyses and should also be easy to parse.
Examples, `>Passe`, `>Ploceu`, `>Prunell`. Use underscores (`_`) instead of
hyphens (`-`). Fasta headers needs to be unique (i.e., no duplicates in each
individual alignment), but the number of sequences doesn't need to be the same
in all files.

From the pool of files in `data/reference/fasta_files`, a filtered selection is
placed in the `data/reference/selected` folder by the pipeline. These steps
where designed specifically for "The Jarvis data" (see below), and is currently
carried out using the commands in the
[`data/reference/Makefile`](data/reference/Makefile) (and executed by `make
refdata`). It may be possible to circumvent that step by manually creating the
necessary files (mostly untested).

#### 2.2 Jarvis data

We also provide filtered versions of the "Jarvis data" ([Jarvis *et al*.
2015](doc/Jarvis_et_al_2015/Jarvis_et_al_2015.pdf)). If you wish to use any of
these data sets, it is recommend to download and uncompress the data
(`fasta_files.tgz`) directly inside the `birdscanner/data/reference/` folder,
and then continue with any data filtering steps, and finally proceed with the
first SLURM script (`refdata_and_init_and_plast.slurm.sh`).

If you wish to save some computational time, and use the "length-filtered" data
subsets, we also provide the necessary HMM's and reference fasta file.  It is
then recommended to download and uncompress the data (`selected.tgz`) directly
inside the `birdscanner/data/reference/` folder and proceed with the SLURM
script `init_and_plast.slurm.sh`.

Please see the file
[`doc/Jarvis_et_al_2015/README.md`](doc/Jarvis_et_al_2015/README.md) for full
description.

## Outdata

Individual `gene` files (fasta format) for each `genome` are written to the
folder `out/<genome>_nhmmer_output/`, with the default name
`<genome>.<gene>.fas`. The (default) fasta header contains the genome name:
`><genome>` and, in addition, some statistics from the HMMer search. The
default filenames and fasta header format can be changed by altering the call
to the script [`parse_nhmmer.pl`](src/parse_nhmmer.pl) inside the
[`Makefile`](Makefile) (line starting with `perl $(PARSENHMMER)`). This is
mostly untested, however.

If several genome files have been run, it should be possible to gather the
individual sequences and sort them into (unaligned) data matrices.  This can be
done by using the [`gather_genes.pl`](src/gather_genes.pl) script. See examples
at the end of the [Worked Examples](#worked-examples).

## Software used

- `make` (GNU Make 4.1)
- `grepfasta.pl` (provided, <https://github.com/nylander/grepfasta>)
- `hmmerbuild`, `hmmpress`, `nhmmer` (hmmer v.3.2.1, <http://hmmer.org/>)
- `makeblastdb` (ncbi-blast+ v.2.9.0+, <https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs>)
- `parallel` (<https://www.gnu.org/software/parallel/>)
- `pigz` (<https://zlib.net/pigz/>)
- [`plast`](#plast) (v.2.3.1, <https://plast.inria.fr/plast-algorithm/>)
- Custom scripts in [src/](src/)

### plast

The `plast` program needs to be installed locally on UPPMAX.
Here is one way (installing in user's own `bin` folder):

    wget http://plast.gforge.inria.fr/files/plastbinary_linux_v2.3.1.tar.gz
    tar xvzf plastbinary_linux_v2.3.1.tar.gz
    cp plastbinary_linux_20160121/build/bin/plast ~/bin/plast

Or, compile (on UPPMAX):

    module load cmake
    module load doxygen
    git clone https://github.com/PLAST-software/plast-library.git
    cd plast-library
    git checkout stable
    sed -i '98,99{s/^/#/}' CMakeLists.txt
    mkdir build
    cd build
    cmake ..
    make
    cp bin/PlastCmd ~/bin/plast

## License and copyright

Copyright (c) 2019-2023 Johan Nylander

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

