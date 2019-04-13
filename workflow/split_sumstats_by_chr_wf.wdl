import "ld-regression-pipeline/workflow/task_modules/utilities.wdl" as UTIL

workflow split_sumstats_by_chr_wf{

    File sumstat_file
    Int chr_col = 1
    String output_basename = "test_split_chr"

    # Unzip file if it needs to be unzipped
    if(basename(sumstat_file) != basename(sumstat_file,".gz")){
        call UTIL.gunzip as gunzip{
            input:
                in_file = sumstat_file
        }
        File unzipped_sumstat_file = gunzip.output_file
    }

    # Split either the newly unzipped file or the original file depending on whether original file was zipped
    Array[File?] possible_files = [unzipped_sumstat_file, sumstat_file]
    File to_split = select_first(possible_files)

    # Split file by chromosome
    call UTIL.split_text_file_by_chr as split_chr{
        input:
            in_file = to_split,
            output_basename = output_basename,
            chr_col = chr_col
    }

    output{
        Array[File] output_files = split_chr.output_files
    }
}