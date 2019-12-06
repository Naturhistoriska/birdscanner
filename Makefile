## Makefile for birdscanner, uppmax
## Last modified: fre dec 06, 2019  09:43
## Sign: JN

## Make sure you have the correct account nr (e.g. 'snic2019-1-234')
UPPNR :=

ifndef UPPNR
$(error UPPNR is not set. Please run \"make account UPPNR=snic1234-5-678\" \(use your account nr\) or edit the Makefile and the slurm/*.sh files and add your uppmax compute account nr. )
endif

## Minimum default alignment length
ALILENGTH := 200

## Time asked for in the nhmmer step
HMMERTIME := 40:00:00

## Some settings
SHELL := /bin/bash
NCPU  := 10

export NCPU

## Folders
PROJECTDIR   := $(shell pwd)
RUNDIR       := $(PROJECTDIR)/run
DATADIR      := $(PROJECTDIR)/data
OUTDIR       := $(PROJECTDIR)/out
SLURMDIR     := $(PROJECTDIR)/slurm
SRCDIR       := $(PROJECTDIR)/src
REFERENCEDIR := $(DATADIR)/reference
GENOMESDIR   := $(DATADIR)/genomes
PLASTDIR     := $(RUNDIR)/plast
HMMERDIR     := $(RUNDIR)/hmmer
SELECTEDDIR  := $(REFERENCEDIR)/selected

MKFILEPATH  := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILEDIR   := $(dir $(MKFILEPATH))

export PROJECTDIR

## Files
GENOMEFILES := $(wildcard $(GENOMESDIR)/*.gz)

ifndef GENOMEFILES
$(error GENOMEFILES is not set. Did you provide genome files in .gz format in data/genomes/ ?)
endif

REFFAS               := selected_shortlabel.degap.fas
PLASTQUERYSELECTEDFP := $(SELECTEDDIR)/$(REFFAS)
PLASTQUERYFP         := $(PLASTDIR)/$(REFFAS)

## Programs (need to be in place)
GREPFASTA     := $(SRCDIR)/grepfasta.pl
SPLITFAST     := $(SRCDIR)/splitfast_100K
PARSENHMMER   := $(SRCDIR)/parse_nhmmer.pl
NHMMERSLURM   := $(SRCDIR)/create_nhmmer_slurm_file.pl
REQUIRED_BINS := hmmpress nhmmer plast makeblastdb grepfasta.pl parallel pigz

## Check for programs. Need to be loaded using the module system on uppmax:
## `module load bioinfo-tools hmmer/3.2.1-intel blast/2.9.0+ gnuparallel pigz`
#$(foreach bin,$(REQUIRED_BINS),\
#	$(if $(shell command -v $(bin) 2> /dev/null),,$(error Error: could not find program `$(bin)`. Did you load/install it?)))

.PHONY: all refdata init splitfast plastdb plast readplast parseplast hmmer readhmmer parsehmmer clean distclean copytestdata

## Recepies
$(PLASTQUERYFP): $(PLASTQUERYSELECTEDFP)
	ln -sf $< $@ ; \
	test -s $@ || { echo "Error: empty file"; rm $@; exit 1; }

SPLITFILES := $(shell for name in $(GENOMEFILES); do n=$${name/data\/genomes/run\/plast}; echo $${n%%.*}.split.fas; done)

$(PLASTDIR)/%.split.fas: $(GENOMESDIR)/%.gz
	$(SPLITFAST) <(pigz -d -c $<) > $@ ; \
	test -s $@ || { echo "Error: empty file"; rm $@; exit 1; }

DBFILES := $(patsubst $(PLASTDIR)/%.split.fas,$(PLASTDIR)/%.split.fas.nin,$(SPLITFILES))

$(PLASTDIR)/%.split.fas.nin: $(PLASTDIR)/%.split.fas
	cd $(PLASTDIR); \
	makeblastdb -dbtype nucl -in $<

PLASTTABFILES := $(patsubst $(PLASTDIR)/%.split.fas,$(PLASTDIR)/%.selected.plast.tab,$(SPLITFILES))

$(PLASTDIR)/%.selected.plast.tab: $(PLASTDIR)/%.split.fas $(PLASTQUERYFP)
	plast -p plastn \
		-i $(PLASTQUERYFP) \
		-d $< \
		-o $@ \
		-a $(NCPU) \
		-max-hit-per-query 1 \
		-bargraph

SCAFFOLDIDS := $(patsubst $(PLASTDIR)/%.selected.plast.tab,$(PLASTDIR)/%.plast$(ALILENGTH).scaffolds.ids,$(PLASTTABFILES))

$(PLASTDIR)/%.plast$(ALILENGTH).scaffolds.ids: $(PLASTDIR)/%.selected.plast.tab
	awk '$$4>$(ALILENGTH)' $< | \
		perl -npe 's/-\w+//' | \
		sort -t$$'\t' -k1g -k12rg | \
		awk -F $$'\t' '!x[$$1]++' | \
		awk -F $$'\t' '{print $$2}' | \
		sort -u > $@ ; \
	test -s $@ || { echo "Error: empty file"; rm $@; exit 1; }

SEARCHFILES1 := $(patsubst $(PLASTDIR)/%.plast$(ALILENGTH).scaffolds.ids,$(PLASTDIR)/%.searchfile1,$(SCAFFOLDIDS))

$(PLASTDIR)/%.searchfile1: $(PLASTDIR)/%.plast$(ALILENGTH).scaffolds.ids
	sed -e 's/$$/\\s/' -e 's/^/\^>/' $< > $@ ; \
	test -s $@ || { echo "Error: empty file"; rm $@; exit 1; }

PLASTFASFILES := $(patsubst $(PLASTDIR)/%.split.fas,$(PLASTDIR)/%.plast$(ALILENGTH).fas,$(SPLITFILES))

$(PLASTDIR)/%.plast$(ALILENGTH).fas: $(PLASTDIR)/%.searchfile1 $(PLASTDIR)/%.split.fas
	$(GREPFASTA) -f $^ > $@ ; \
	test -s $@ || { echo "Error: empty file"; rm $@; exit 1; }

REFIDS := $(patsubst $(PLASTDIR)/%.selected.plast.tab,$(PLASTDIR)/%.plast$(ALILENGTH).ref.ids,$(PLASTTABFILES))

$(PLASTDIR)/%.plast$(ALILENGTH).ref.ids: $(PLASTDIR)/%.selected.plast.tab
	awk '$$4>$(ALILENGTH)' $< | \
		perl -npe 's/-\w+//' | \
		sort -t$$'\t' -k1g -k12rg | \
		awk -F $$'\t' '!x[$$1]++' | \
		awk -F $$'\t' '{print $$1}' > $@ ; \
	test -s $@ || { echo "Error: empty file"; rm $@; exit 1; }

SEARCHFILES2 := $(patsubst $(PLASTDIR)/%.plast$(ALILENGTH).ref.ids,$(PLASTDIR)/%.searchfile2,$(REFIDS))

$(PLASTDIR)/%.searchfile2: $(PLASTDIR)/%.plast$(ALILENGTH).ref.ids
	sed -e 's/\([0-9]\+\)/hmm\/\1\.sate/' $< > $@ ; \
	test -s $@ || { echo "Error: empty file"; rm $@; exit 1; }

SELECTEDHMMS := $(patsubst $(PLASTDIR)/%.searchfile2,$(HMMERDIR)/%.selected_concat.hmm,$(SEARCHFILES2))

$(HMMERDIR)/%.selected_concat.hmm: $(PLASTDIR)/%.searchfile2
	cat $$(find $(SELECTEDDIR)/hmm -type f -name \*.hmm | grep -f $<) > $@ ; \
	test -s $@ || { echo "Error: empty file"; rm $@; exit 1; }

HMMPRESSFILES := $(patsubst $(HMMERDIR)/%.hmm,$(HMMERDIR)/%.hmm.h3f,$(SELECTEDHMMS))

$(HMMERDIR)/%.hmm.h3f: $(HMMERDIR)/%.hmm
	cd $(HMMERDIR) ; \
	hmmpress $<

HMMEROUT := $(patsubst $(HMMERDIR)/%.selected_concat.hmm,$(HMMERDIR)/%.nhmmer.out,$(SELECTEDHMMS))

$(HMMERDIR)/%.nhmmer.out: $(SLURMDIR)/%.nhmmer.slurm.sh
	sbatch $< $(MKFILEDIR)

HMMEROUTDIR := $(patsubst $(HMMERDIR)/%.nhmmer.out,$(OUTDIR)/%_nhmmer_output/,$(HMMEROUT))

$(OUTDIR)/%_nhmmer_output/: $(HMMERDIR)/%.nhmmer.out
	perl $(PARSENHMMER) \
		-i $< \
		-g $(PLASTDIR)/$*.plast$(ALILENGTH).fas \
		-d $@ \
		-f $* \
		-p $*

$(SLURMDIR)/%.nhmmer.slurm.sh: $(HMMERDIR)/%.selected_concat.hmm
	perl $(NHMMERSLURM) \
		-o $@ \
		-g $(patsubst %.selected_concat.hmm,%,$(notdir $<)) \
		-a $(UPPNR) \
		-n $(NCPU) \
		-t $(HMMERTIME)

## Rules/tasks:

all: refdata init plast parseplast hmmer

account:
	sed -i 's/#UPPMAXACCOUNTNR#/$(UPPNR)/' $(SLURMDIR)/*.slurm.sh ; \
	sed -i '/^UPPNR/ s/$$/ $(UPPNR)/' $(lastword $(MAKEFILE_LIST))

refdata:
	$(MAKE) -C $(REFERENCEDIR)

init:
	$(MAKE) -j$(NCPU) splitfast plastdb

splitfast: $(SPLITFILES)

plastdb: $(DBFILES)

plast: $(PLASTTABFILES)

readplast: $(SCAFFOLDIDS) $(SEARCHFILES1) $(PLASTFASFILES) $(REFIDS) $(SEARCHFILES2) $(SELECTEDHMMS) $(HMMPRESSFILES)

parseplast:
	$(MAKE) -j$(NCPU) readplast

hmmer: $(HMMEROUT)

readhmmer: $(HMMEROUTDIR)

parsehmmer:
	$(MAKE) -j$(NCPU) readhmmer

clean:
	cd $(SELECTEDDIR) ; $(RM) *.tgz *.gz *.fas ; \
	cd $(SELECTEDDIR)/hmm ; $(RM) *.hmm ; \
	cd $(SELECTEDDIR) ; rm -r fas sto ; \
	cd $(HMMERDIR) ; $(RM) *.nhmmer.out *.selected_concat.hmm* *.sh ; \
	cd $(PLASTDIR) ; $(RM) *.fas *.ids *.searchfile* *.tab *.nhr *.nin *.nsq; \
	cd $(OUTDIR) ; rm -rf *_nhmmer_output ; \
	cd $(SLURMDIR) ; $(RM) *.err *.nhmmer.slurm.sh

distclean:
	cd $(GENOMESDIR) ; $(RM) *.gz ; \
	cd $(REFERENCEDIR)/fasta_files ; $(RM) *.fas ; \
	cd $(SELECTEDDIR) ; $(RM) *.tgz *.gz *.fas ; \
	cd $(SELECTEDDIR) ; rm -r fas sto ; \
	cd $(SELECTEDDIR)/hmm ; $(RM) *.hmm ; \
	cd $(HMMERDIR) ; $(RM) *.nhmmer.out *.selected_concat.hmm* *.sh ; \
	cd $(PLASTDIR) ; $(RM) *.fas *.ids *.searchfile* *.tab *.nhr *.nin *.nsq; \
	cd $(OUTDIR) ; rm -rf *_nhmmer_output \
	cd $(SLURMDIR) ; $(RM) *.err *.nhmmer.slurm.sh

## This will only work if you have the testdata folder
copytestdata:
	cp -v -u $(PROJECTDIR)/testdata/data/genomes/*.gz $(GENOMESDIR) ; \
	cp -v -u $(PROJECTDIR)/testdata/data/reference/fasta_files/*.fas $(REFERENCEDIR)/fasta_files

