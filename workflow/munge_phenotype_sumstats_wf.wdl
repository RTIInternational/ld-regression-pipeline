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
    String signed_sumstats

    Int? num_samples_col
    Int? num_samples

    File merge_allele_snplist
    Array[Pair[String, File]] legend_files

    # Unzip file if it needs to be unzipped
    if(basename(sumstats_file) != basename(sumstats_file,".gz")){
        call UTIL.gunzip as gunzip{
            input:
                in_file = sumstats_file
        }
        File unzipped_sumstat_file = gunzip.output_file
    }


    # Split file by chromosome
    # This small section is because we have to choose whether to split the original input file or the unzipped input from previous task
    Array[File?] possible_files = [unzipped_sumstat_file, sumstats_file]
    File to_split = select_first(possible_files)
    call UTIL.split_text_file_by_chr as split_by_chr{
        input:
            in_file = to_split,
            output_basename = basename(sumstats_file, ".gz"),
            chr_col = chr_col
    }

    # Map chromosome names to each split output file for easier indexing
    #Array[Pair[String, File]] split_chr_paired_array = zip(split_by_chr.chrs, split_by_chr.output_files)
    #Map[String, File] split_chr_file_map = as_map(split_chr_paired_array)

    # Munge_stats.py workflow for each chromosome
    scatter (chr_index in range(length(legend_files))){
        String chr = legend_files[chr_index].left
        File legend_file = legend_files[chr_index].right
        Int sumstats_file_index = split_by_chr.chr_index_map[chr]
        File sumstats_chr_file = split_by_chr.output_files[sumstats_file_index]
        call MUNGE_CHR_WF.munge_sumstats_chr_wf as munge_chr_wf{
            input:
                sumstats_in = sumstats_chr_file,
                id_col = id_col,
                chr_col = chr_col,
                pos_col = pos_col,
                a1_col = a1_col,
                a2_col = a2_col,
                beta_col = beta_col,
                pvalue_col = pvalue_col,
                num_samples_col = num_samples_col,
                legend_file = legend_file,
                chr = chr,
                merge_allele_snplist = merge_allele_snplist,
                signed_sumstats = signed_sumstats,
                num_samples = num_samples,
                output_basename = basename(sumstats_file,".gz")
        }
    }

    # Merge munged output for each chromosome into single file
    call UTIL.cat_files_with_headers as merge_munge_output{
        input:
            in_files = munge_chr_wf.munge_sumstats_chr_output,
            output_basename = basename(sumstats_file,".gz") + ".munged"
    }

    output{
        File munge_sumstats_output = merge_munge_output.output_file
    }
}



