
include: "rules/common.smk"

# === one rule to rule them all ===
rule all:
    input:
        expand("data/raw_samples/trimmed_fastq/{fastq_file}", fastq_file=fastq_files),
        expand("data/raw_samples/aligned_fastq/{sample}.bam", sample=SAMPLES),
        expand("data/raw_samples/merged_bam/{individual}.bam", individual=individuals),
        expand("data/raw_samples/deduplicated_bam/{individual}.bam", individual=individuals),
        expand("data/raw_samples/recalibrated_bam/{individual}.bam", individual=individuals),
        expand("data/gvcf_files/{individual}.reblocked.g.vcf.gz", individual=individuals),
        expand(os.path.join(scratch_folder, "{chrom}_db"), chrom=chromosomes),
        expand(os.path.join("data/final_vcfs/unphased_chromosomes/", f"{project_name}_{{chrom}}_unphased_genotypes.vcf.gz"), chrom=chromosomes),
        expand(os.path.join("data/final_vcfs/phased_chromosomes/", f"{project_name}_{{chrom}}_unphased_genotypes.vcf.gz"), chrom=chromosomes),
        expand("data/final_vcfs/phased/{project_name}_merged_phased_genotypes.vcf.gz", project_name=project_name)


# === trim the fastq files ===
include: "rules/trim_fastq.smk"
# === align to the genome ===
include: "rules/bwa_align.smk"
# == Merge the bam files ===
include: "rules/merge_bam.smk"
# === CALL HAPLOTYPES ===
include: "rules/call_variants.smk"