import "ld-regression-pipeline/workflow/munge_sumstats_chr_wf.wdl" as MUNGE_CHR_WF
import "ld-regression-pipeline/workflow/task_modules/utilities.wdl" as UTIL

workflow munge_phenotype_sumstats_wf{

    File sumstats_file
    Int id_col
    Int chr_col
    Int pos_col
    Int a1_col
    Int a2_col
    Int beta_col
    Int pvalue_col
    Int num_samples_col = chr_col

    String signed_sumstats
    Int? num_samples

    Array[File] legend_files
    Array[Int] chrs
    File merge_allele_snplist

    # Unzip file if it needs to be unzipped
    if(basename(sumstats_file) != basename(sumstats_file,".gz")){
        call UTIL.gunzip as gunzip{
            input:
                in_file = sumstats_file
        }
        File unzipped_sumstat_file = gunzip.output_file
    }

    # Split either the newly unzipped file or the original file depending on whether original file was zipped
    Array[File?] possible_files = [unzipped_sumstat_file, sumstats_file]
    File to_split = select_first(possible_files)

    # Split file by chromosome
    call UTIL.split_text_file_by_chr as split_by_chr{
        input:
            in_file = to_split,
            output_basename = basename(sumstats_file, ".gz"),
            chr_col = chr_col
    }

    scatter (chr_index in range(length(split_by_chr.output_files))){
        Int chr = split_by_chr.chrs[chr_index]
        Int legend_chr_index = chr-1
        call MUNGE_CHR_WF.munge_sumstats_chr_wf as munge_chr_wf{
            input:
                sumstats_in = split_by_chr.output_files[chr_index],
                id_col = id_col,
                chr_col = chr_col,
                pos_col = pos_col,
                a1_col = a1_col,
                a2_col = a2_col,
                beta_col = beta_col,
                pvalue_col = pvalue_col,
                num_samples_col = num_samples_col,
                legend_file = legend_files[legend_chr_index],
                chr = chr,
                merge_allele_snplist = merge_allele_snplist,
                signed_sumstats = signed_sumstats,
                num_samples = num_samples,
                output_basename = basename(sumstats_file,".gz")
        }
    }

    call UTIL.cat_files_with_headers as merge_munge_output{
        input:
            in_files = munge_chr_wf.munge_sumstats_chr_output,
            output_basename = basename(sumstats_file,".gz") + ".munged"
    }

    output{
        File munge_sumstats_output = merge_munge_output.output_file
    }
}



