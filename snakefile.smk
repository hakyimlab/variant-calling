
include: "workflow/rules/common.smk"

# === one rule to rule them all ===
rule all:
    input:
        expand("{data_dir}/trimmed_fastq/{fastq_file}", fastq_file=fastq_files, data_dir=DATA_DIR),
        expand("{data_dir}/aligned_fastq/{sample}.bam", sample=SAMPLES, data_dir=DATA_DIR),
        expand("{data_dir}/merged_bam/{individual}.bam", individual=individuals, data_dir=DATA_DIR),
        expand("{data_dir}/deduplicated_bam/{individual}.bam", individual=individuals, data_dir=DATA_DIR),
        expand("{data_dir}/recalibrated_bam/{individual}.bam", individual=individuals, data_dir=DATA_DIR),
        expand(os.path.join(GVCF_DIR, "{individual}.reblocked.g.vcf.gz"), individual=individuals),
        expand(os.path.join(scratch_folder, "{chrom}_db"), chrom=chromosomes),
        expand(os.path.join(FINAL_VCFS_DIR, f"unphased_chromosomes/{project_name}_{{chrom}}_unphased_genotypes.vcf.gz"), chrom=chromosomes),
        expand(os.path.join(FINAL_VCFS_DIR, f"phased_chromosomes/{project_name}_{{chrom}}_unphased_genotypes.vcf.gz"), chrom=chromosomes),
        expand(os.path.join(FINAL_VCFS_DIR, f"phased/{project_name}_merged_phased_genotypes.vcf.gz"), project_name=project_name)

# === trim the fastq files ===
include: "workflow/rules/trim_fastq.smk"
# # === align to the genome ===
include: "workflow/rules/bwa_align.smk"
# # == Merge the bam files ===
include: "workflow/rules/merge_bam.smk"
# # === CALL HAPLOTYPES ===
include: "workflow/rules/call_variants.smk"


# snakemake --cluster qsub -j 32