# variant-calling
#### Date: Mon Jan 23 2023
#### Author: Temi


> :warning: **This pipeline is not for use yet.**

## Introduction 

This repo contains a pipeline to call variants from fastq files. Another use case is when there are multiple fastq files that may need to be merged. E.g. there are multiple fastq files for an individual.

## Usage
1. Edit the `config/config.json`; instructions are [here](##-Config-file-details)
2. Make sure that `metadata/chromosomes.txt` exists
3. Ensure that `metatdata/merge_info.txt` exists
4. Run `snakemake -s snakemake.smk`

## Dry run
`snakemake -s snakemake.smk -np`

## lint run
`snakemake -s snakemake.smk --lint`

## Config file details
- `project_name`: A name for the project. If final, phased vcf files are to be merged into one, the final vcf file will be names `{project_name}_final.vcf.gz`
- `metadata_sheet`: A headerless (no headers), tab-delimited file that contains how you want to group the reads and merge them, if merging is necessary. Columns are described below
  - individual
  - SRR fastq files separated by commas e.g. SRR01020304,SRR05060708,SRR09101112,SRR13141516. If merging is specified, these fastq files, after trimming and aligning to the genome, will be merged into one and given the name: `{individual}_norg.bam`. If merging is not true, this column will be skipped at merging stages. But you should provide it still, since the workflow depends on this column.
  - sequencing platform: e.g. ILLUMINA - useful for adding read groups information to merged bam files.
  - sample name: similar to the individual name (or may be the same values) - useful for adding read groups information to merged bam files.
  - library: - useful for adding read groups information to merged bam files
- `sra_folder`:
- `merge`: should bam files be merged based on the metadata.txt file?
- `conda_env`: An environment yaml file - shipped with the pipeline and should be found in [`workflow/envs/environment.yaml`](workflow/envs/environment.yaml)
- `variants_resource`: A nested json directive for various vcf files of known variants
  - `folder`: the path to the folder
  - `files`: list of known variants
- `genetic_map`: A nested json directive for 
- `bwa_resource`:
- `genome_resource`: 
- `reblock_gvcf`:
- `scratch_folder`:
- `variants_db`:
- `phase_vcfs`: Should unphased vcf files be phased?
- `chromosomes`: A txt file of chromosome names one on each row - shipped with the pipeline and should be found in [`metadata/chromosomes.txt`](metadata/chromosomes.txt)


## To-do
- [ ] Remove the merging criterion; pipeline should work fine without a merging step
- [X] Include software environment - conda or containers? Decisions, decisions
