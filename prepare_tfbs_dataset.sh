#!/bin/bash
# ============================================================
# Script: prepare_tfbs_dataset.sh
# Purpose:
#   Prepare a real ENCODE TFBS dataset (CTCF, GM12878)
#   for CNN training by:
#     1. Centering peaks on summit
#     2. Creating fixed-length (50 bp) positive regions
#     3. Generating matched negative regions
#     4. Extracting DNA sequences in FASTA format
#
# Author: Kinya
# ============================================================

set -e  # Exit immediately if a command fails

# -------------------------------
# User-defined variables
# -------------------------------
cd TFBS/data

PEAK_FILE="wgEncodeAwgTfbsBroadGm12878CtcfUniPk.narrowPeak"
GENOME_FASTA="hg19.fa"
GENOME_SIZES="hg19.genome"
SEQ_LEN=100
HALF_LEN=50

# Output files
POS_BED="positive_100bp.bed"
NEG_BED="negative_100bp.bed"
POS_FASTA="positive_100.fa"
NEG_FASTA="negative_100.fa"

# -------------------------------
# Step 2: Create centered 100 bp positive regions
# -------------------------------
# ENCODE narrowPeak format:
#   column 2 = start
#   column 10 = summit offset from start
#
# We compute:
#   summit = start + offset
#   region = summit ± 25 bp

echo "Creating centered ${SEQ_LEN} bp positive regions..."

awk -v half=${HALF_LEN} 'BEGIN{OFS="\t"}{
    summit = $2 + $10
    start  = summit - half
    end    = summit + half
    if (start >= 0)
        print $1, start, end
}' ${PEAK_FILE} > ${POS_BED}

echo "Positive regions written to ${POS_BED}"

# -------------------------------
# Step 3: Generate negative regions
# -------------------------------
# Shuffle positive regions across the genome:
#   - same length
#   - same chromosome distribution
#   - no overlap with positives

echo "Generating matched negative regions..."

bedtools shuffle \
    -i ${POS_BED} \
    -g ${GENOME_SIZES} \
    -noOverlapping \
    > ${NEG_BED}

echo "Negative regions written to ${NEG_BED}"

# -------------------------------
# Step 4: Extract DNA sequences
# -------------------------------
# Convert BED regions to FASTA sequences

echo "Extracting positive sequences..."

bedtools getfasta \
    -fi ${GENOME_FASTA} \
    -bed ${POS_BED} \
    -fo ${POS_FASTA}

echo "Extracting negative sequences..."

bedtools getfasta \
    -fi ${GENOME_FASTA} \
    -bed ${NEG_BED} \
    -fo ${NEG_FASTA}

# -------------------------------
# Done
# -------------------------------
echo "============================================"
echo "Dataset preparation complete!"
echo "Positive FASTA: ${POS_FASTA} (label = 1)"
echo "Negative FASTA: ${NEG_FASTA} (label = 0)"
echo "Sequence length: ${SEQ_LEN} bp"
echo "============================================"

