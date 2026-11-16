#!/bin/bash
set -e  # Exit if any command fails

# ==== Paths ====
inpath="/mnt/f/jigyasha/trimmed/"  # Input FASTQs
outpath="/mnt/f/jigyasha/RB/mapped/"  # Output directory
reffile="/mnt/f/jigyasha/rufous_babbler_ref_sequence/GCA_981468605.1_B10K-LU-20-09_genomic.fna"
email="jigyasha_20221069@students.iisertirupati.ac.in"

# ==== Software paths ====
bwa="/home/softs/bwa/bwa"
samtools="/usr/bin/samtools"

# ==== Setup ====
mkdir -p "$outpath" "$outpath/tmp"

# ==== Start notification ====
echo "Starting BWA MEM mapping + filtering + rmdup at $(date)" | mail -s "Mapping Started" "$email"

# ==== Loop through all paired-end FASTQ ====
for i in ${inpath}*_R1_paired.fastq.gz; do
    file=$(basename "$i" _R1_paired.fastq.gz)

    echo "Processing sample: $file"

    # === Step 1: BWA MEM ===
    echo "Mapping $file with BWA MEM..."
    $bwa mem -t 20 -M -R "@RG\tID:${file}\tSM:${file}\tLB:IlluminaWGS\tPL:ILLUMINA" \
        "$reffile" \
        "${inpath}${file}_R1_paired.fastq.gz" "${inpath}${file}_R2_paired.fastq.gz" | \
    $samtools view -bh - | \
    $samtools sort -@ 20 -T "${outpath}/tmp/${file}_tmp" -o "${outpath}${file}_mapped.bam"

    # === Step 2: Filter by mapping quality ===
    echo "Filtering $file BAM for quality >= 20"
    $samtools view -bh -F 4 -q 20 -o "${outpath}${file}_filtered.bam" "${outpath}${file}_mapped.bam"

    # === Step 3: Final sort ===
    echo "Sorting filtered BAM for $file..."
    $samtools sort -@ 20 -T "${outpath}/tmp/${file}_sort" -o "${outpath}${file}_filtered_sorted.bam" "${outpath}${file}_filtered.bam"

    echo "Completed alignment + sorting for $file"
done

# ==== Completion notification ====
echo "Mapping + deduplication pipeline completed at $(date)" | mail -s "Mapping Pipeline Finished" "$email"

# ==== Second loop: Mark duplicates and index ====

echo "Starting duplicate removal for all sorted BAMs..."

for bam in "$outpath"/*_filtered_sorted.bam; do
    [ -e "$bam" ] || continue

    sample=$(basename "$bam" _filtered_sorted.bam)
    rmdup_bam="${outpath}${sample}_filtered_sorted_rmdup.bam"
    metrics_file="${outpath}${sample}_filtered_sorted_rmdup_metrics.txt"

    echo "Removing duplicates for $sample..."
    java -Xmx8g -jar /home/softs/picard/build/libs/picard-*.jar MarkDuplicates \
        MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=900 \
        INPUT="$bam" \
        OUTPUT="$rmdup_bam" \
        METRICS_FILE="$metrics_file" \
        REMOVE_DUPLICATES=true \
        ASSUME_SORTED=true \
        TMP_DIR="${outpath}/tmp" \
        VALIDATION_STRINGENCY=SILENT

    echo "Indexing $sample final BAM..."
    $samtools index "$rmdup_bam"

done

echo "Duplicate removal completed"
