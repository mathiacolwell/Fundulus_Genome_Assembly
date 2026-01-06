#!/usr/bin/env bash
set -euo pipefail

# Global settings
THREADS=32
GENOME_SIZE="1.3g"

# Input data
READS="data/KC21Clean.q10.fastq"
REFERENCE_GENOME="data/GCF_011125445.2_MU-UCD_Fhet_4.1_genomic.fna"

# Conda setup
source ~/miniforge3/etc/profile.d/conda.sh

FLYE_OUTDIR="assembly/flye"
MEDAKA_OUTDIR="${FLYE_OUTDIR}/medaka"
MEDAKA_MODEL="r1041_e82_400bps_sup_v5.0.0"

conda activate medaka

echo "Running Flye assembly..."
flye \
  --nano-raw ${READS} \
  --out-dir ${FLYE_OUTDIR} \
  --threads ${THREADS} \
  --genome-size ${GENOME_SIZE}

ASSEMBLY_FASTA="${FLYE_OUTDIR}/assembly.fasta"
mkdir -p ${MEDAKA_OUTDIR}

echo "Running Medaka polishing..."
medaka_consensus \
  -i ${READS} \
  -d ${ASSEMBLY_FASTA} \
  -o ${MEDAKA_OUTDIR} \
  -t ${THREADS} \
  -m ${MEDAKA_MODEL} \
  2>&1 | tee ${MEDAKA_OUTDIR}/medaka.log

POLISHED_ASSEMBLY="${MEDAKA_OUTDIR}/consensus.fasta"

# Purge Duplications

PURGE_OUTDIR="assembly/purge_dups"
mkdir -p ${PURGE_OUTDIR}

echo "Aligning reads to polished assembly..."
minimap2 -x map-ont -t ${THREADS} \
  ${POLISHED_ASSEMBLY} ${READS} \
  | gzip -c > ${PURGE_OUTDIR}/reads_to_assembly.paf.gz

# NOTE:
# Coverage calculation and cutoff generation
# are assumed to be performed upstream
# (PB.base.cov, cutoffs files)

echo "Running purge_dups..."
purge_dups \
  -2 \
  -T ${PURGE_OUTDIR}/cutoffs \
  -c PB.base.cov \
  ${PURGE_OUTDIR}/assembly.split.self.paf.gz \
  > ${PURGE_OUTDIR}/dups.bed \
  2> ${PURGE_OUTDIR}/purge_dups.log

PURGED_ASSEMBLY="${PURGE_OUTDIR}/purged.fa"

# Contig Curation

CURATION_OUTDIR="assembly/curated"
mkdir -p ${CURATION_OUTDIR}

echo "Filtering contigs by size (>10 kb)..."
seqkit seq -m 10000 ${PURGED_ASSEMBLY} > ${CURATION_OUTDIR}/size_filtered.fasta

echo "Calculating coverage..."
mosdepth \
  -t ${THREADS} \
  -n ${CURATION_OUTDIR}/coverage \
  ${CURATION_OUTDIR}/aligned.bam

echo "Filtering contigs by coverage..."
awk '$4 >= 6 && $4 <= 60 {print $1}' \
  ${CURATION_OUTDIR}/coverage.mosdepth.summary.txt \
  | sort -u > ${CURATION_OUTDIR}/keepers.txt

seqkit grep \
  -f ${CURATION_OUTDIR}/keepers.txt \
  ${CURATION_OUTDIR}/size_filtered.fasta \
  -o ${CURATION_OUTDIR}/curated.fa

CURATED_ASSEMBLY="${CURATION_OUTDIR}/curated.fa"

# Scaffolding (RagTag) + Gap Closing

SCAFFOLD_OUTDIR="assembly/scaffolded"
mkdir -p ${SCAFFOLD_OUTDIR}

echo "Running RagTag scaffolding..."
ragtag.py scaffold \
  ${REFERENCE_GENOME} \
  ${CURATED_ASSEMBLY} \
  -o ${SCAFFOLD_OUTDIR}/ragtag \
  -t ${THREADS}

echo "Running TGS-GapCloser..."
tgsgapcloser \
  --scaff ${SCAFFOLD_OUTDIR}/ragtag/ragtag.scaffold.fasta \
  --reads ${READS} \
  --output ${SCAFFOLD_OUTDIR}/gapclosed \
  --thread ${THREADS} \
  --ne

FINAL_ASSEMBLY="${SCAFFOLD_OUTDIR}/gapclosed.scaff_seqs"

# BUSCO 

BUSCO_OUTDIR="qc/busco"
LINEAGE="actinopterygii_odb10"
mkdir -p ${BUSCO_OUTDIR}

echo "Running BUSCO (pre-scaffolding)..."
busco \
  -i ${POLISHED_ASSEMBLY} \
  -o pre_scaffold \
  -m genome \
  -l ${LINEAGE} \
  -c ${THREADS} \
  --out_path ${BUSCO_OUTDIR} \
  --force

echo "Running BUSCO (post-scaffolding)..."
busco \
  -i ${FINAL_ASSEMBLY} \
  -o post_scaffold \
  -m genome \
  -l ${LINEAGE} \
  -c ${THREADS} \
  --out_path ${BUSCO_OUTDIR} \
  --force
  
# Name Chromosomes

NAMING_OUTDIR="assembly/named"
mkdir -p ${NAMING_OUTDIR}

echo "Aligning assembly to reference for chromosome naming..."
minimap2 -ax asm5 ${REFERENCE_GENOME} ${FINAL_ASSEMBLY} | \
  samtools sort -o ${NAMING_OUTDIR}/alignment.bam

samtools view ${NAMING_OUTDIR}/alignment.bam | \
  awk '{print $1, $3}' | sort -u > ${NAMING_OUTDIR}/chr_map.txt

awk '
  /^>/ {
    contig=substr($0,2)
    cmd="grep \"^" contig " \" '"${NAMING_OUTDIR}/chr_map.txt"'"
    cmd | getline line
    close(cmd)
    if (line) {
      split(line,a)
      print ">" a[2] "_" contig
    } else {
      print ">Unassigned_" contig
    }
    next
  }
  {print}
' ${FINAL_ASSEMBLY} > ${NAMING_OUTDIR}/fundulus_named.fasta

echo "Chromosome naming complete."

