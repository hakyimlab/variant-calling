# variant-calling
#### Date: Mon Jan 23 2023
#### Author: Temi


> :warning: **This pipeline is not for use yet.**

## Introduction 

This repo contains a pipeline to call variants from fastq files in a special case. This special case is when there are multiple fastq file that may need to be merged. E.g. there are multiple fastq files for an individual.

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
- `conda_env`:
- `variants_resource`: 
- `genetic_map`:
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
