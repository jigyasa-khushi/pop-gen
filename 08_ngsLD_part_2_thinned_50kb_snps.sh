#!/usr/bin/env bash
# PART 2: run ngsLD, then prune at two r2 thresholds (0.5 and 0.2)
# Needs the output of ngsLD_part_1_thinned_50kb_snps.sh: all_pops.geno.gz and all_pops.pos

set -e

# ---- Paths (change here only) ----
BASE_DIR=/media/birdlab/bird_hdd3/jigyasha/RB/angsd/genotype_likelihood
IN_DIR=$BASE_DIR/ngsLD_input        # where Part 1 wrote its files
OUT_DIR=$BASE_DIR/ngsLD_output      # where results will go
NGSLD=/home/birdlab/softs/ngsLD/ngsLD                       # full path to the ngsLD program if it is not in the current folder
PRUNE=/home/birdlab/softs/prune_graph/target/release/prune_graph     # 

# ---- Settings (change here only) ----
N_IND=12                  # number of individuals
THREADS=8                 # CPU threads
MAX_KB=500                 # max distance between SNPs (kb)
MAX_BP=500000              # same distance in bp (used by prune_graph)

# create the output folder (does nothing if it already exists)
mkdir -p "$OUT_DIR"

# number of sites = number of lines in the position file
N=$(wc -l < "$IN_DIR/all_pops_thinned_50kb.pos")
echo "Number of sites: $N"

# ---- Step 5: ngsLD (slow, run once) ----
$NGSLD \
 --geno "$IN_DIR/all_pops_thinned_50kb.geno.gz" \
 --pos "$IN_DIR/all_pops_thinned_50kb.pos" \
 --probs \
 --n_ind $N_IND \
 --n_sites $N \
 --max_kb_dist $MAX_KB \
 --n_threads $THREADS \
 --out "$OUT_DIR/all_pops_thinned_50kb.ld"

# ---- Step 6a: prune with r2 >= 0.5 ----
$PRUNE --header --in "$OUT_DIR/all_pops_thinned_50kb.ld" \
  --weight "r2" \
  --filter "dist <= $MAX_BP && r2 >= 0.5" \
  --out "$OUT_DIR/all_pops_thinned_50kb_kept_r2_0.5.txt" \
  --out-excl "$OUT_DIR/all_pops_thinned_50kb_removed_r2_0.5.txt"

# ---- Step 6b: prune with r2 >= 0.2 ----
$PRUNE --header --in "$OUT_DIR/all_pops_thinned_50kb.ld" \
  --weight "r2" \
  --filter "dist <= $MAX_BP && r2 >= 0.2" \
  --out "$OUT_DIR/all_pops_thinned_50kb_kept_r2_0.2.txt" \
  --out-excl "$OUT_DIR/all_pops_thinned_50kb_removed_r2_0.2.txt"

# ---- Count how many sites were kept ----
wc -l "$OUT_DIR/all_pops_thinned_50kb_kept_r2_0.5.txt" "$OUT_DIR/all_pops_thinned_50kb_kept_r2_0.2.txt"
