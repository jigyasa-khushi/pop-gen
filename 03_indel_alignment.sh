#!/bin/bash
# Filename: run_gatk_realign.sh
# Description: GATK Indel Realignment for all _sorted_rmdup.bam files, indexing before and after realignment

# Exit on error
set -e

# Paths to software and reference
GATK_JAR="/home/birdlab/softs/gatk-3.6/GenomeAnalysisTK.jar"
REF="/media/birdlab/bird_hdd3/jigyasha/RB/ref_genome/ncbi_dataset/data/GCA_981468605.1/GCA_981468605.1_B10K-LU-20-09_genomic.fna"

# Directories
BAM_DIR="/media/birdlab/bird_hdd3/jigyasha/RB/mapped_RB"
OUTPUT_DIR="/media/birdlab/bird_hdd3/jigyasha/RB/indel_aligned"

# Make sure output directory exists
mkdir -p "$OUTPUT_DIR"

# Function to realign a single sample
realign_sample() {
    local filepath=$1
    local file=$(basename "$filepath" "_sorted_rmdup.bam")
    
    echo "---------------------------------------------"
    echo "Processing sample: ${file}"
    
    local input_bam="$BAM_DIR/${file}_sorted_rmdup.bam"
    local target_intervals="$OUTPUT_DIR/${file}_sorted_rmdup.intervals"
    local output_bam="$OUTPUT_DIR/${file}_RI.bam"
    
    # Step 0: Index the input rmdup BAM if not already indexed
    if [ ! -f "${input_bam}.bai" ]; then
        echo "Indexing input BAM: ${file}_sorted_rmdup.bam"
        samtools index "$input_bam"
    else
        echo "Input BAM already indexed: ${file}_sorted_rmdup.bam"
    fi
    
    # Step 1: RealignerTargetCreator
    echo "Running RealignerTargetCreator..."
    java -Xmx64g -jar "$GATK_JAR" -T RealignerTargetCreator \
        -R "$REF" \
        -I "$input_bam" \
        -o "$target_intervals"
    
    # Step 2: IndelRealigner
    echo "Running IndelRealigner..."
    java -Xmx64g -jar "$GATK_JAR" -T IndelRealigner \
        -R "$REF" \
        -I "$input_bam" \
        -targetIntervals "$target_intervals" \
        -o "$output_bam"
    
    # Step 3: Index the realigned BAM
    echo "Indexing realigned BAM..."
    samtools index "$output_bam"
    
    echo "Finished ${file}"
    echo "---------------------------------------------"
}

# Loop through all _sorted_rmdup.bam files
for bam in "$BAM_DIR"/*_sorted_rmdup.bam; do
    realign_sample "$bam"
done

echo "All samples processed!"

