#!/usr/bin/env bash
# PART 1: prepare the beagle file for ngsLD
# Run:  bash part1_prep_v2.sh
# Input : all_pops_thinned_50kb.beagle.gz  (from ANGSD)
# Output: all_pops_thinned_50kb.geno.gz and all_pops_thinned_50kb.pos (in the ngsLD_input folder)

# Stop if any command fails
set -e

# ---- Paths (change here only) ----
IN_DIR=/media/birdlab/bird_hdd3/jigyasha/RB/angsd/genotype_likelihood
OUT_DIR=$IN_DIR/ngsLD_input

# create the output folder (does nothing if it already exists)
mkdir -p "$OUT_DIR"

# ---- Step 1: genotype probabilities only ----
# skip the header line, drop columns 1-3 (marker, allele1, allele2)
zcat "$IN_DIR/all_pops_thinned_50kb.beagle.gz" | tail -n +2 | cut -f4- | gzip > "$OUT_DIR/all_pops_thinned_50kb.geno.gz"

# ---- Step 2: position file (chromosome <TAB> position) ----
# the marker looks like  contig_position ; split at the last underscore
zcat "$IN_DIR/all_pops_thinned_50kb.beagle.gz" | tail -n +2 | cut -f1 | \
  awk '{n=split($1,a,"_"); p=a[n]; c=substr($1,1,length($1)-length(p)-1); print c"\t"p}' \
  > "$OUT_DIR/all_pops_thinned_50kb.pos"

# ---- Step 3: checks (read these numbers!) ----
# number of sites: the first two numbers must be the same
wc -l < "$OUT_DIR/all_pops_thinned_50kb.pos"
zcat "$OUT_DIR/all_pops_thinned_50kb.geno.gz" | wc -l
# number of columns: must be 36 (12 individuals x 3)
zcat "$OUT_DIR/all_pops_thinned_50kb.geno.gz" | head -n 1 | awk '{print NF}'

# ---- Step 4 (optional): small test files to try Part 2 quickly ----
#zcat "$OUT_DIR/all_pops.geno.gz" | head -n 20000 | gzip > "$OUT_DIR/test.geno.gz"
#head -n 20000 "$OUT_DIR/all_pops.pos" > "$OUT_DIR/test.pos"
