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
- `merge_file`: A tab-delimited file that contains how you want to group the reads and merge them, if merging is necessary.
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
- `chromosomes`: 


## To-do
- [ ] Remove the merging criterion; pipeline should work fine without a merging step
- [X] Include software environment - conda or containers? Decisions, decisions
