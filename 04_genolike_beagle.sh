#!/usr/bin/env bash
set -euo pipefail

# ALL POPULATIONS BEAGLE
# Using genotype likelihoods (correct for 5× LC genomes)
# ALL POPULATIONS BEAGLE  BEAGLE WILL GIVE ME LIKLIEHOODS, AT 5X I THOUGHT RATHER THAN HARD GENOTYPING BY VCFS, BEAGLE WLD BE FINE.
# All 12 individuals together
# Order: hyperythra (7) subrufa ()
# This order MUST match sample info in R
REF="/media/birdlab/bird_hdd3/jigyasha/RB/ref_genome/ncbi_dataset/data/GCA_981468605.1/GCA_981468605.1_B10K-LU-20-09_genomic.fna"
BAMLIST="/media/birdlab/bird_hdd3/jigyasha/RB/indel_aligned/all_samples_bam_list.txt"
OUTDIR="/media/birdlab/bird_hdd3/jigyasha/RB/angsd/genotype_likelihood"

mkdir -p "${OUTDIR}"
cd "${OUTDIR}"

THREADS=20

echo "Using bamlist: ${BAMLIST}"
echo "Total individuals: $(wc -l < ${BAMLIST})"

# BEAGLE — all 12 together
# doGlf 2 ensures beagle format for PCAngsd
# minMaf 0.05 remove very rare variants which might be sequencing errrors at 5x ?? 
# No SNP_pvalue restrictions.... too strict for 5x LC
# minInd 12 75% of 12 total individuals
# Major/minor called consistently across
# all individuals simultaneously — required
# for valid PCA/admixture comparisons
echo "Beagle — all 12 individuals"
echo "Started: $(date)"

angsd \
  -GL 1 \
  -doGlf 2 \
  -doMajorMinor 1 \
  -doMaf 1 \
  -minMaf 0.05 \
  -minInd 9 \
  -minMapQ 20 \
  -minQ 20 \
  -setMinDepthInd 2 \
  -skipTriallelic 1 \
  -uniqueOnly 1 \
  -remove_bads 1 \
  -only_proper_pairs 1 \
  -C 50 \
  -baq 2 \
  -nThreads ${THREADS} \
  -bam ${BAMLIST} \
  -ref "${REF}" \
  -out all_pops

echo "Total SNPs in beagle: $(zcat all_pops.beagle.gz | tail -n +2 | wc -l)"
echo "DONE: $(date)"
echo "Output: ${OUTDIR}/all_pops.beagle.gz"
