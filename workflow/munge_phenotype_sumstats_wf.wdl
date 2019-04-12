import "ld-regression-pipeline/workflow/munge_sumstats_wf.wdl" as MUNGE_WF
import "ld-regression-pipeline/workflow/task_modules/utilities.wdl" as UTIL

workflow munge_sumstats_wf{

    Array[File] sumstats_files
    Int id_col
    Int chr_col
    Int pos_col
    Int a1_col
    Int a2_col
    Int beta_col
    Int pvalue_col
    String signed_sumstats
    Int? num_samples

    Array[File] legend_files
    Array[Int] chrs
    File merge_allele_snplist


    String munge_sumstats_output_basename = "test"

