# HTCF_viral
A repository for sbatch scripts used for viral pipeline development

Current contig assembly and annotation example (post-Hecatomb):

<b>1.  Assemble contigs:</b>\
sbatch virome_assembly_kallisto_htcf_mod2.sbatch

NOTE: Please change this line to your user:

#SBATCH --mail-user=mihindu

2.  Contig annotation:

sbatch contig_annotation_htcf_mod_v2.sbatch

NOTE: Please change this line to your user:

#SBATCH --mail-user=mihindu
