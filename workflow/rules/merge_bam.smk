rule merge_bam_files:
    input:
        lambda wildcards: expand(os.path.join(DATA_DIR, "sorted_bam/{ind_srrs}.bam"), ind_srrs=grouping_dict[wildcards.file_basename])
    output:
        merged_bam_file_norg=os.path.join(DATA_DIR, "merged_bam/{file_basename}_norg.bam")
    params:
        input_samples=lambda wildcards, input: ' I='.join(input),
        temporary_dir=TMP_DIR,
        should_merge=config['merge'],
        jobname='{file_basename}'
    message:
        "MERGING BAM FILES - {wildcards.file_basename}"
    threads: 8
    log:
        merge_out=os.path.join(LOG_DIR, "merge/{file_basename}_merge.log")
    shell:
        """
        (picard MergeSamFiles I={params.input_samples} O={output.merged_bam_file_norg} TMP_DIR={params.temporary_dir} CREATE_INDEX=false) 2> {log.merge_out}
        """

rule add_read_groups:
    input:
        f0=rules.merge_bam_files.output.merged_bam_file_norg
    output:
        merged_bam_file=os.path.join(DATA_DIR, "merged_bam/{file_basename}.bam"),
        merged_bai_file=os.path.join(DATA_DIR, "merged_bam/{file_basename}.bai")
    params:
        rg_info=lambda wildcards: read_groups[wildcards.file_basename],
        temporary_dir=TMP_DIR,
        jobname='{file_basename}'
    message: "ADDING READ GROUPS - {wildcards.file_basename}"
    threads: 8
    log:
        replace_rgs_out=os.path.join(LOG_DIR, "merge/{file_basename}_replace_rg.log")
    shell:
        """
        (picard AddOrReplaceReadGroups I={input.f0} RGID={params.rg_info[3]} RGLB={params.rg_info[2]} RGSM={params.rg_info[1]} RGPL={params.rg_info[0]} RGPU={params.rg_info[4]} O={output.merged_bam_file} TMP_DIR={params.temporary_dir} CREATE_INDEX=true) 2> {log.replace_rgs_out}
        """

rule mark_duplicates:
    input:
        f0=rules.add_read_groups.output.merged_bam_file,
        f1=rules.add_read_groups.output.merged_bai_file
    output:
        deduplicated_bam_file=os.path.join(DATA_DIR, "deduplicated_bam/{file_basename}.bam"),
        deduplicated_bai_file=os.path.join(DATA_DIR, "deduplicated_bam/{file_basename}.bai"),
        metrics_file=os.path.join(DATA_DIR, "deduplicated_bam/{file_basename}_dedup_metrics.txt")
    params:
        temporary_dir=TMP_DIR,
        jobname='{file_basename}'
    message: "MARKING DUPLICATES - {wildcards.file_basename}"
    threads: 8
    log:
        mark_dups_out=os.path.join(LOG_DIR, "merge/{file_basename}_mark_dups.log")
    shell:
        """
        (picard MarkDuplicates I={input.f0} O={output.deduplicated_bam_file} M={output.metrics_file} CREATE_INDEX=true TMP_DIR={params.temporary_dir}) 2> {log.mark_dups_out}
        """

rule create_recalibration:
    input:
        f0=rules.mark_duplicates.output.deduplicated_bam_file,
        f1=rules.mark_duplicates.output.deduplicated_bai_file,
        f3=rules.mark_duplicates.output.metrics_file
    output:
        recalibration_table=os.path.join(DATA_DIR, "recalibrated_bam/{file_basename}_recal_data.table")
    params:
        temporary_dir=TMP_DIR,
        genome_file=genome_file,
        known_variants_files=known_variants_files,
        jobname='{file_basename}'
    message: "CREATING RECALIBRATION - {wildcards.file_basename}"
    threads: 8
    log:
        create_recab_out=os.path.join(LOG_DIR, "merge/{file_basename}_base_recalibrate.log")
    shell:
        """
        (gatk BaseRecalibrator -I {input.f0} -R {params.genome_file} -O {output.recalibration_table} --tmp-dir {params.temporary_dir} {params.known_variants_files}) 2> {log.create_recab_out}
        """


