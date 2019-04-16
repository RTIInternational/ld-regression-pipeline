task standardize_sumstat_cols{
    # Standardizes GWAS/Meta-analysis input files to expected format for pipelines
    # Replaces spaces with tabs to ensure tab delimited
    # Re-arranges columns to be in standard order
    # Standardizes column names

    File sumstats_file
    Int id_col
    Int chr_col
    Int pos_col
    Int a1_col
    Int a2_col
    Int beta_col
    Int pvalue_col
    Int num_samples_col = -1
    String output_filename = basename(sumstats_file, ".gz") + ".standardized.txt"
    String tmp_filename = "unzipped_gxg_file.txt"
    command<<<
        set -e

        input_file=${sumstats_file}

        # Unzip file if necessary
        if [[ ${sumstats_file} =~ \.gz$ ]]; then
            echo "${sumstats_file} is gzipped. Unzipping..."
            gunzip -c ${sumstats_file} > ${tmp_filename}
            input_file=${tmp_filename}
        fi

        # Replace spaces with tabs
        sed -i 's/ /\t/g' $input_file

        num_sample_col="${num_samples_col}"

        if [[ "$num_sample_col" != "-1" ]]; then

            # Re-arrange colunns
            awk -v OFS="\t" -F"\t" '{print $${id_col},$${chr_col},$${pos_col},$${a1_col},$${a2_col},$${beta_col},$${pvalue_col},$${num_samples_col}}' \
                $input_file \
                > ${output_filename}

            # Standardize column names
            sed -i "1s/.*/MarkerName\tchr\tposition\tA1\tA2\tBETA\tP\tN/" ${output_filename}

        else
            # Re-arrange colunns
            awk -v OFS="\t" -F"\t" '{print $${id_col},$${chr_col},$${pos_col},$${a1_col},$${a2_col},$${beta_col},$${pvalue_col}}' \
                $input_file \
                > ${output_filename}

            # Standardize column names
            sed -i "1s/.*/MarkerName\tchr\tposition\tA1\tA2\tBETA\tP/" ${output_filename}
        fi

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

task convert_to_1000g_ids {
    File in_file
    File legend_file
    Int contains_header = 1
    Int id_col
    Int chr_col
    Int pos_col
    Int a1_col
    Int a2_col
    Int chr
    String output_filename = basename(in_file, ".txt") + ".phase3ID.txt"
    command{

        set -e

        /opt/code_docker_lib/convert_to_1000g_ids.pl \
            --file_in ${in_file} \
            --file_out ${output_filename} \
            --legend ${legend_file} \
            --file_in_header ${contains_header} \
            --file_in_id_col ${id_col} \
            --file_in_chr_col ${chr_col} \
            --file_in_pos_col ${pos_col} \
            --file_in_a1_col ${a1_col} \
            --file_in_a2_col ${a2_col} \
            --chr ${chr}
    }
    output {
        File output_file = "${output_filename}"
    }
    runtime{
        docker: "rticode/convert_to_1000g_ids:fe710d550c9ff0d100d0b7c37db580362488e8fc"
        cpu: "2"
        memory: "8 GB"
    }

}

task reformat_for_munge_sumstats {
    File in_file
    String output_filename = basename(in_file, ".txt") + ".munge_ready.txt"
    command<<<

        set -e

        # Perl one-liner to:
        #   1. Print header line
        #   2. Exclude lines that don't start with rs
        #   3. Extract only rsid from id field to be compatible with LDHub snplist

        perl -lane 'if($. == 1){print;} elsif(/rs/){$F[0] = (split /:/,$F[0])[0]; print join("\t",@F);}' ${in_file} > ${output_filename}
    >>>
    output {
        File output_file = "${output_filename}"
    }
    runtime{
        docker: "ubuntu:18.04"
        cpu: "1"
        memory: "2 GB"
    }

}

task remove_empty_variants {
    File in_file
    String output_filename = basename(in_file, ".gz") + ".no_empty_variants.txt"
    command{
        zgrep -E "G|C|T|A|g|c|t|a" ${in_file} > ${output_filename}
    }
    output {
        File output_file = "${output_filename}"
    }
    runtime{
        docker: "ubuntu:18.04"
        cpu: "1"
        memory: "2 GB"
    }

}
