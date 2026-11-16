#!/usr/bin/env bash
# PART 3: make pruned beagle files (r2 0.5 and r2 0.2) for PCAngsd
# Run:  bash getting_beagle_after_LD_pruning_50kb thinned.sh
# Idea: get the list of REMOVED sites from prune_graph, then keep every
#       beagle line whose marker is NOT in that list.
# Needs: all_pops.ld (from Part 2) and the original all_pops.beagle.gz, here all_pops_50kb_thinned_beagle.gz

set -e

# ---- Paths (change here only) ----
BASE_DIR=/media/birdlab/bird_hdd3/jigyasha/RB/angsd/genotype_likelihood
LD_DIR=$BASE_DIR/ngsLD_output           # where all_pops_thinned_50kb.ld is
BEAGLE=$BASE_DIR/all_pops_50kb_thinned_beagle.gz    # the 50kb thinned beagle file
OUT_DIR=$BASE_DIR/pruned_beagle         # new folder for results
PRUNE=/home/birdlab/softs/prune_graph/target/release/prune_graph
MAX_BP=500000                            # same distance as in Part 2 (bp)

mkdir -p "$OUT_DIR"

# total number of sites in the original beagle (header not counted)
N_TOTAL=$(( $(zcat "$BEAGLE" | wc -l) - 1 ))
echo "Sites in original beagle: $N_TOTAL"

# 2. rename sites from contig:position to contig_position (beagle style)
sed 's/:\([0-9][0-9]*\)$/_\1/' "$OUT_DIR/all_pops_thinned_50kb_removed_r2_0.5.txt" > "$OUT_DIR/removed_r2_0.5.markers"
echo "First removed markers (should look like CEQSKK...1_1234):"
head -n 3 "$OUT_DIR/removed_r2_0.5.markers"

# 3. keep the header and every line whose marker is NOT in the removed list
zcat "$BEAGLE" | awk 'NR==FNR{rm[$1]; next} FNR==1 || !($1 in rm)' \
  "$OUT_DIR/removed_r2_0.5.markers" - | gzip > "$OUT_DIR/all_pops_thinned_50kb_pruned_r2_0.5.beagle.gz"
  
  