rule apply_recalibration:
    input:
        f0=rules.mark_duplicates.output.deduplicated_bam_file,
        f1=rules.mark_duplicates.output.deduplicated_bai_file,
        f3=rules.create_recalibration.output.recalibration_table
    output:
        recalibrated_bam_file=os.path.join(DATA_DIR, "recalibrated_bam/{file_basename}.bam"),
        recalibrated_bai_file=os.path.join(DATA_DIR, "recalibrated_bam/{file_basename}.bam.bai")
    params:
        temporary_dir=TMP_DIR,
        genome_file=genome_file,
        jobname='{file_basename}'
    message: "APPLYING RECALIBRATION - {wildcards.file_basename}"
    threads: 8
    log:
        apply_recab_out=os.path.join(LOG_DIR, "merge/{file_basename}_apply_recab.log")
    shell:
        """
        (gatk ApplyBQSR -R {params.genome_file} -I {input.f0} -bqsr {input.f3} -O {output.recalibrated_bam_file} --tmp-dir {params.temporary_dir} && samtools index {output.recalibrated_bam_file}) 2> {log.apply_recab_out}
        """

        # (gatk ApplyBQSR -R {params.genome_file} -I {input.f0} -bqsr {output.recalibration_table} -O {output.recalibrated_bam_file} --tmp-dir {params.temporary_dir} && samtools index {output.recalibrated_bam_file}) 2> {log.apply_recab_err} 1> {log.apply_recab_out}
    





        # (picard MarkDuplicates I={output.merged_bam_file} O={output.deduplicated_bam_file} M={output.metrics_file} CREATE_INDEX=true TMP_DIR={params.temporary_dir}) 2> {log.mark_dups_err} 1> {log.mark_dups_out}

        # (gatk BaseRecalibrator -I {output.deduplicated_bam_file} -R {params.genome_file} -O {output.recalibration_table} --tmp-dir {params.temporary_dir} {params.known_variants_files}) 2> {log.base_recab_err} 1> {log.base_recab_out}

        # (gatk ApplyBQSR -R {params.genome_file} -I {output.deduplicated_bam_file} -bqsr {output.recalibration_table} -O {output.recalibrated_bam_file} --tmp-dir {params.temporary_dir} && samtools index {output.recalibrated_bam_file}) 2> {log.apply_recab_err} 1> {log.apply_recab_out}


        # if [ '{params.should_merge}' == 'true' ]; then
        #     (picard MergeSamFiles I={params.input_samples} O={output.merged_bam_file_norg} TMP_DIR={params.temporary_dir} CREATE_INDEX=false) 2> {log.merge}

        #     (picard AddOrReplaceReadGroups I={output.merged_bam_file_norg} RGID={params.rg_info[3]} RGLB={params.rg_info[2]} RGSM={params.rg_info[1]} RGPL={params.rg_info[0]} RGPU={params.rg_info[4]} O={output.merged_bam_file} TMP_DIR={params.temporary_dir} CREATE_INDEX=true) 2> {log.replace_rgs}

        # elif [ '{params.should_merge}' == 'false' ]; then
        #     (ln -s {params.input_samples} {output.merged_bam_file_norg}) 2> {log.merge}
        #     (ln -s {output.merged_bam_file_norg}) {output.merged_bam_file}) 2> {log.replace_rgs}
        # fi

        # (picard MarkDuplicates I={output.merged_bam_file} O={output.deduplicated_bam_file} M={output.metrics_file} CREATE_INDEX=true TMP_DIR={params.temporary_dir}) 2> {log.mark_dups}

        # (gatk BaseRecalibrator -I {output.deduplicated_bam_file} -R {params.genome_file} -O {output.recalibration_table} --tmp-dir {params.temporary_dir} {params.known_variants_files}) 2> {log.base_recab}

        # (gatk ApplyBQSR -R {params.genome_file} -I {output.deduplicated_bam_file} -bqsr {output.recalibration_table} -O {output.recalibrated_bam_file} --tmp-dir {params.temporary_dir} && samtools index {output.recalibrated_bam_file}) 2> {log.apply_recab}