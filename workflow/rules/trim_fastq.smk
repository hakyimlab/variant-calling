

rule trim_fastq_single:
    input:
        rIn=os.path.join(config["sra_folder"], "{file_basename}.fastq.gz")
    output:
        rOut=os.path.join(DATA_DIR, "trimmed_fastq/{file_basename}_trimmed.fq.gz")
    params:
        #output_dir="data/raw_samples/trimmed_fastq",
        output_dir=lambda wildcards, output: os.path.dirname(output.rOut),
        sample_name="{file_basename}"
    message: "TRIMMING - single sample for {params.sample_name}"
    conda: CONDA_YAML_FILE
    log:
        os.path.join(LOG_DIR, "trim/{file_basename}.log")
    shell:
        """"
        (trim_galore --single --phred33 --cores 4 --stringency 3 --illumina {input.rIn} --output_dir {params.output_dir}) 2> {log}
        """

rule trim_fastq_paired:
    input:
        r1=os.path.join(config["sra_folder"], "{file_basename}_1.fastq.gz"),
        r2=os.path.join(config["sra_folder"], "{file_basename}_2.fastq.gz")
    output:
        r1=os.path.join(DATA_DIR, "trimmed_fastq/{file_basename}_1_val_1.fq.gz"),
        r2=os.path.join(DATA_DIR, "trimmed_fastq/{file_basename}_2_val_2.fq.gz")
    params:
        #output_dir="data/raw_samples/trimmed_fastq",
        output_dir=lambda wildcards, output: os.path.dirname(output.r1),
        sample_name="{file_basename}"
    message: "TRIMMING - paired samples for {params.sample_name}"
    conda: CONDA_YAML_FILE
    log:
        os.path.join(LOG_DIR, "trim/{file_basename}.log")
    shell:
        """"
        (trim_galore --paired --phred33 --cores 4 --stringency 3 --illumina {input.r1} {input.r2} --output_dir {params.output_dir}) 2> {log}
        """