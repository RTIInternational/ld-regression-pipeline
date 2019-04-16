import "ld-regression-pipeline/workflow/munge_sumstats_chr_wf.wdl" as MUNGE_CHR
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
    Int? num_samples_col

    Array[File] legend_files
    Array[Int] chrs

    File merge_allele_snplist
    String signed_sumstats
    Int? num_samples

    String munge_sumstats_output_basename = "test"

    scatter (chr_index in range(length(chrs))){
        call MUNGE_CHR.munge_sumstats_chr_wf as munge_chr_wf{
            input:
                sumstats_in = sumstats_files[chr_index],
                id_col = id_col,
                chr_col = chr_col,
                pos_col = pos_col,
                a1_col = a1_col,
                a2_col = a2_col,
                beta_col = beta_col,
                pvalue_col = pvalue_col,
                num_samples_col = num_samples_col,
                legend_file = legend_files[chr_index],
                chr = chrs[chr_index],
                merge_allele_snplist = merge_allele_snplist,
                signed_sumstats = signed_sumstats,
                num_samples = num_samples,
                output_basename = munge_sumstats_output_basename
        }
    }

    call UTIL.cat_files_with_headers as merge_munge_output{
        input:
            in_files = munge_chr_wf.munge_sumstats_chr_output,
            output_basename = munge_sumstats_output_basename
    }

    output{
        File munge_sumstats_output = merge_munge_output.output_file
    }
}