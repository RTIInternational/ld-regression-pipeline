import "ld-regression-pipeline/workflow/task_modules/utilities.wdl" as UTIL

task parse_log_file{
    File ld_regression_log
    String output_filename = basename(ld_regression_log, ".log") + ".parsed.tsv"

    command<<<
        # Get results as tsv
        tail ${ld_regression_log} | grep -A 1 "p1" | sed 's/ \+/\t/g' > ${output_filename}
    >>>
    output{
        File output_file = "${output_filename}"
    }
    runtime{
        docker: "ubuntu:18.04"
        cpu: "1"
        memory: "1 GB"
    }
}

task make_label_data_tsv{
    Array[String] trait_labels
    Array[String] group_labels
    String output_basename
    String output_filename = "${output_basename}.plot_metadata.tsv"
    command{

        # Output trait names to txt file
        for line in '${sep="' '" trait_labels}';do
            echo "$line" >> trait.txt
        done

        # Output group names to txt file
        for line in '${sep="' '" group_labels}';do
            echo "$line" >> group.txt
        done

        # Combine in to TSV
        paste trait.txt group.txt > tmpfile.tsv

        # Add column names
        echo -e "Trait_Label\tTrait_Group" | cat - tmpfile.tsv > ${output_filename}

    }
    output{
        File output_file = "${output_filename}"
    }
    runtime{
        docker: "ubuntu:18.04"
        cpu: "1"
        memory: "1 GB"
    }
}

task plot_ld_regression_results{
    File ld_results_file
    String output_filename
    Boolean comma_delimited = false
    File? group_order_file
    Float? pvalue_threshold
    
    String docker = "rtibiocloud/plot_ld_regression_results:v1.0_0f1f25f"
    Int cpu = 1
    Int mem = 1
    
    command{
        Rscript /opt/plot_ld_regression/plot_ld_regression_results.R --input_file ${ld_results_file} \
            --output_file ./${output_filename} ${true="--comma_delimited" false="" comma_delimited} ${"--group_order_file " + group_order_file} ${"--pvalue_threshold " + pvalue_threshold}
    }
    output{
        File output_file = "${output_filename}"
    }
    runtime{
        docker: docker
        cpu: cpu
        memory: "${mem} GB"
    }
}

workflow plot_ld_regression_wf{

    String analysis_name
    Array[File] ldsc_regression_logs
    Array[String] trait_labels
    Array[String] group_labels

    String pvalue_cor_method = "bonferroni"

    File? group_order_file
    Float? pvalue_threshold


    # Output additional data to TSV
    Array[Array[String]] plot_data = [trait_labels, group_labels]
    Array[Array[String]] label_data = transpose(plot_data)
    call make_label_data_tsv{
        input:
            trait_labels = trait_labels,
            group_labels = group_labels,
            output_basename = analysis_name
    }

    # Parse each log file to get only information needed as TSV table
    scatter(ldsc_log_file in ldsc_regression_logs){
        call parse_log_file{
            input:
                ld_regression_log = ldsc_log_file
        }
    }

    # Merge into single table
    call UTIL.cat_files_with_headers as merge_logs{
        input:
            in_files = parse_log_file.output_file,
            output_basename = analysis_name + ".merged_ld_regression_results.tsv"
    }

    # Combine into single table
    call UTIL.paste as make_plot_table{
        input:
            in_files = [make_label_data_tsv.output_file, merge_logs.output_file],
            output_filename = analysis_name + ".ld_regression_results.tsv"
    }

    call UTIL.adj_csv_pvalue as adj_pvalues{
        input:
            input_file = make_plot_table.output_file,
            pvalue_colname = "p",
            method = pvalue_cor_method,
            output_filename = analysis_name + ".ld_regression_results.adj_pvalue.csv",
            tab_delimited = true
    }

    call plot_ld_regression_results{
        input:
            ld_results_file = make_plot_table.output_file,
            output_filename = analysis_name + ".ld_regression_results.pdf",
            group_order_file = group_order_file,
            pvalue_threshold = pvalue_threshold
    }

    output{
        File ld_regression_results_table = adj_pvalues.output_file
        File ld_regression_results_plot  = plot_ld_regression_results.output_file
    }
}
