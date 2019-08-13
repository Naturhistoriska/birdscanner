# Makefile for birdscanner reference data preparation
#
# Last modified: tis aug 13, 2019  03:18
# Sign: JN
#
# Usage:
# 1) Add reference data (nt alignments in fasta format, files ending in '.fas', no periods in file names)'
#    in birdscanner/data/reference/fasta_files (file ending `.fas`, no periods in file name).
# 2) Call this Makefile from the root Makefile as such
#     cd /path/to/birdscanner && make reference
# Note: PROJECTDIR, NCPU will be inheritade from the root Makefile


#### Setup 
ifndef PROJECTDIR
$(error PROJECTDIR is not set. Need to run this makefile from root makefile.)
endif

DATADIR      := $(PROJECTDIR)/data
REFERENCEDIR := $(DATADIR)/reference
SELECTED     := $(REFERENCEDIR)/selected
GENOMESDIR   := $(DATADIR)/genomes
SRCDIR       := $(PROJECTDIR)/src

.PHONY: linebreaks fastafiles trim1 trim2 trim3 tosto buildhmms concat degapandwrap compress

all: linebreaks fastafiles trim1 trim2 trim3 tosto buildhmms concat degapandwrap compress

#### If needed, convert line breaks to unix
linebreaks:
	find "$(REFERENCEDIR)/fasta_files" -type f -name '*.fas' | \
		parallel -j $(NCPU) "sed -i 's/.$$//' {}"

#### Select which sequences, and which fasta files to be used ("selected"). If no filtering (as in example below), all files and sequences can be used.
fastafiles:    
	mkdir -p "$(SELECTED)/fas" && \
	cp $(REFERENCEDIR)/fasta_files/*.fas "$(SELECTED)/fas"

#### Replace '?' with 'N'
trim1:
	find "$(SELECTED)/fas" -type f -name '*.fas' | \
		parallel -j $(NCPU) "sed -i 's/?/N/g' {}"

trim2:
	find "$(SELECTED)/fas" -type f -name '*.fas' | \
		parallel -j $(NCPU) "$(SRCDIR)/degap_fasta.pl -o={}.degap.fas {}"

trim3:
	find "$(SELECTED)/fas" -type f -name '*.degap.fas' | \
		parallel -j $(NCPU) "sed -i '/^$$/d' {}"

#### Fasta to Stockholm format conversion
tosto: 
	mkdir -p "$(SELECTED)/sto" && \
	cd "$(SELECTED)/fas" && \
	find . -type f -name '*.degap.fas' | \
		parallel -j $(NCPU) "$(SRCDIR)/fasta2stockholm.pl {} > $(SELECTED)/sto/{.}.sto"

#### Build hmms
buildhmms:
	mkdir -p $(SELECTED)/hmm && \
	cd $(SELECTED)/sto && \
	find . -type f -name '*.sto' | \
		parallel -j $(NCPU) "hmmbuild $(SELECTED)/hmm/{.}.hmm {}"

#### Create concatenated fasta file for superficial searching
concat:
	cd $(SELECTED) && \
	for f in fas/*.degap.fas ; do \
		export f ; \
		h=$$(f=$$f perl -e 'print"$$1"if($$ENV{f}=~/^fas\/(\w+)\./)') ; \
		echo $$h ; \
		h=$$h f=$$f perl -e '$$f=shift;open(F,"<",$$ENV{f});while(<F>){if(/>/){$$_=~s/>(\w+)$$/>$$ENV{h}-$$1/;print;}else{print;}}close(F);' >> $(SELECTED)/selected_shortlabel.fas ;\
	done


#### Degap and wrap
degapandwrap:
	$(SRCDIR)/remove_gaps_in_fasta.pl $(SELECTED)/selected_shortlabel.fas | \
		$(SRCDIR)/fasta_unwrap.pl | \
		$(SRCDIR)/fasta_wrap.pl > $(SELECTED)/selected_shortlabel.degap.fas

#### Compress some files
compress:
	cd $(SELECTED) && \
	tar -I pigz -cf fas.tgz fas && rm -r fas/ ; \
	tar -I pigz -cf sto.tgz sto && rm -r sto/ ;\
	pigz selected_shortlabel.fas

