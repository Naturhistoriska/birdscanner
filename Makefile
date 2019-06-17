# Makefile for birdscanner
# Last modified: mån jun 17, 2019  04:43
# Sign: JN


# Directories (need to be in place)
#
# birdscanner 
# ├── data
# │   ├── genomes
# │   └── reference
# │       ├── fasta_files
# │       └── selected
# │           └── hmm
# ├── doc
# │   └── workflow
# ├── out
# ├── run
# │   ├── hmmer
# │   └── plast
# └── src


# Some settings
SHELL := /bin/bash
NCPU      := 10
ALILENGTH := 200
REFFAS := selected_shortlabel.degap.fas

export NCPU

PROJECTDIR   := $(shell pwd)
RUNDIR       := $(PROJECTDIR)/run
DATADIR      := $(PROJECTDIR)/data
REFERENCEDIR := $(DATADIR)/reference
SELECTEDDIR  := $(REFERENCEDIR)/selected
GENOMESDIR   := $(DATADIR)/genomes
SRCDIR       := $(PROJECTDIR)/src
PLASTDIR     := $(RUNDIR)/plast
HMMERDIR     := $(RUNDIR)/hmmer
OUTDIR       := $(PROJECTDIR)/out

export PROJECTDIR


# Files (need to be in place)
GENOMEFILES          := $(wildcard $(GENOMESDIR)/*.gz)
PLASTQUERYSELECTEDFP := $(SELECTEDDIR)/$(REFFAS)
PLASTQUERYFP         := $(PLASTDIR)/$(REFFAS)


# Programs (need to be in place)
GREPFASTA     := $(SRCDIR)/grepfasta.pl
SPLITFAST     := $(SRCDIR)/splitfast_100K
PARSENHMMER   := $(SRCDIR)/parse_nhmmer.pl
REMOVEGAPS    := $(SRCDIR)/remove_gaps_in_fasta.pl
SLURMFILES    := $(SRCDIR)/create_slurm_files.pl
REQUIRED_BINS := hmmpress nhmmer plast makeblastdb grepfasta.pl

$(foreach bin,$(REQUIRED_BINS),\
	$(if $(shell command -v $(bin) 2> /dev/null),,$(error Error: could not find program `$(bin)`)))


# Output files and rules
.PHONY: preplast splitfast dbfiles plast parseplast hmmer 

$(PLASTQUERYFP): $(PLASTQUERYSELECTEDFP)
	ln -sf $< $@


# 2. Split fasta: splitfast-100K <(gunzip -c $GENOMEFILE) > ${GENOME}.split.fas
SPLITFILES := $(shell for name in $(GENOMEFILES); do n=$${name/data\/genomes/run\/plast}; echo $${n%%.*}.split.fas; done)

$(PLASTDIR)/%.split.fas: $(GENOMESDIR)/%.gz
	$(SPLITFAST) <(gunzip -c $<) > $@


# 3. lw.fas.nin: makeblastdb -dbtype nucl -in %.split.fas
DBFILES := $(patsubst $(PLASTDIR)/%.split.fas,$(PLASTDIR)/%.split.fas.nin,$(SPLITFILES))

$(PLASTDIR)/%.split.fas.nin: $(PLASTDIR)/%.split.fas
	cd $(PLASTDIR); \
	makeblastdb -dbtype nucl -in $<


# 4. Plastoutput: plast -p plastn \
#        -i selected_shortlabel.degap.fas \
#        -d %.split.fas \
#        -o %.selected.plast.tab \
#        -a 10 \
#        -max-hit-per-query 1 \
#        -bargraph
PLASTTABFILES := $(patsubst $(PLASTDIR)/%.split.fas,$(PLASTDIR)/%.selected.plast.tab,$(SPLITFILES))

$(PLASTDIR)/%.selected.plast.tab: $(PLASTDIR)/%.split.fas $(PLASTQUERYFP)
	plast -p plastn \
		-i $(PLASTQUERYFP) \
		-d $< \
		-o $@ \
		-a $(NCPU) \
		-max-hit-per-query 1 \
		-bargraph


# 5. Scaffoldsid:  awk '$4>200' %.selected.plast.tab | \
#        perl -npe 's/-\w+//' | \
#        sort -t$'\t' -k1g -k12rg | \
#        awk -F $'\t' '!x[$1]++' | \
#        awk -F $'\t' '{print $2}' | \
#        sort -u > %.plast200.scaffold.ids
SCAFFOLDIDS := $(patsubst $(PLASTDIR)/%.selected.plast.tab,$(PLASTDIR)/%.plast$(ALILENGTH).scaffolds.ids,$(PLASTTABFILES))

$(PLASTDIR)/%.plast$(ALILENGTH).scaffolds.ids: $(PLASTDIR)/%.selected.plast.tab
	awk '$$4>$(ALILENGTH)' $< | \
		perl -npe 's/-\w+//' | \
		sort -t$$'\t' -k1g -k12rg | \
		awk -F $$'\t' '!x[$$1]++' | \
		awk -F $$'\t' '{print $$2}' | \
		sort -u > $@


# 6. Searchfile1: sed -e 's/$/\$/' -e 's/^/\^>/' %.plast200.scaffold.ids > %.searchfile1
SEARCHFILES1 := $(patsubst $(PLASTDIR)/%.plast$(ALILENGTH).scaffolds.ids,$(PLASTDIR)/%.searchfile1,$(SCAFFOLDIDS))

$(PLASTDIR)/%.searchfile1: $(PLASTDIR)/%.plast$(ALILENGTH).scaffolds.ids
	sed -e 's/$$/\$$/' -e 's/^/\^>/' $< > $@


# 7. Plast200.fas: grepfasta.pl -f %.searchfile1 %.split.fas > %.plast200.fas
PLASTFASFILES := $(patsubst $(PLASTDIR)/%.split.fas,$(PLASTDIR)/%.plast$(ALILENGTH).fas,$(SPLITFILES))

$(PLASTDIR)/%.plast$(ALILENGTH).fas: $(PLASTDIR)/%.searchfile1 $(PLASTDIR)/%.split.fas
	$(GREPFASTA) -f $^ > $@


# 8. Refids: awk '$4>200' %.selected.plast.tab | \
#        perl -npe 's/-\w+//' | \
#        sort -t$'\t' -k1g -k12rg | \
#        awk -F $'\t' '!x[$1]++' | \
#        awk -F $'\t' '{print $1}' > %.plast200.ref.ids
REFIDS := $(patsubst $(PLASTDIR)/%.selected.plast.tab,$(PLASTDIR)/%.plast$(ALILENGTH).ref.ids,$(PLASTTABFILES))

$(PLASTDIR)/%.plast$(ALILENGTH).ref.ids: $(PLASTDIR)/%.selected.plast.tab
	awk '$$4>$(ALILENGTH)' $< | \
		perl -npe 's/-\w+//' | \
		sort -t$$'\t' -k1g -k12rg | \
		awk -F $$'\t' '!x[$$1]++' | \
		awk -F $$'\t' '{print $$1}' > $@


## TODO: Rewrite 9. and 10. to one step.
# We want to read each genome specific /home/nylander/run/pe/birdscanner-part/run/plast/*.ref.ids
# and for each ref.ids file, find the corresponding /home/nylander/run/pe/birdscanner-part/data/reference/selected/hmm/<ID>.fas.degap.hmm
# Stub:
#
#    TTT='/home/nylander/run/pe/birdscanner-part/run/plast/'
#    while read theid; do
#      echo "$theid"; \
#      find /home/nylander/run/pe/birdscanner-part -name "${theid}.fas.degap.hmm";\
#      #echo "${TTT}${theid}.fas.degap.hmm"; \
#    done < /home/nylander/run/pe/birdscanner-part/run/plast/SaureNRM_genome.plast200.ref.ids > OUTFILE

# 9. Searchfile2: sed -e 's/\([0-9]\+\)/hmm\/\1\.sate/' %.plast200.ref.ids > %.searchfile2
SEARCHFILES2 := $(patsubst $(PLASTDIR)/%.plast$(ALILENGTH).ref.ids,$(PLASTDIR)/%.searchfile2,$(REFIDS))

$(PLASTDIR)/%.searchfile2: $(PLASTDIR)/%.plast$(ALILENGTH).ref.ids
	sed -e 's/\([0-9]\+\)/hmm\/\1\.sate/' $< > $@


# 10. Selected_concat.hmm: cat $(find $SELECTED/hmm -type f -name \*.hmm | grep -f %.searchfile2) > ${RUNDIR}/hmmer/%.selected_concat.hmm
SELECTEDHMMS := $(patsubst $(PLASTDIR)/%.searchfile2,$(HMMERDIR)/%.selected_concat.hmm,$(SEARCHFILES2))

$(HMMERDIR)/%.selected_concat.hmm: $(PLASTDIR)/%.searchfile2
	#cat $$(find $(SELECTEDDIR)/hmm -type f -name \*.hmm | grep -f $<) > $@
	# Crate new recepie here for concatenating correct files
	# Based on this stub:
	# cat $(TTT='/home/nylander/run/pe/birdscanner-part/run/plast/' && \
	#     sed -e "s#.*#${TTT}&\.fas.degap.hmm#" /home/nylander/run/pe/birdscanner-part/run/plast/SaureNRM_genome.plast200.ref.ids)
	#
	#
	#
	cat $$(find $(SELECTEDDIR)/hmm -type f -name \*.hmm | grep -f $<) > $@


# 11. Hmmpress: hmmpress %.selected_concat.hmm
HMMPRESSFILES := $(patsubst $(HMMERDIR)/%.hmm,$(HMMERDIR)/%.hmm.h3f,$(SELECTEDHMMS))

$(HMMERDIR)/%.hmm.h3f: $(HMMERDIR)/%.hmm
	cd $(HMMERDIR) ; \
	hmmpress $<


# 12. Hmmerout: nhmmer \
#        --tblout %.nhmmer.out \
#        --notextw \
#        --cpu 10 \
#        %.selected_concat.hmm \
#        %.plast200.fas
HMMEROUT := $(patsubst $(HMMERDIR)/%.selected_concat.hmm,$(HMMERDIR)/%.nhmmer.out,$(SELECTEDHMMS))

$(HMMERDIR)/%.nhmmer.out: $(HMMERDIR)/%.selected_concat.hmm $(PLASTDIR)/%.plast$(ALILENGTH).fas
	nhmmer \
		--tblout $@ \
		--notextw \
		--cpu $(NCPU) \
		$^


# 13. Hmmer_parse_output: perl $SRCDIR/parse_nhmmer.pl \
#        -i %.nhmmer.out \
#        -g %.plast200.fas \
#        -d %_nhmmer_output \
#        -f % \
#        -p %
#
# perl src/parse_nhmmer.pl \
#     -i run/hmmer/Ainor_genome.nhmmer.out \
#     -g run/plast/Ainor_genome.plast200.fas \
#     -d /proj/uppstore2018005/birdscanner/out/Ainor_genome_nhmmer_output/ \
#     -f Ainor_genome \
#     -p Ainor_genome
HMMEROUTDIR := $(patsubst $(HMMERDIR)/%.nhmmer.out,$(OUTDIR)/%_nhmmer_output/,$(HMMEROUT))

$(OUTDIR)/%_nhmmer_output/: $(HMMERDIR)/%.nhmmer.out
	perl $(PARSENHMMER) \
		-i $< \
		-g $(PLASTDIR)/$*.plast$(ALILENGTH).fas \
		-d $@ \
		-f $* \
		-p $*


# Tasks:

all: init plast parseplast

#all: init plast parseplast hmmer parsehmmer

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

# The size of run4uppmax.tgz was 2.6G, expanded size 27G.
slurm:
	cd $(HMMERDIR) ; \
	for f in *.hmm; do g=$$(basename "$$f" .selected_concat.hmm); $(SRCDIR)/create_slurm_file.pl -g "$$g"; done ; \
	cd $(PROJECTDIR); \
	tar -I pigz -cvf run4uppmax.tgz run/plast/*.plast$(ALILENGTH).fas run/hmmer/*.selected_concat.hmm run/hmmer/*.nhmmer.slurm.sh ;

hmmer: $(HMMEROUT)

readhmmer: $(HMMEROUTDIR)

parsehmmer:
	$(MAKE) -j$(NCPU) readhmmer

#clean:
#	( cd $(PLASTDIR) ; $(RM) * ; cd $(HMMERDIR) ; $(RM) * )

distclean:
	cd $(PROJECTDIR) ; $(RM) run4uppmax.tgz ; \
	cd $(GENOMESDIR) ; $(RM) *.gz ; \
	cd $(REFERENCEDIR)/fasta_files ; $(RM) *.fas ; \
	cd $(SELECTEDDIR) ; $(RM) *.tgz *.gz *.fas ; \
	cd $(SELECTEDDIR)/hmm ; $(RM) *.hmm ; \
	cd $(HMMERDIR) ; $(RM) *.nhmmer.out *.selected_concat.hmm* *.sh ; \
	cd $(PLASTDIR) ; $(RM) *.fas *.ids *.searchfile* *.tab *.nhr *.nin *.nsq; \
	cd $(OUTDIR) ; rm -rf *_nhmmer_output

copytestfiles:
	cp -v -u $(PROJECTDIR)/testdata/data/genomes/*.gz $(GENOMESDIR) ; \
	cp -v -u $(PROJECTDIR)/testdata/data/reference/fasta_files/*.fas $(REFERENCEDIR)/fasta_files
