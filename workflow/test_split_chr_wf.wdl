import "ld-regression-pipeline/workflow/task_modules/utilities.wdl" as UTIL

task gunzip{
    File in_file
    String out_filename = basename(in_file, ".gz")
    command{
        gunzip -c ${in_file} > ${out_filename}
    }
    output{
        File output_file = "${out_filename}"
    }
    runtime{
        docker: "ubuntu:18.04"
        cpu: "1"
        memory: "1 GB"
    }
}

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
