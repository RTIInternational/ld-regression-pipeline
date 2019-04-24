import "ld-regression-pipeline/workflow/subworkflows/munge_phenotype_sumstats_wf.wdl" as MUNGE_TRAIT_WF
import "ld-regression-pipeline/workflow/subworkflows/munge_sumstats_wf.wdl" as MUNGE_REF_WF
import "ld-regression-pipeline/workflow/subworkflows/single_ld_regression_wf.wdl" as LDSC
import "ld-regression-pipeline/workflow/subworkflows/plot_ld_regression_wf.wdl" as PLOT

workflow full_ld_regression_wf{

    # Name of analysis that will be used throughout for filename conventions
    String analysis_name

    # Inputs for phenotype of interest that will be regressed against phenotypes of interest
    String ref_trait_name
    Array[File] ref_sumstats_files
    Int ref_id_col
    Int ref_chr_col
    Int ref_pos_col
    Int ref_effect_allele_col
    Int ref_ref_allele_col
    Int ref_beta_col
    Int ref_pvalue_col
    String ref_signed_sumstats
    Int? ref_num_samples_col
    Int? ref_num_samples
    File ref_ld_chr_tarfile

    # Inputs for each phenotype of interest that will be regressed against main phenotype
    Array[File] pheno_sumstats_files
    Array[Int] pheno_id_cols
    Array[Int] pheno_chr_cols
    Array[Int] pheno_pos_cols
    Array[Int] pheno_effect_allele_cols
    Array[Int] pheno_ref_allele_cols
    Array[Int] pheno_beta_cols
    Array[Int] pheno_pvalue_cols
    Array[String] pheno_signed_sumstats
    Array[Int] pheno_num_samples_cols
    Array[Int] pheno_num_samples
    Array[String] pheno_names
    Array[String] pheno_plot_labels
    Array[String] pheno_plot_groups
    Array[File] pheno_ld_chr_tarfiles

    String pvalue_cor_method = "bonferroni"
    File? plot_group_order_file
    Float? plot_pvalue_threshold

    # Common reference files used for processing all sumstats files
    Array[Pair[String, File]] legend_files
    File merge_allele_snplist

    # Process main GWAS dataset for input to LDSC
    call MUNGE_REF_WF.munge_sumstats_wf as munge_ref{
        input:
            sumstats_files = ref_sumstats_files,
            id_col = ref_id_col,
            chr_col = ref_chr_col,
            pos_col = ref_pos_col,
            a1_col = ref_effect_allele_col,
            a2_col = ref_ref_allele_col,
            beta_col = ref_beta_col,
            pvalue_col = ref_pvalue_col,
            num_samples_col = ref_num_samples_col,
            num_samples = ref_num_samples,
            signed_sumstats = ref_signed_sumstats,
            legend_files = legend_files,
            merge_allele_snplist = merge_allele_snplist
    }

    # Process each additional trait for input to LDSC
    scatter (phenotype_file_index in range(length(pheno_sumstats_files))){
        call MUNGE_TRAIT_WF.munge_phenotype_sumstats_wf as munge_pheno{
            input:
                sumstats_file = pheno_sumstats_files[phenotype_file_index],
                id_col = pheno_id_cols[phenotype_file_index],
                chr_col = pheno_chr_cols[phenotype_file_index],
                pos_col = pheno_pos_cols[phenotype_file_index],
                a1_col = pheno_effect_allele_cols[phenotype_file_index],
                a2_col = pheno_ref_allele_cols[phenotype_file_index],
                beta_col = pheno_beta_cols[phenotype_file_index],
                pvalue_col = pheno_pvalue_cols[phenotype_file_index],
                num_samples_col = pheno_num_samples_cols[phenotype_file_index],
                num_samples = pheno_num_samples[phenotype_file_index],
                signed_sumstats = pheno_signed_sumstats[phenotype_file_index],
                legend_files = legend_files,
                merge_allele_snplist = merge_allele_snplist
        }
    }

    # Do LD-Regression of main phenotype against each additional phenotype
    scatter(phenotype_file_index in range(length(pheno_sumstats_files))){
        call LDSC.single_ld_regression_wf as ld_regression{
            input:
                ref_munged_sumstats_file = munge_ref.munge_sumstats_output,
                w_munged_sumstats_file = munge_pheno.munge_sumstats_output[phenotype_file_index],
                ref_ld_chr_tarfile = ref_ld_chr_tarfile,
                w_ld_chr_tarfile = pheno_ld_chr_tarfiles[phenotype_file_index],
                ref_trait_name = ref_trait_name,
                w_trait_name = pheno_names[phenotype_file_index]
        }
    }

    # Combine results and plot
    call PLOT.plot_ld_regression_wf as plot_ld{
        input:
            analysis_name = analysis_name,
            ldsc_regression_logs = ld_regression.ldsc_output_file,
            trait_labels = pheno_plot_labels,
            group_labels = pheno_plot_groups,
            pvalue_cor_method = pvalue_cor_method,
            group_order_file = plot_group_order_file,
            pvalue_threshold = plot_pvalue_threshold
    }

    output{
        File munge_ref_sumstats_outputs = munge_ref.munge_sumstats_output
        Array[File] munge_pheno_sumstats_outputs = munge_pheno.munge_sumstats_output
        File ld_regression_results_table = plot_ld.ld_regression_results_table
        File ld_regression_results_plot  = plot_ld.ld_regression_results_plot
    }
}

