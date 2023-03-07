

# check if merge is true
#print(f"Merge?: {config['merge']}")

rule merge_and_recalibrate_bam_files:
    input:
        lambda wildcards: expand(os.path.join(DATA_DIR, "aligned_fastq/{ind_srrs}.bam"), ind_srrs=grouping_dict[wildcards.individual])
    output:
        merged_bam_file_norg=os.path.join(DATA_DIR, "merged_bam/{individual}_norg.bam"),
        merged_bam_file=os.path.join(DATA_DIR, "merged_bam/{individual}.bam"),
        deduplicated_bam_file=os.path.join(DATA_DIR, "deduplicated_bam/{individual}.bam"),
        metrics_file=os.path.join(DATA_DIR, "deduplicated_bam/{individual}_dedup_metrics.txt"),
        recalibration_table=os.path.join(DATA_DIR, "deduplicated_bam/{individual}_recal_data.table"),
        recalibrated_bam_file=os.path.join(DATA_DIR, "recalibrated_bam/{individual}.bam")
    params:
        input_samples=lambda wildcards, input: ' -I '.join(input),
        rg_info=lambda wildcards: read_groups[wildcards.individual],
        temporary_dir=TMP_DIR,
        genome_file=genome_file,
        known_variants_files=known_variants_files,
        should_merge=config['merge']
    message:
        "MERGING & RECALIBRATING - {wildcards.individual}"
    conda: CONDA_YAML_FILE
    log:
        merge=os.path.join(LOG_DIR, "merge_and_recalibrate/{individual}_merge.log"),
        replace_rgs=os.path.join(LOG_DIR, "merge_and_recalibrate/{individual}_replace_rg.log"),
        mark_dups=os.path.join(LOG_DIR, "merge_and_recalibrate/{individual}_mark_dups.log"),
        base_recab=os.path.join(LOG_DIR, "merge_and_recalibrate/{individual}_base_recalibrate.log"),
        apply_recab=os.path.join(LOG_DIR, "merge_and_recalibrate/{individual}_apply_recab.log")
    shell:
        """
        if [ '{params.should_merge}' == 'true' ]; then
            (picard MergeSamFiles -I {params.input_samples} -O {output.merged_bam_file_norg} --TMP_DIR {params.temporary_dir} --CREATE_INDEX false) 2> {log.merge}

            (picard AddOrReplaceReadGroups -I {output.merged_bam_file_norg} --RGID {params.rg_info[3]} --RGLB {params.rg_info[2]} --RGSM {params.rg_info[1]} --RGPL {params.rg_info[0]} --RGPU {params.rg_info[4]} -O {output.merged_bam_file} --TMP_DIR {params.temporary_dir} --CREATE_INDEX true) 2> {log.replace_rgs}

        elif [ '{params.should_merge}' == 'false' ]; then
            (ln -s {params.input_samples} {output.merged_bam_file_norg}) 2> {log.merge}
            (ln -s {output.merged_bam_file_norg}) {output.merged_bam_file}) 2> {log.replace_rgs}
        fi

        (gatk MarkDuplicates -I {output.merged_bam_file} -O {output.deduplicated_bam_file} -M {output.metrics_file} --CREATE_INDEX true --TMP_DIR {params.temporary_dir}) 2> {log.mark_dups}

        (gatk BaseRecalibrator -I {output.deduplicated_bam_file} -R {params.genome_file} -O {output.recalibration_table} --tmp-dir {params.temporary_dir} {params.known_variants_files}) 2> {log.base_recab}

        (gatk ApplyBQSR -R {params.genome_file} -I {output.deduplicated_bam_file} -bqsr {output.recalibration_table} -O {output.recalibrated_bam_file} --tmp-dir {params.temporary_dir} && samtools index {output.recalibrated_bam_file}) 2> {log.apply_recab}

        rm {output.merged_bam_file_norg}
        """
