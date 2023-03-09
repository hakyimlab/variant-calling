
# Usage: Common snakefile
# Author: Temi
# Date: Mon Feb 27 2023

import pandas as pd
import os, glob, sys
from snakemake.io import glob_wildcards

sys.path.append('workflow/scripts')

try:
    import module
except ModuleNotFoundError as merr:
    raise Exception("ERROR - modules not found")

configfile: "config/config.json"

metadata_file = config['metadata']
if not os.path.isfile(metadata_file):
    raise Exception("ERROR - Metadata sheet file does not exist in `metadata/`")

# CREATING FILES AND LISTS AND PARAMETERS ===
grouping_dict = module.grouping_information(metadata_file)
SAMPLES = [l for l in list(grouping_dict.values()) for l in l]
# you need to provide the path to the sra files
SRA_FILES_BASENAMES = glob_wildcards(os.path.join(config["sra_folder"], "{SRA_FILES}.fastq.gz")).SRA_FILES
# "data/raw_samples/raw_fastq"
#SRA_FILES_BASENAMES = glob_wildcards(os.path.join("data/raw_samples/raw_fastq", "{SRA_FILES}.fastq.gz")).SRA_FILES
sra_num_grouping = module.create_sra_num_dict(SRA_FILES_BASENAMES)
trimming_grouping = {s: module.create_trim_inputs(sra_num_grouping, s) for s in SAMPLES}
fastq_files = [l for l in list(trimming_grouping.values()) for l in l]
individuals = list(grouping_dict.keys())
# read group dictionary ===
read_groups = module.return_read_group_information(metadata_file)

# FILES AND DIRECTORIES ===
CONDA_YAML_FILE = config['conda_env']
if not os.path.isfile(CONDA_YAML_FILE):
    raise Exception("ERROR - conda yaml file cannot be found in `workflow/envs`")
DATA_DIR = "data/raw_samples"
GVCF_DIR = "data/gvcf_files"
REBLOCKED_GVCF_DIR = "data/reblocked_gvcf_files"
FINAL_VCFS_DIR =  "data/final_vcfs"
LOG_DIR = 'logs'
TMP_DIR = 'tmp'
#BWA_INDEX = 'resource/alignment/index' # what is this?????????????
known_variants_files = [f"--known-sites {os.path.join(config['variants_resource']['folder'], v)}" for v in config['variants_resource']['files']]
genome_file = os.path.join(config['genome_resource']['folder'], config['genome_resource']['files'])
print(f'GENOME FILE - {genome_file}')
#bwa_index_file = f"{config['bwa_resource']['folder']['files']}"
bwa_index_file = os.path.join(config['bwa_resource']['folder'], config['bwa_resource']['files'][0])
scratch_folder = config['scratch_folder']
variants_db = config["variants_db"]
chromosomes = pd.read_csv(config["chromosomes"], header=None).iloc[:, 0].tolist()
project_name = config["project_name"]
gmap_dir = config['genetic_map']['folder']

if not os.path.isdir(LOG_DIR):
    os.makedirs(LOG_DIR)
if not os.path.isdir(TMP_DIR):
    os.makedirs(TMP_DIR)

if config['merge'] == True:
    config['merge'] = 'true'
elif config['merge'] == False:
    config['merge'] = 'false'

# output directories and all that

# rule order
ruleorder: bwa_align_single > bwa_align_paired
ruleorder: trim_fastq_single > trim_fastq_paired


#glob_wildcards('data/raw_samples/raw_fastq/{s}.fastq.gz')

#glob_wildcards(os.path.join("data/raw_samples/raw_fastq", "{SRA_FILES}.fastq.gz"))