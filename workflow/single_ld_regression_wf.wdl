import "ld-regression-pipeline/workflow/task_modules/utilities.wdl" as UTIL
import "ld-regression-pipeline/workflow/task_modules/ldsc.wdl" as LDSC

task

workflow single_ld_regression_wf{

    File ref_munged_sumstats_file
    File w_munged_sumstats_file

    File ref_ld_chr_tarfile
    File w_ld_chr_tarfile

    String ref_trait_name
    String w_trait_name

    #String ref_trait_label
    #String ref_trait_label

    String output_basename = "${ref_trait_name}_by_${w_trait_name}.ldsc_regression"

    # Untar ref_ld_chr_files
    call UTIL.untar_wf as untar_ref{
        input:
            tar_file = ref_ld_chr_tarfile
    }

    # Unzip w_ld_chr files
    call UTIL.untar_wf as untar_w{
        input:
            tar_file = ref_ld_chr_tarfile
    }

    call LDSC.ldsc_rg as ld_regression{
        input:
            ref_munged_sumstats_file = ref_munged_sumstats_file,
            w_munged_sumstats_file = w_munged_sumstats_file,
            ref_ld_chr_files = untar_ref.output_files,
            w_ld_chr_files = untar_w.output_files,
            output_basename = output_basename
    }

    call LDSC.parse_ldsc_rg_results as parse_results{
        input:
            ld_regression_log = ld_regression.output_file
    }

    output{
        File output_file = ld_regression.output_file
    }
}