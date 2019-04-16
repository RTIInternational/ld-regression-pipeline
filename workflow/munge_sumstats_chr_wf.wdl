import "ld-regression-pipeline/workflow/task_modules/preprocessing.wdl" as PREPROCESSING
import "ld-regression-pipeline/workflow/task_modules/ldsc.wdl" as LDSC

workflow munge_sumstats_chr_wf{

    File sumstats_in
    Int id_col
    Int chr_col
    Int pos_col
    Int a1_col
    Int a2_col
    Int beta_col
    Int pvalue_col
    Int? num_samples_col

    File legend_file
    Int chr

    File merge_allele_snplist
    String signed_sumstats
    Int? num_samples

    String output_basename
    String munge_sumstats_output_basename = "${output_basename}.chr${chr}"

    call PREPROCESSING.standardize_sumstat_cols as stdize_cols {
        input:
            sumstats_file = sumstats_in,
            id_col = id_col,
            chr_col = chr_col,
            pos_col = pos_col,
            a1_col = a1_col,
            a2_col = a2_col,
            beta_col = beta_col,
            pvalue_col = pvalue_col,
            num_samples_col = num_samples_col
    }

    call PREPROCESSING.convert_to_1000g_ids as convert_ids{
        input:
            in_file = stdize_cols.output_file,
            legend_file = legend_file,
            id_col = 0,
            chr_col = 1,
            pos_col = 2,
            a1_col = 3,
            a2_col = 4,
            chr = chr
    }

    call PREPROCESSING.reformat_for_munge_sumstats as rfmt_sumstats{
        input:
            in_file = convert_ids.output_file
    }

    call LDSC.munge_sumstats as munge_sumstats{
        input:
            sumstats_file = rfmt_sumstats.output_file,
            merge_allele_snplist = merge_allele_snplist,
            snp_colname = "MarkerName",
            a1_colname = "A1",
            a2_colname = "A2",
            pvalue_colname = "P",
            num_samples = num_samples,
            signed_sumstats = signed_sumstats,
            output_basename = munge_sumstats_output_basename
    }

    call PREPROCESSING.remove_empty_variants as rm_empty_vars {
        input:
            in_file = munge_sumstats.output_file
    }

    output{
        File munge_sumstats_chr_output = rm_empty_vars.output_file
    }

}