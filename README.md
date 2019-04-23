# LD-Regression Workflow 
Documentation for running ld-score regression between GWAS summary statistics from a reference phenotype and set of phenotypes of interest. 

## Workflow overview
[LD-Hub](http://ldsc.broadinstitute.org/ldhub/) and the associated [LDSC](https://github.com/bulik/ldsc) software package provides a suite of tools designed to perform LD-score regression between GWAS outputs of two phenotypes.

This document describes an automated WDL workflow designed to perform LD regression of a reference phenotype against one or more phenotypes using the following high level steps:

1) Transform GWAS summary statistics into [summary statistics format](https://github.com/bulik/ldsc/wiki/Summary-Statistics-File-Format)
2) Reformat summary statistics using `munge_sumstats.py`
3) Perform LD-regression between the reference and all traits of interest using `ldsc.py`
4) Combine results and plot in a single graph (below)

<div align=center><img src="doc/ftnd_summary_figure.png" alt="LD regression output" width=1100 height=800 align="middle"/></div>

### Workflow inputs
The following are required for the main phenotype and each phenotype you want to compare using ld-regression:
1) Phenotype name
2) Plot label for how you want the phenotype to be labeled on the output graph
3) path to a GWAS summary statistics output file
4) 1-based column index for each of the following:
    * id col
    * chr col
    * pos col
    * effect allele col
    * ref allele col 
    * pvalue col
    * Effect column (e.g. beta, z-score, odds ratio)
    * Either the number of samples in the cohort or the sample size column index in the GWAS input
5) Effect column type in the GWAS file (BETA, Z, OR, LOG_ODD)
6) Plot group for grouping phenotypes into larger trait groups on final output plot

### Detailed Workflow Steps
1) Transform GWAS in summary statistics
    * Split by chr if necessary
        * Put columns in standardized order and give standard colnames (e.g. SNP, A1, A2, BETA, etc.)
        * Convert to 1000g ids
        * Replace 1000g ids with only rsIDs
2) Reformat summary statistics using `munge_sumstats.py`
    * For each chr:
        * Call munge_sumstats.py
        * Remove empty variants for each chromosome
    * Re-combine into single munged sumstats file
3) Perform LD-regression between the reference and all traits of interest using `ldsc.py`
    * For each phenotype you want to regress against reference phenotype
        * untar ld reference panel files
        * Call `LDSC.py` with `--rg` option to get logfile with regression statistics
4) Combine results and plot in a single graph
    * Parse statistics from log files generated by LDSC
    * Combine into single table and add plot information (e.g. plot_label, plot_group)
    * Make plot of rg values returned for each phenotype with 95% CI error bars

### Pre-requisites 
   * Unix-based operating system (Linux or OSx. Sorry Windows folks.)
   * Java v1.8 and higher [(download here)](https://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)
   * [Docker](https://docs.docker.com/install/)
   * [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
   
   1. Install [Cromwell](https://cromwell.readthedocs.io/en/stable/tutorials/FiveMinuteIntro/) if you haven't already
   
   2. [Configure the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) for use with CODE AWS group. 
        * Configure with the secret key associated with the CODE AWS account 
   
   3. Clone local copy of ld-regression-pipeline to download this repository to your local machine
        
        ```
        git clone https://github.com/RTIInternational/ld-regression-pipeline.git    
        ```
   4. Download the [Cromwell AWS config file](https://s3.amazonaws.com/rti-cromwell-output/cromwell-config/cromwell_default_genomics_queue.conf) needed to run the workflow on CODE's AWS DefaultGenomicsQueue. 
        * Keep this handy. It might be best to put the queue file in the repo you download. 
        * File location: *s3://rti-cromwell-output/cromwell-config/cromwell_default_genomics_queue.conf*
    
        ```bash
        # Change into workflow repo dir
        cd ld-regression-pipeline
  
        # Make var directory (gitignore specifically ignores var folders) 
        mkdir var
  
        # Copy config to var directory 
        cp ~/Downloads/cromwell_default_genomics_queue.conf ./var

        ``` 
   Voila! You're ready to get started running the pipeline.
   
## Creating your input file
This repo provides a custom docker tool designed to help generate the json-input file needed to run the pipeline. 

### Fill out your workflow template file
Start with the json_input/test_inputs/full_ld_regression_wf_template.json and fill in the following values unique to your analysis:
1) Give your analysis a name

        "full_ld_regression_wf.analysis_name": "ftnd_test"
        
        
2) Specify paths to GWAS summary files (22 in total; 1 per chr) for your main reference trait you wish to compare to other phenotypes

        "full_ld_regression_wf.main_sumstats_files": 
        [
        "s3://rti-nd/META/1df/boneyard/20181108/results/ea/20181108_ftnd_meta_analysis_wave3.eur.chr1.exclude_singletons.1df.gz",
        "s3://rti-nd/META/1df/boneyard/20181108/results/ea/20181108_ftnd_meta_analysis_wave3.eur.chr2.exclude_singletons.1df.gz",
        ...
        "s3://rti-nd/META/1df/boneyard/20181108/results/ea/20181108_ftnd_meta_analysis_wave3.eur.chr22.exclude_singletons.1df.gz",
        ]
3) Inspect your GWAS summary files to find the correct indices for each required column index (1-based so the first column has index 1)
        
        "full_ld_regression_wf.main_trait_name" : "ftnd",
        "full_ld_regression_wf.main_id_col":     1,
        "full_ld_regression_wf.main_chr_col":    2,
        "full_ld_regression_wf.main_pos_col":    3,
        "full_ld_regression_wf.main_a1_col":     5,
        "full_ld_regression_wf.main_a2_col":     4,
        "full_ld_regression_wf.main_beta_col":   6,
        "full_ld_regression_wf.main_pvalue_col": 8,
        
4) If your GWAS summary stats file has a sample size column, specify it's index

        "full_ld_regression_wf.main_num_samples_col": 11 
        
5) Otherwise, provide the number of samples in the cohort (will be the same for all SNPs) 

        "full_ld_regression_wf.main_num_samples" : 45233
6) Specify the effect type and the zero value as you would pass it to `munge_sumstats.py`
    
        "full_ld_regression_wf.main_signed_sumstats" : "BETA,0"

7) Provide path to a merge_allele snplist needed for `munge_sumstats.py`

        "full_ld_regression_wf.merge_allele_snplist": "s3://clustername--files/w_hm3.snplist",
        "full_ld_regression_wf.ref_ld_chr_tarfile": "s3://clustername--files/eur_w_ld_chr.tar.bz2",
        "full_ld_regression_wf.w_ld_chr_tarfile": "s3://clustername--files/eur_w_ld_chr.tar.bz2",

8) Provide paths to the reference ld-reference panel bz2 tarball passed to `LDSC.py` 
        "full_ld_regression_wf.ref_ld_chr_tarfile": "s3://clustername--files/eur_w_ld_chr.tar.bz2",


        
        
        


## Authors
For any questions, comments, concerns, or bugs,
send me an email or slack and I'll be happy to help. 
* [Alex Waldrop](https://github.com/alexwaldrop) (awaldrop@rti.org)
