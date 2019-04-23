import "ld-regression-pipeline/workflow/subworkflows/munge_phenotype_sumstats_wf.wdl" as MUNGE_TRAIT_WF
import "ld-regression-pipeline/workflow/subworkflows/munge_sumstats_wf.wdl" as MUNGE_MAIN_WF

workflow ldsc_preprocessing_wf{

    # Inputs for phenotype of interest that will be regressed against phenotypes of interest
    Array[File] main_sumstats_files
    Int main_id_col
    Int main_chr_col
    Int main_pos_col
    Int main_a1_col
    Int main_a2_col
    Int main_beta_col
    Int main_pvalue_col
    String main_signed_sumstats
    Int? main_num_samples_col
    Int? main_num_samples

    # Inputs for each phenotype of interest that will be regressed against main phenotype
    Array[File] pheno_sumstats_files
    Array[Int] pheno_id_cols
    Array[Int] pheno_chr_cols
    Array[Int] pheno_pos_cols
    Array[Int] pheno_a1_cols
    Array[Int] pheno_a2_cols
    Array[Int] pheno_beta_cols
    Array[Int] pheno_pvalue_cols
    Array[String] pheno_signed_sumstats
    Array[Int] pheno_num_samples_cols
    Array[Int] pheno_num_samples

    # Common reference files used for processing all sumstats files
    Array[Pair[String, File]] legend_files
    File merge_allele_snplist


    # Process main GWAS dataset for input to LDSC
    call MUNGE_MAIN_WF.munge_sumstats_wf as munge_main{
        input:
            sumstats_files = main_sumstats_files,
            id_col = main_id_col,
            chr_col = main_chr_col,
            pos_col = main_pos_col,
            a1_col = main_a1_col,
            a2_col = main_a2_col,
            beta_col = main_beta_col,
            pvalue_col = main_pvalue_col,
            num_samples_col = main_num_samples_col,
            num_samples = main_num_samples,
            signed_sumstats = main_signed_sumstats,
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
                a1_col = pheno_a1_cols[phenotype_file_index],
                a2_col = pheno_a2_cols[phenotype_file_index],
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

    output{
        File munge_main_sumstats_outputs = munge_main.munge_sumstats_output
        Array[File] munge_pheno_sumstats_outputs = munge_pheno.munge_sumstats_output
    }

}
