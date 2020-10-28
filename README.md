# HTCF_viral
A repository for sbatch scripts used for viral pipeline development

Current contig assembly and annotation example (post-Hecatomb):

<b>1.  Assemble contigs:</b><br>
sbatch virome_assembly_kallisto_htcf_mod2.sbatch<br>
<b>NOTE: Please change this line to your user:</b><br>
#SBATCH --mail-user=mihindu<br>

<b>2.  Contig annotation:</b><br>
sbatch contig_annotation_htcf_mod_v2.sbatch<br>
<b>NOTE: Please change this line to your user:</b><br>
#SBATCH --mail-user=mihindu<br>

<b>3. Run cenote-taker2 on Pathogen: DNA</b>\
mkdir -p /path/to/your/project/<b>assembly/contig_dictionary</b><br>
cd /path/to/your/project/<b>assembly/contig_dictionary</b><br>
rsync your contig_dictionary.fasta file here<br>
cd /path/to/your/project/<br>
mkdir <folder to run CenoteTaker2><br>

<b># Set variables - now 999 to match CAT</b><br>
MIN=999<br><br>
nohup python /mnt/pathogen1/rrodgers/Cenote-Taker2/run_cenote-taker2.0.1.py \
 --contigs /mnt/pathogen1/kathiem/Jeffrey_IBD_VLP/assembly/contig_dictionary/contig_dictionary.fasta \
 --run_title Jeffrey_IBD_VLP_DNA_ct2_all \
 --template_file ../template.sbt \
 --mem 80 --cpu 20 \
 --prune_prophage FALSE \
 --filter_out_plasmids FALSE \
 --minimum_length_circular $MIN \
 --minimum_length_linear $MIN \
 --hhsuite_tool hhsearch \
 --handle_contigs_without_hallmark sketch_all > DNA_out.log 2>&1 & <br>
 
 <b>outfile: /mnt/pathogen1/kathiem/Jeffrey_IBD_VLP/Jeffrey_IBD_VLP_DNA_ct2_all/Jeffrey_IBD_VLP_DNA_ct2_all.tsv</b><br>
 
<b>4.  Run cenote-taker2 RNA:</b><br>
mkdir Jeffrey_IBD_VLP_RNA_ct2_all<br><br>
<b>4A. Modify infile to replace space in headers with @</b><br>
sed 's/ /@/g' -i non_viral_domains_contigs.fna<br><br>
<b>4B. Find RNA viruses:</b><br>
conda activate /mnt/pathogen1/rrodgers/miniconda2/envs/cenote-taker2_env<br><br>
MIN=999<br><br>
nohup python /mnt/pathogen1/rrodgers/Cenote-Taker2/run_cenote-taker2.0.1.py \
 --contigs /mnt/pathogen1/kathiem/Jeffrey_IBD_VLP/Jeffrey_IBD_VLP_DNA_ct2_all/other_contigs/non_viral_domains_contigs.fna \
 --run_title Jeffrey_IBD_VLP_RNA_ct2_all \
 --template_file ../template.sbt \
 --mem 80 --cpu 20 \
 --virus_domain_db rna_virus \
 --prune_prophage FALSE \
 --filter_out_plasmids FALSE \
 --minimum_length_circular $MIN \
 --minimum_length_linear $MIN \
 --hhsuite_tool hhsearch \
 --handle_contigs_without_hallmark sketch_all > RNA_out.log 2>&1 & \\
<b>outfile = Jeffrey_IBD_VLP_RNA_ct2_all.tsv</b>\\
<b>5.  Perl scripts to happily marry CAT and CT2 results:</b><br>
<b>5A.  Standardize Cenote-Taker2 output:</b><br>
perl cenote-taker2_parser_v3.pl <output from Cenote-taker2> <Cenote-taker2 mode: DNA (default) or RNA><br>
perl cenote-taker2_parser_v3.pl Jeffrey_IBD_VLP_RNA_ct2_all.tsv RNA<br>
Your outfile is Jeffrey_IBD_VLP_RNA_ct2_all_clean_tax.txt</b> <br><br>
perl cenote-taker2_parser_v3.pl Jeffrey_IBD_VLP_DNA_ct2_all.tsv DNA<br>
<b>Your outfile is Jeffrey_IBD_VLP_DNA_ct2_all_clean_tax.txt</b> <br><br>
<b>5B.  Standardize CAT output:</b> \
perl cat_taxonomy_supplement.pl <output from CAT (contig.taxonomy)> <flye assembler outfile (assembly_info.txt)> <CAT.scores from CAT><br>
perl cat_taxonomy_supplement.pl contig.taxonomy assembly_info.txt CAT.scores<br>
<b>Your parsed contig taxonomy file is: contig.taxonomy_clean_tax.txt</b> <br><br>
<b>5C.  Merge CAT and CT2 output</b> <br><br>
perl cenote-taker2_cat_taxonomy_merger.pl <parsed DNA output from Cenote-taker2> <parsed RNA output from Cenote-taker2> <parsed output from CAT> <base name for outfiles><br>
perl cenote-taker2_cat_taxonomy_merger.pl Jeffrey_IBD_VLP_DNA_ct2_all_clean_tax.txt Jeffrey_IBD_VLP_RNA_ct2_all_clean_tax.txt contig.taxonomy_clean_tax.txt Jeffrey_IBD_VLP_CAT_ct2<br>
<b>Your R taxonomy infile is Jeffrey_IBD_VLP_CAT_ct2_CT2_CAT_contig_taxonomy.txt</b> 
