#!/bin/bash

# Ad-hoc replacement step for `make parsehmmer`
#
# Last modified: fre aug 02, 2019  02:41
# Sign: JN

## Description:
#
# Run up to the step where you normally would have done `make parsehmmer` (see `birdscanner/README.md`).
#
# Instead run this script (make sure to stand in the birdscanner root):
#
#    bash src/adhoc-nhmmer.sh
#

for f in $(find run/hmmer/ -name '*.out') ; do
    g=${f#'run/hmmer/'}
    h=${g%'.nhmmer.out'}
    i=${h%'_genome'}
    perl src/parse_nhmmer.pl \
        -i "$f" \
        -g run/plast/"$h".plast200.fas \
        -d out/"$h"_hmmer \
        -p "$i" \
        -f "$i" \
        --nostats
done

# The results are written in the folder `birdscanner/out/`
