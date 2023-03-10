
rule call_haplotypes:
    input:
        recalibrated_bam_file=rules.apply_recalibration.output.recalibrated_bam_file,
        recalibrated_bai_file=rules.apply_recalibration.output.recalibrated_bai_file
    output:
        gvcf_file=os.path.join(GVCF_DIR, "{file_basename}.g.vcf.gz")
    message:
        "CALLING HAPLOTYPES - {wildcards.file_basename}"
    log:
        call_haps_out=os.path.join(LOG_DIR, "call_haplotypes/{file_basename}_call_haps.log")
    threads: 8
    params:
        genome_file=genome_file,
        jobname='{file_basename}'
    shell:
        """
        (gatk HaplotypeCaller -R {params.genome_file} -I {input.recalibrated_bam_file} -O {output.gvcf_file} -ERC GVCF) 2> {log.call_haps_out}
        """

rule reblock_gvcf:
    input:
        f0=rules.call_haplotypes.output.gvcf_file
    output:
        reblocked_gvcf_file=os.path.join(REBLOCKED_GVCF_DIR, "{file_basename}.reblocked.g.vcf.gz")
    message:
        "REBLOCKING GVCF - {wildcards.file_basename}"
    log:
        reblock_out=os.path.join(LOG_DIR, "reblock_gvcf/{file_basename}_reblock.log")
    threads: 8
    params:
        genome_file=genome_file,
        jobname='{file_basename}'
    shell:
        """
        (gatk ReblockGVCF -R {params.genome_file} -V {input.f0} -O {output.reblocked_gvcf_file}) 2> {log.reblock_out}
        """
        

#=== CREATE DATABASE ===
rule create_variants_DB:
    input:
        reblocked_gvcfs=expand(rules.reblock_gvcf.output.reblocked_gvcf_file, file_basename=individuals)
    output:
        variant_chrom_db=directory("data/variants_DB/{chrom}_db")
    params:
        scratch_chrom_db=directory(os.path.join(scratch_folder, "{chrom}_db")),
        input_samples=lambda wildcards, input:' -V '.join(input.reblocked_gvcfs),
        #scratch_dir=lambda wildcards, output: os.path.dirname(output.scratch_chrom_db),
        temporary_dir=TMP_DIR,
        jobname='{chrom}'
    message:
        "CREATING VARIANTS DB - {wildcards.chrom}"
    threads: 8
    log:
        create_db_out=os.path.join(LOG_DIR, 'create_db/{chrom}.log')
    shell:
        """
        (gatk GenomicsDBImport -V {params.input_samples} --genomicsdb-workspace-path {params.scratch_chrom_db} --intervals {wildcards.chrom} --tmp-dir {params.temporary_dir} && cp -r {params.scratch_chrom_db} {output.variant_chrom_db}) 2> {log.create_db_out}
        """


# === joint calling === "data/final_vcfs/unphased_chromomosomes/{project_name}_{chrom}_unphased_genotypes.vcf.gz
rule genotype_gvcfs:
    input:
        #variant_chrom_db="data/variants_DB/{chrom}_db"
        variant_chrom_db=rules.create_variants_DB.output.variant_chrom_db
    output:
        unphased_chrom_vcf=os.path.join(FINAL_VCFS_DIR, f"unphased_chromosomes/{project_name}_{{chrom}}_unphased_genotypes.vcf.gz")
    params:
        genome_file=genome_file,
        jobname='{chrom}'
        #variant_chrom_db="data/variants_DB/{chrom}_db"
    log:
        genotype_gvcf_out=os.path.join(LOG_DIR, 'genotype_gvcfs/{chrom}_unphased.log')
    message:
        "GENOTYPING - {wildcards.chrom}"
    threads: 8
    shell:
        """
        (gatk GenotypeGVCFs -R {params.genome_file} -V gendb://{input.variant_chrom_db} -O {output.unphased_chrom_vcf}) 2> {log.genotype_gvcf_out}
        """     

#=== phase vcfs ===
rule phase_vcfs:
    input:
        #unphased_chrom_vcf="data/final_vcfs/unphased_chromosomes/{project_name}_{chrom}_unphased_genotypes.vcf.gz"
        unphased_chrom_vcf=rules.genotype_gvcfs.output.unphased_chrom_vcf
    output:
        phased_chrom_vcf=os.path.join(FINAL_VCFS_DIR, f"phased_chromosomes/{project_name}_{{chrom}}_phased_genotypes.vcf.gz")
    threads: 4
    log:
        phase_vcf_out=os.path.join(LOG_DIR, 'genotype_gvcfs/{chrom}_phased.log')
    params:
        gmap_dir=gmap_dir,
        jobname='{chrom}'
    message:
        "PHASING VCFs - {wildcards.chrom}"
    shell:
        """
        (shapeit4 --input {input.unphased_chrom_vcf} --map {params.gmap_dir}/{wildcards.chrom}.b38.gmap.gz --region {wildcards.chrom} --output {output.phased_chrom_vcf} --thread 4 && tabix -p vcf {output.phased_chrom_vcf}) 2> {log.phase_vcf_out}
        """

# === gather the phased vcfs ===
# rule gather_vcfs:
#     input:
#         all_phased_chrom_vcf=expand(rules.phase_vcfs.output.phased_chrom_vcf, chrom=chromosomes)
#         #all_phased_chrom_vcf=expand("data/final_vcfs/phased_chromosomes/{project_name}_{chrom}_phased_genotypes.vcf.gz", chrom=chromosomes, project_name=project_name)
#     output:
#         final_vcf_file=os.path.join(FINAL_VCFS_DIR, "phased/{project_name}_merged_phased_genotypes.vcf.gz")
#     params:
#         chrom="{wildcards.chrom}"
#     message:
#         "GATHERING VCFs - {project_name}"
#     threads: 8
#     log:
#         os.path.join(LOG_DIR, 'gather_vcfs/{project_name}.log')
#     shell:
#         """
#         (bcftools concat {input.all_phased_chrom_vcf} -o {output.final_vcf_file} -O z && tabix -p vcf {output.final_vcf_file}) 2> {log}
#         """