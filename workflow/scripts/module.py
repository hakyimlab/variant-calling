# Usage: Utility functions for calling genotypes from fastq files
# Author: Temi
# Date: Mon Feb 27 2023

import pandas as pd

def prepare_srr_list(merge_info_file):

    """
    Return a list of SRR accession numbers
    """
    #merge_info_file = './metadata/merge_info.txt' #config['merge_info']
    minfo = pd.read_table(merge_info_file, sep='\t', header=None)
    lofl = [ea.split(',') for ea in minfo[1].tolist()]
    final_list = [item for subitem in lofl for item in subitem]

    return(final_list)

def return_read_group_information(merge_info_file):
    """
    Return a dictionary of read group information for each individual or grouping level
    """
    #merge_info_file = './metadata/merge_info.txt' #config['merge_info']
    minfo = pd.read_table(merge_info_file, sep='\t', header=None)
    rg_dict = {}
    for i, individual in enumerate(minfo[0].tolist()):
        rg_dict[individual] = minfo.iloc[i, 2:].values.tolist()
    return(rg_dict)

def grouping_information(merge_info_file):
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

