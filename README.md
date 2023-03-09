# variant-calling
#### Date: Mon Jan 23 2023
#### Author: Temi

> :white_check_mark: **This pipeline is ready for use.**

## Introduction 
This repo contains a pipeline to call variants from fastq files. Another use case is when there are multiple fastq files that may need to be merged. E.g. there are multiple fastq files for an individual.

## Dry run 
#### - use this to check that the pipeline can, at least, dry-run
`snakemake -s snakemake.smk --profile profile/simple -np`

## Lint run
`snakemake -s snakemake.smk --lint`

## Final output
The final output are files of the form: `data/final_vcfs/{phased, unphased}_chromosomes/{project_name}_chr{1..X}_{phased, unphased}_genotypes.vcf.gz` (and the accompanying indexing files)

## Software
This pipeline works with a conda environment and uses a slurm directive found [here](./profiles/simple/config.yaml). You can edit this slurm directive yaml file if you know what to do. Else, leave as is.

A yaml file for the software environment is present [here](./workflow/envs/variant_calling_environment.yaml). 

You should do the following to set up the environment:

1. Make sure you have conda installed
2. Create the environment
  
    run: `conda create -p {path_to_where_you_want_a_conda_environment} -f {path_to_environment.yaml_file}`
3. Activate the environment and export the library

    run: `conda activate {path_to_where_you_want_a_conda_environment}`

    `export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/{path_to_where_you_want_a_conda_environment}/lib`

## Usage
1. Edit the `config/config.json`; instructions are [here](##-Config-file-details)
2. Make sure that `metadata/chromosomes.txt` exists
3. Ensure that `metatdata/merge_info.txt` exists
4. Activate the environment/software
4. Run `snakemake -s snakemake.smk --profile profile/simple`

## Config file details
- `project_name`: A name for the project. This name will be used to construct the final vcf files. You can use metadata information as the project name e.g. "my_family_genotypes_2023-09-09_GERMLINE"
- `metadata_sheet`: A headerless (no headers), tab-delimited file that contains how you want to group the reads and merge them, if merging is necessary. Columns are described below
  - individual
  - SRR fastq files separated by commas e.g. SRR01020304,SRR05060708,SRR09101112,SRR13141516. If merging is specified, these fastq files, after trimming and aligning to the genome, will be merged into one and given the name: `{individual}_norg.bam`. If merging is not true, this column will be skipped at merging stages. But you should provide it still, since the workflow depends on this column.
  - sequencing platform: e.g. ILLUMINA - useful for adding read groups information to merged bam files.
  - sample name: similar to the individual name (or may be the same values) - useful for adding read groups information to merged bam files.
  - library: - useful for adding read groups information to merged bam files
- `sra_folder`: folder to where the untrimmed fastq files are deposited
- `merge`: should bam files be merged based on the metadata.txt file? default is `true`
- `variants_resource`: A nested json directive for various vcf files of known variants
  - `folder`: the path to the folder
  - `files`: list of known variants
- `genetic_map`: A nested json directive for genetic maps for phasing. Should point to the folder only - not files
  - `folder`: the path to the folder containing the files
- `bwa_resource`: nested json directive for resources used for alignment
  - `folder`: the path to the folder
  - `files`: a human genome file
- `genome_resource`: 
- `reblock_gvcf`: true (will be removed later, since I intend for this pipeline to reblock anyway)
- `scratch_folder`:
- `variants_db`:
- `phase_vcfs`: Should unphased vcf files be phased?
- `chromosomes`: A txt file of chromosome names one on each row - shipped with the pipeline and should be found in [`metadata/chromosomes.txt`](metadata/chromosomes.txt)


## To-do
- [X] Remove the merging criterion; pipeline should work fine without a merging step
- [X] Include software environment - conda or containers? Decisions, decisions
- [ ] Correct where the temporary variants databases are stored. Ideally, should be in something like `/scratch`
- [ ] Use `jobname` as a param for all rules so that the SLURM directive to create error and output files appropriately
- [ ] Still deciding whether to use rule's log or SLURM log files; both will be too much extra information
