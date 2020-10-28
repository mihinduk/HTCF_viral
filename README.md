# HTCF_viral
A repository for sbatch scripts used for viral pipeline development

Current contig assembly and annotation example (post-Hecatomb):

<b>1.  Assemble contigs:</b>\
sbatch virome_assembly_kallisto_htcf_mod2.sbatch\
<b>NOTE: Please change this line to your user:<\b>\
#SBATCH --mail-user=mihindu\

<b>2.  Contig annotation:<\b>\
sbatch contig_annotation_htcf_mod_v2.sbatch\
<b>NOTE: Please change this line to your user:<\b>\
#SBATCH --mail-user=mihindu
