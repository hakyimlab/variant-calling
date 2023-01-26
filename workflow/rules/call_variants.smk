

rule call_haplotypes:
    input:
        recalibrated_bam_file=rules.merge_and_recalibrate_bam_files.output.recalibrated_bam_file
    output:
        gvcf_file="data/gvcf_files/{individual}.g.vcf.gz",
        reblocked_gvcf_file="data/gvcf_files/{individual}.reblocked.g.vcf.gz"
    message:
        "[CALLING HAPLOTYPES] {wildcards.individual}"
    log:
        call_haps="log/call_haplotypes/{individual}_call_haps.log",
        reblock="log/call_haplotypes/{individual}_reblock.log"
    params:
        genome_file=genome_file
    shell:
        """
        (gatk HaplotypeCaller -R {params.genome_file} -I {input.recalibrated_bam_file} -O {output.gvcf_file} -ERC GVCF) 2> {log.call_haps}
        (gatk ReblockGVCF -R {params.genome_file} -V {output.gvcf_file} -O {output.reblocked_gvcf_file}) 2> {log.reblock}
        rm {output.gvcf_file}
        """

#=== CREATE DATABASE ===
rule create_variants_DB:
    input:
        reblocked_gvcfs=expand(rules.call_haplotypes.output.reblocked_gvcf_file, individual=individuals)
    output:
        scratch_chrom_db=os.path.join(scratch_folder, "{chrom}_db"),
        variant_chrom_db="data/variants_DB/{chrom}_db"
    params:
        input_samples=lambda wildcards, input:' -V '.join(input.reblocked_gvcfs),
        #scratch_dir=lambda wildcards, output: os.path.dirname(output.scratch_chrom_db),
        temporary_dir=TMP_DIR
    message:
        "[CREATING VARIANTS DB] {wildcards}"
    log:
        os.path.join(LOG_DIR, 'create_db/{chrom}.log')
    shell:
        """
        (gatk GenomicsDBImport -V {params.input_samples} --genomicsdb-workspace-path {output.scratch_chrom_db} --intervals {wildcards.chrom} --tmp-dir {params.temporary_dir} && cp -r {output.scratch_chrom_db} {output.variant_chrom_db}) 2> {log}
        """


# === joint calling === "data/final_vcfs/unphased_chromomosomes/{project_name}_{chrom}_unphased_genotypes.vcf.gz
rule genotype_gvcfs:
    input:
        #variant_chrom_db="data/variants_DB/{chrom}_db"
        variant_chrom_db=rules.create_variants_DB.output.variant_chrom_db
    output:
        unphased_chrom_vcf=os.path.join("data/final_vcfs/unphased_chromosomes/", f"{project_name}_{{chrom}}_unphased_genotypes.vcf.gz")
    params:
        genome_file=genome_file
        #variant_chrom_db="data/variants_DB/{chrom}_db"
    log:
        os.path.join(LOG_DIR, 'genotype_gvcfs/{chrom}_unphased.log')
    message:
        "Genotyping {wildcards.chrom}"
    shell:
        """
        (gatk GenotypeGVCFs -R {params.genome_file} -V gendb://{input.variant_chrom_db} -O {output.unphased_chrom_vcf}) 2> {log}
        """     

#=== phase vcfs ===
rule phase_vcfs:
    input:
        #unphased_chrom_vcf="data/final_vcfs/unphased_chromosomes/{project_name}_{chrom}_unphased_genotypes.vcf.gz"
        unphased_chrom_vcf=rules.genotype_gvcfs.output.unphased_chrom_vcf
    output:
        phased_chrom_vcf=os.path.join("data/final_vcfs/phased_chromosomes/", f"{project_name}_{{chrom}}_unphased_genotypes.vcf.gz")
    threads: 4
    log:
        os.path.join(LOG_DIR, 'genotype_gvcfs/{chrom}_phased.log')
    params:
        gmap_dir=gmap_dir
    shell:
        """
        (shapeit4 --input {input.unphased_chrom_vcf} --map {params.gmap_dir}/{wildcards.chrom}.b38.gmap.gz --region {wildcards.chrom} --output {output.phased_chrom_vcf} --thread 4 && tabix -p vcf {output.phased_chrom_vcf}) 2> {log}
        """

# === gather the phased vcfs ===
rule gather_vcfs:
    input:
        all_phased_chrom_vcf=expand(rules.phase_vcfs.output.phased_chrom_vcf, chrom=chromosomes)
        #all_phased_chrom_vcf=expand("data/final_vcfs/phased_chromosomes/{project_name}_{chrom}_phased_genotypes.vcf.gz", chrom=chromosomes, project_name=project_name)
    output:
        final_vcf_file="data/final_vcfs/phased/{project_name}_merged_phased_genotypes.vcf.gz"
    params:
        chrom="{wildcards.chrom}"
    message:
        "[GATHERING VCFs] for project: {project_name}"
    log:
        os.path.join(LOG_DIR, 'gather_vcfs/{project_name}.log')
    shell:
        """
        (bcftools concat {input.all_phased_chrom_vcf} -o {output.final_vcf_file} -O z && tabix -p vcf {output.final_vcf_file}) 2> {log}
        """