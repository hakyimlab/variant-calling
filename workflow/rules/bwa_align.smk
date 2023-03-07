

rule bwa_align_single:
    input:
        #r0="data/raw_samples/trimmed_fastq/{sample}_trimmed.fq.gz"
        r0=rules.trim_fastq_single.output.rOut
    output:
        bam_file=os.path.join(DATA_DIR, "aligned_fastq/{file_basename}.bam"),
        bai_file=os.path.join(DATA_DIR, "aligned_fastq/{file_basename}.bai")
    params:
        sample_name="{file_basename}",
        sample_sam=os.path.join(DATA_DIR, "bam_files/{file_basename}.sam"),
        bwa_index_file=bwa_index_file,
        temporary_dir=TMP_DIR
    message: "ALIGNING - single sample for {params.sample_name}"
    threads: 8
    log:
        os.path.join(LOG_DIR, "bwa_align/{file_basename}.log")
    shell:
        """
        (bwa mem -M -t 8 {params.bwa_index_file} {input.r0} > {params.sample_sam}) 2> {log}
        (picard SortSam -I {params.sample_sam} -O {output.bam_file} --TMP_DIR {params.temporary_dir} -SO coordinate --CREATE_INDEX true) 2> {log}
        rm {params.sample_sam}
        """

rule bwa_align_paired:
    input:
        r1=rules.trim_fastq_paired.output.r1,
        r2=rules.trim_fastq_paired.output.r2
    output:
        bam_file=os.path.join(DATA_DIR, "aligned_fastq/{file_basename}.bam"),
        bai_file=os.path.join(DATA_DIR, "aligned_fastq/{file_basename}.bai")
    params:
        sample_name="{file_basename}",
        sample_sam=os.path.join(DATA_DIR, "bam_files/{file_basename}.sam"),
        bwa_index_file=bwa_index_file,
        temporary_dir=TMP_DIR
    message: "ALIGNING - paired samples for {params.sample_name}"
    threads: 8
    log: 
        os.path.join(LOG_DIR, "bwa_align/{file_basename}.log")
    shell:
        """
        (bwa mem -M -t 8 {params.bwa_index_file} {input.r1} {input.r2} > {params.sample_sam}) 2> {log}
        (picard SortSam -I {params.sample_sam} -O {output.bam_file} --TMP_DIR {params.temporary_dir} -SO coordinate --CREATE_INDEX true) 2> {log}
        rm {params.sample_sam}
        """