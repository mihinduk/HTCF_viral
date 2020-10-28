#!/bin/bash

# contig_annotation_htcf_mod_v2.sbatch

#SBATCH --cpus-per-task=16
#SBATCH --mem=250G
#SBATCH -J virome_contig_annotate
#SBATCH --mail-user=mihindu
#SBATCH --mail-type=ALL

# Immediately exit on errors
set -ue

# Modules
module load cat
module load diamond/0.9.34-python-3.6.5

# Set variables
DIR=./assembly/contig_dictionary

# CAT annotation
# GitHub: https://github.com/dutilh/CAT

# Step 1: Main CAT pipeline
echo
echo "Contig annotation: step_1. Main CAT pipeline"
echo
CAT contigs -c $DIR/contig_dictionary.fasta -o $DIR/out.CAT \
        --force \
        --sensitive \
        -d /scratch/ref/cat/CAT_prepare_20200618/2020-06-18_CAT_database \
        -t /scratch/ref/cat/CAT_prepare_20200618/2020-06-18_taxonomy;

# Step 2: Add taxonomic names
echo
echo "Contig annotation: step_2. Add taxonomic names"
echo
CAT add_names -i $DIR/out.CAT.contig2classification.txt -o $DIR/out.CAT.taxonomy \
        -t /scratch/ref/cat/CAT_prepare_20200618/2020-06-18_taxonomy \
        --only_official --exclude_scores --force;

# Step 3: Summarize results
echo
echo "Contig annotation: step_3. Summarize results"
echo
CAT summarise -c $DIR/contig_dictionary.fasta -i $DIR/out.CAT.taxonomy \
        -o $DIR/out.CAT.summary;

# Step 4: Create contig taxonomy table
echo
echo "Contig annotation: step_4. Create contig taxonomy table"
echo
# Seperate names from CAT scores and lineage information
cut -f1,6-12 $DIR/out.CAT.taxonomy > $DIR/contig.taxonomy;
cut -f1-5 $DIR/out.CAT.taxonomy > $DIR/CAT.scores;


echo
echo "Contig annotation finished successfully"
echo
