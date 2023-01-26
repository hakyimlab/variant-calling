
# Use: 
# Author:
# Date:

prefetch_software = "/home/temi/software/sratoolkit.3.0.0-ubuntu64/bin/prefetch"
import pandas as pd
import os, glob
from snakemake.io import glob_wildcards

configfile: "metadata/call_genotypes_config.json"

merge_info_file = config['merge_file']

def prepare_srr_list(merge_info_file):
    #merge_info_file = './metadata/merge_info.txt' #config['merge_info']
    minfo = pd.read_table(merge_info_file, sep='\t', header=None)
    lofl = [ea.split(',') for ea in minfo[1].tolist()]
    final_list = [item for subitem in lofl for item in subitem]

    return(final_list)

def return_read_group_information(merge_info_file):
    #merge_info_file = './metadata/merge_info.txt' #config['merge_info']
    minfo = pd.read_table(merge_info_file, sep='\t', header=None)
    rg_dict = {}
    for i, individual in enumerate(minfo[0].tolist()):
        rg_dict[individual] = minfo.iloc[i, 2:].values.tolist()
    return(rg_dict)

def grouping_information():
    minfo = pd.read_table(merge_info_file, sep='\t', header=None)
    group_keys = minfo[0]
    group_list = [ea.split(',') for ea in minfo[1].tolist()]

    return(dict(zip(group_keys, group_list)))

def split_sras(sra_list):
    return list(set([s.split('_')[0] for s in sra_list]))

def create_sra_num_dict(sra_list):
    keys = list(set([s.split('_')[0] for s in sra_list]))
    out_dict = {}
    for k in keys:
        out_dict[k] = []
        for s in sra_list:
            if (s.startswith(k)) and (not s in out_dict[k]):
                out_dict[k].append(s)
    return(out_dict)

def subset_for(gather_dict, which):
    return(gather_dict[which])

def create_gather(gather_dict, out_type='list'):
    out_list = {}
    for k in gather_dict.keys():
        out_list[k] = []
        if len(gather_dict[k]) == 1:
            out_list[k].append(f'{k}_trimmed.fq.gz')
        elif len(gather_dict[k]) == 2:
            for i,s in enumerate(gather_dict[k]):
                out_list[k].append(f'{k}_{i+1}_val_{i+1}.fq.gz')
    
    if out_type == 'list':
        return [l for l in list(out_list.values()) for l in l]
    elif out_type == 'dict':
        return(out_list)

def create_trim_inputs(gather_dict, which):
    if len(gather_dict[which]) == 1:
        return([f'{which}_trimmed.fq.gz'])
    elif len(gather_dict[which]) == 2:
        output = []
        for i,s in enumerate(gather_dict[which]): 
            output.append(f'{which}_{i+1}_val_{i+1}.fq.gz')
        return(output)

def create_prefetch_outputs(gather_dict, which):
    if len(gather_dict[which]) == 1:
        return([f'{which}.fastq.gz'])
    elif len(gather_dict[which]) == 2:
        output = []
        for i,s in enumerate(gather_dict[which]): 
            output.append(f'{which}_{i+1}.fastq.gz')
        return(output)

def create_sra_num_list(gather_dict, which):
    if len(gather_dict[which]) == 1:
        return([f'{which}_trimmed.fq.gz'])
    elif len(gather_dict[which]) == 2:
        output = []
        for i,s in enumerate(gather_dict[which]): 
            output.append(f'{which}_{i+1}_val_{i+1}.fq.gz')
        return(output)

grouping_dict = grouping_information()

SAMPLES = [l for l in list(grouping_dict.values()) for l in l]

# you need to provide the path to the sra files
SRA_FILES_BASENAMES = glob_wildcards(os.path.join(config["sra_folder"], "{SRA_FILES}.fastq.gz")).SRA_FILES

sra_num_grouping = create_sra_num_dict(SRA_FILES_BASENAMES)

trimming_grouping = {s: create_trim_inputs(sra_num_grouping, s) for s in SAMPLES}
fastq_files = [l for l in list(trimming_grouping.values()) for l in l]
individuals = list(grouping_dict.keys())

# read group dictionary
read_groups = return_read_group_information(merge_info_file)
known_variants_files = [f"--known-sites {os.path.join(config['variants_resource']['folder'], v)}" for v in config['variants_resource']['files']]
genome_file = [f"{os.path.join(config['genome_resource']['folder'], v)}" for v in config['genome_resource']['files']]
bwa_index_file = f"{config['bwa_resource']['folder']}"
scratch_folder = config['scratch_folder']
variants_db = config["variants_db"]
chromosomes = pd.read_csv(config["chromosomes"], header=None).iloc[:, 0].tolist()
project_name = config["project_name"]
gmap_dir = config['genetic_map']['folder']
LOG_DIR = 'log/'
TMP_DIR = 'tmp/'
BWA_INDEX = 'resource/alignment/index'

if not os.path.isdir(LOG_DIR):
    os.makedirs(LOG_DIR)
if not os.path.isdir(TMP_DIR):
    os.makedirs(TMP_DIR)

# output directories and all that

# rule order
ruleorder: bwa_align_single > bwa_align_paired
ruleorder: trim_fastq_single > trim_fastq_paired


#glob_wildcards('data/raw_samples/raw_fastq/{s}.fastq.gz')

#glob_wildcards(os.path.join("data/raw_samples/raw_fastq", "{SRA_FILES}.fastq.gz"))