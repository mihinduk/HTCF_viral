#!/bin/bash

# virome_assembly_kallisto_htcf_mod2.sbatch

# Takes quality controlled reads (through contaminant_removal.sh Step 7) and performs a metagenomic assembly

# Steps:
# 0) Kmer stats file generation
# 1) Digital normalization (bbnorm)
# 2) Individual sample assembly (megahit)
# 3) Contig assembly to create contig dictionary (flye)
# 4) Statistics - bbtools
# 5) Quantification by mapping - kallisto
# 6) Combine contig covereages from bbmap with kallisto results - unix

#SBATCH --cpus-per-task=16
#SBATCH --mem=250G
#SBATCH -J virome_assembly_kallisto
#SBATCH --mail-user=mihindu
#SBATCH --mail-type=ALL

# Immediately exit on errors
set -ue

# Modules
module load bbtools
module load megahit
module load py-flye/2.7.1-python-3.6.5


# Prep output directories
mkdir -p ./assembly
mkdir -p ./assembly/stats
mkdir -p ./assembly/megahit_contigs
mkdir -p ./assembly/contig_dictionary

# Set variables
IN=./QC/step_7
OUT=./assembly
DIR=./assembly/contig_dictionary
MIN=1000 # Minimum contig length


# Set file names
for i in $IN/*_R1.s7.out.fastq; do
        sample=`basename $i _R1.s7.out.fastq`;


# Step 0: Tabulate some kmer statistics
echo
echo "Viral Assembly: step_0. Tabulate kmer stats"
echo
bbcountunique.sh in=$IN/${sample}_R1.s7.out.fastq in2=$IN/${sample}_R2.s7.out.fastq \
	interval=2500 \
	out=$OUT/stats/${sample}_uniq_kmer_stats.txt \
	ow=t \
  -Xmx64g

  # Step 1: Digital Normalization
  echo
  echo "Viral Assembly: step_1. Digital Norm"
  echo
  bbnorm.sh in=$IN/${sample}_R1.s7.out.fastq in2=$IN/${sample}_R2.s7.out.fastq extra=$IN/${sample}_singletons_R1.out.fastq,$IN/${sample}_singletons_R2.out.fastq \
  	out=$OUT/${sample}_R1.norm.out.fastq out2=$OUT/${sample}_R2.norm.out.fastq outt=$OUT/${sample}_tossed.norm.fastq \
  	target=20 mindepth=2 \
  	hist=$OUT/${sample}_norm.hist \
  	ow=t \
    -Xmx64g

  # Step 2: Assembly
  echo
  echo "Viral Assembly: step_2. Megahit"
  echo
  megahit -1 $OUT/${sample}_R1.norm.out.fastq -2 $OUT/${sample}_R2.norm.out.fastq -r $IN/${sample}_singletons_R1.out.fastq,$IN/${sample}_singletons_R2.out.fastq -o $OUT/${sample}_megahit_out \
  	--out-prefix ${sample}.mh \
    -t ${SLURM_CPUS_PER_TASK}

  done;

  find . -type f -name "*.mh.contigs.fa" -exec cp -rfp {} $OUT/megahit_contigs \;

  # Step 3: Contig assembly to create contig dictionary (flye)
  echo
  echo "Viral Assembly: step_3. flye"
  echo

  cat $OUT/megahit_contigs/*.mh.contigs.fa > $OUT/contig_dictionary/all.mh.contigs.fa;

  reformat.sh in=$OUT/contig_dictionary/all.mh.contigs.fa out=$OUT/contig_dictionary/all.mh.contigs_trunc.fa \
  	ml=$MIN \
  	ow=t;

  rename.sh in=$OUT/contig_dictionary/all.mh.contigs_trunc.fa out=$OUT/contig_dictionary/all.mh.contigs_for_flye.fa

  flye --subassemblies $OUT/contig_dictionary/all.mh.contigs_for_flye.fa -t 24 --meta --plasmids -o $OUT/contig_dictionary -g 1g

  reformat.sh in=$OUT/contig_dictionary/assembly.fasta out=$OUT/contig_dictionary/contig_dictionary.fasta \
          ml=$MIN \
          ow=t;


# Step 4: Statistics - bbtools
echo
echo "Viral Assembly: step_4. bbtools"
echo

# Set file names
for i in $IN/*_R1.s7.out.fastq; do
          sample=`basename $i _R1.s7.out.fastq`;

# Use bbmap to calculate various stats that kallisto does not
bbmap.sh ref=$OUT/contig_dictionary/contig_dictionary.fasta in=$IN/${sample}_R1.s7.out.fastq in2=$IN/${sample}_R2.s7.out.fastq \
        out=$OUT/contig_dictionary/${sample}.aln.sam.gz \
        kfilter=22 subfilter=15 maxindel=80 \
        ambiguous=random \
	physcov=t \
        covstats=$OUT/contig_dictionary/${sample}.covstats \
        rpkm=$OUT/contig_dictionary/${sample}.rpkm \
        statsfile=$OUT/contig_dictionary/${sample}.statsfile \
        scafstats=$OUT/contig_dictionary/${sample}.scafstats \
        ow=t \
        t=${SLURM_CPUS_PER_TASK} \
        -Xmx64g

done

# Step 5: Quantification by mapping - kallisto
echo
echo "Viral Assembly: step_5. kallisto"
echo

# Unload flye and load kallisto
module purge py-flye/2.7.1-python-3.6.5

module load mpich/3.3-python-2.7.15
module load kallisto/0.46.2-python-2.7.15

# Calculate TPM with kallisto
# Create kallisto index
kallisto index -i $OUT/contig_dictionary/contig_dictionary.idx $OUT/contig_dictionary/contig_dictionary.fasta

for i in $IN/*_R1.s7.out.fastq; do
        sample=`basename $i _R1.s7.out.fastq`;

kallisto quant -i $OUT/contig_dictionary/contig_dictionary.idx -b 100 \
	$IN/${sample}_R1.s7.out.fastq $IN/${sample}_R2.s7.out.fastq \
	-o $DIR/${sample}_kallisto;

done

# Step 6: Combine contig covereages from bbmap with kallisto results - unix
echo
echo "Viral Assembly: step_6. Combine contig covereages from bbmap with kallisto results"
echo

# Extract contig IDs
grep ">" $DIR/assembly.fasta | sed 's/>//' > $DIR/contig.ids;

# Combine frags with coverage percent and calculate fragments per length (frags/contig length)
# Removes alignment statistic from mappings across < 90% of the length of the contig
for i in $DIR/*.covstats; do

	sample=`basename $i .covstats`;

	tail -n+2 $DIR/${sample}_kallisto/abundance.tsv | cut -f5 > $DIR/${sample}_kallisto/${sample}.temp;

	sed -i "1i$sample" $DIR/${sample}_kallisto/${sample}.temp;

	paste $DIR/${sample}.covstats $DIR/${sample}_kallisto/${sample}.temp > $DIR/${sample}.temp;

	tail -n+2 $DIR/${sample}.temp | awk '{ if ($5 >= 90) { print$1"\t"$11 } }' > $DIR/${sample}.filt.tpm;

	sed -i "1iID\t$sample" $DIR/${sample}.filt.tpm;

done

rm $DIR/*.temp
