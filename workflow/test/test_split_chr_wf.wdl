import "ld-regression-pipeline/workflow/task_modules/utilities.wdl" as UTIL

workflow test_split_chr_wf{

    File sumstat_file
    Int chr_col = 1

    call UTIL.split_text_file_by_chr as split_chr{
        input:
            in_file = sumstat_file,
            output_basename = "test_merge",
            chr_col = chr_col
    }

    output{
        Array[File] split_out = split_chr.output_files
    }
}
