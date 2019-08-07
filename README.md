# BirdScanner on Uppmax

- Last modified: ons aug 07, 2019  05:25
- Sign: JN

**Disclaimer:** Work in progress, this is not the final version of the instructions.

## Description

The workflow will try to extract known genomic regions (based on multiple sequence 
alignments (user provided) and HMMs) from genome- (scaffold) files (aslo user provided).
The approach taken is esentially a search with HMM's against a reference genome, with an
extra step where an initial similarity search (using plast) is used to reduce the input
data to hmm's and genomic regions having hits by the inital similarity search.

![Workflow](doc/workflow/Diagram1.png)


The current version is made for running on ``Uppmax'' (compute clusters rackham and snowy
<https://www.uppmax.uu.se>).

The workflow is managed by the `make` program, and tasks are send to compute units using
the ``SLURM'' batch system implemented on Uppmax.

## Prerequisites

The workflow uses standard Linux (`bash`) tools, and in addition, the slurm scripts will load
necessary software using the `module` system. In addition, the software `plast` needs to be
installed by the user from the develper's site. Please see section **Software used** below.

## Steps to run the pipeline

##### 1. Start by cloning birdscanner:

    [user@rackham ~]$ git clone https://github.com/Naturhistoriska/birdscanner.git
    [user@rackham ~]$ cd birdscanner

##### 2. Set your compute account nr (e.g. 'snic1234-5-678') by running

    [user@rackham birdscanner]$ make account UPPID=snic1234-5-678

##### 3. Add correctly named and formatted genome files and reference data to the `data` folder

See instructions in `data/README.md`.

##### 4. Change directory to the `slurm` directory.

    [user@rackham birdscanner]$ cd slurm

Here you need to manually adjust (text edit) the time asked for in the slurm scripts.

 *Vague instructions*: The "plast" step will take approx 20 mins/genome, while 
 the "hmmer" step will take > ~30 h/per genome. This might be a starting point:

|Script|Current `-t` setting|Comment|
|------|--------------------|-------|
|refdata.slurm.sh|00:10:00||
|init.slurm.sh|00:10:00||
|plast.slurm.sh|00:20:00||
|parseplast.slurm.sh|00:10:00||
|hmmer.slurm.sh|00:05:00|The time asked for is actually set in another file (default 40h)|
|parsehmmer.slurm.sh|00:05:00||

##### 5. Change directory to the `slurm` folder, and submit the first slurm script:

    [user@rackham birdscanner]$ cd slurm
    [user@rackham slurm]$ sbatch refdata.slurm.sh

This step will attempt to read and reformat the reference data, and also create hmm's
for all alignments found.
A final report (as well as any error messages) are printed to the file `refdata.err`.

##### 6. When finished, submit the next:

    [user@rackham slurm]$ sbatch init.slurm.sh

This step will attempt to reformat genome files and XXXXXX.
A final report (as well as any error messages) are printed to the file `init.err`.

##### 7. When finished, submit the next:

    [user@rackham slurm]$ sbatch plast.slurm.sh

This step will attempt to initiate the similarity search 
A final report (as well as any error messages) are printed to the file `plast.err`.

##### 8. When finished, submit the next:

    [user@rackham slurm]$ sbatch parseplast.slurm.sh

This step will attempt to read the outpu from the similarity search, and prepare XXXXXXXX.
A final report (as well as any error messages) are printed to the file `parseplast.err`.

##### 9. When finished, submit the next:

    [user@rackham1 birdscanner]$ sbatch hmmer.slurm.sh

This step will attempt to submit several slurm jobs to the scheduler, one for each genome.
This step is probably time consuming.
A final report (as well as any error messages) are printed to the file `hmmer.err`.

##### 10. When finished, submit the last:

    [user@rackham1 birdscanner]$ sbatch parsehmmer.slurm.sh

This step will attempt to parse the results from hmmer and create separate folders with found
genomic regions in the `birdscanner/out` folder, one for each genome.
A final report (as well as any error messages) are printed to the file `parsehmmer.err`.


## Notes:

- The steps 5--8 can most probably be combined (untested at this stage), hence resulting in
three logical steps ("prepare data and run plast", "run and wait for nhmmer", "parse hmmer").


## Software used

- GNU Make 4.1
- nhmmer, hmmerpress (hmmer 3.2.1)
- makeblastdb (blast+ 2.7.1)
- gnuparallel ()
- grepfasta.pl (<https://github.com/nylander/grepfasta>)
- custom scripts in `birdscanner/src/`
- plast v2.3.1 ()

The `plast` program needs to be installed locally on uppmax.
Here is one way (installing in user's own `bin` folder):

    wget http://plast.gforge.inria.fr/files/plastbinary_linux_v2.3.1.tar.gz
    tar xvzf plastbinary_linux_v2.3.1.tar.gz
    cp plastbinary_linux_20160121/build/bin/plast ~/bin/plast

Or, compile (on uppmax):

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

