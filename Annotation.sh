THREADS=32
GENOME_SIZE="1.3g"

# Input data
READS="data/KC21Clean.q10.fastq"
REFERENCE_GENOME="data/GCF_011125445.2_MU-UCD_Fhet_4.1_genomic.fna"

mamba activate liftoff

ANNOT_OUTDIR="annotation/liftoff"
mkdir -p ${ANNOT_OUTDIR}

echo "Running Liftoff..."
liftoff \
  -g ${REFERENCE_GENOME%.fna}.gff \
  -o ${ANNOT_OUTDIR}/liftoff.gff \
  -p ${THREADS} \
  ${NAMING_OUTDIR}/fundulus_named.fasta \
  ${REFERENCE_GENOME}

echo "Annotation transfer complete."
