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

workflow test_merge_wf{

    Array[File] sumstats_files

        scatter (sumstat_file in sumstats_files){
            call gunzip{
                input:
                    in_file = sumstat_file
             }
        }

        call UTIL.cat_files_with_headers as merge_munge_output{
        input:
            in_files = gunzip.output_file,
            output_basename = "test_merge"
    }

    output{
        File munge_sumstats_output = merge_munge_output.output_file
    }
}
