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

task cat_files_with_headers {
    # Cats a set of files which have headers
    # Includes one copy of header at top of concatentated file and removes header from all other files
    Array[File] in_files
    String output_basename
    String output_filename = output_basename + ".merged.txt"
    command {
        awk '(NR == 1) || (FNR > 1)' ${sep=" " in_files} > ${output_filename}
    }
    output{
        File output_file = "${output_filename}"
    }
    runtime {
        docker: "ubuntu:18.04"
        cpu: "1"
        memory: "1 GB"
    }
}

task split_text_file_by_chr {
    File in_file
    Int chr_col
    String output_basename
    command<<<

        set -e

        # Split by chromosome
        awk 'NR==1{ h=$0 }NR>1{ print (!a[$${chr_col}]++? h ORS $0 : $0) > "${output_basename}.chr"$${chr_col}".merged.txt" }' ${in_file}

        # Print chromosome names and the index of each chromosome split in the file array
        #ls -l *merged.txt | perl -lne 'print $1 if /.+chr(\w+)\.merged.*/'

        ls -l *merged.txt | perl -lne 'print "$1\t".($.-1) if /.+chr(\w+)\.merged.*/'

    >>>
    output{
        Array[File] output_files = glob("${output_basename}*")
        Map[String, Int] chr_index_map = read_map(stdout())
    }
    runtime {
        docker: "ubuntu:18.04"
        cpu: "1"
        memory: "1 GB"
    }
}

task get_colname_index {
    String colname
    File in_file
    command<<<
        head -n 1 ${in_file} | perl -lane 'for my $i (0 .. $#F){ if( $F[$i] eq "${colname}" ){print $i + 1; exit;} elsif( $i == (scalar @F) -1 ){die "Colname not found!"}};'
    >>>
    output{
        Int index = read_int(stdout())
    }
    runtime {
        docker: "ubuntu:18.04"
        cpu: "1"
        memory: "1 GB"
    }
}

task adj_csv_pvalue{
    # Take used to take a CSV file with a columns of pvalues as input
    # Outputs the same CSV with p-values adjusted for multiple comparisons
    # Optionally can include a filter threshold to omit row entries with p-values above threshold from output
    File input_file
    String pvalue_colname
    String method
    String output_filename
    Float? filter_threshold
    Int? num_comparisons

    # Boolean for whether input file is tab delimited (default is false to assume comma-separated)
    Boolean tab_delimited = false

    command {
        Rscript /opt/code_docker_lib/adjust_csv_pvalue.R --input_file ${input_file} \
            --output_file ./${output_filename} \
            --pvalue_colname ${pvalue_colname} \
            --method ${method} ${"--n " + num_comparisons} ${"--filter_threshold " + filter_threshold} ${true="--tab_delimited" false="" tab_delimited}
    }
    output{
        # Count number of records by subtracting out header line for each file
        File output_file = "${output_filename}"
    }
    runtime {
        docker: "alexwaldrop/adjust_csv_pvalue:a40b48623a4877766f8a388046a2dd2cebe9d8f6"
        cpu: "1"
        memory: "1 GB"
    }
}

task paste {
    Array[File] in_files
    String output_filename
    String? delim

    command{
        paste ${"-d '" + delim + "'"} ${sep = " " in_files} > ${output_filename}
    }
    output{
        File output_file = "${output_filename}"
    }
    runtime {
        docker: "ubuntu:18.04"
        cpu: "1"
        memory: "1 GB"
    }

}

task untar {
    File tar_file
    String suffix
    String tar_options
    String output_dir = basename(tar_file, suffix)
    command{
        tar  ${tar_options} ${tar_file}
    }
    output{
        Array[File] output_files = glob("${output_dir}/*")
    }
    runtime {
        docker: "ubuntu:18.04"
        cpu: "1"
        memory: "1 GB"
    }
}

workflow untar_wf{

    File tar_file
    String suffix = ".tar"
    String tar_options = "-xvf"

    # Check to see if tar file is gzipped
    if(basename(tar_file, ".tar.gz") != basename(tar_file)){
        String gunzip_suffix = ".tar.gz"
        String gunzip_tar_options = "-xzvf"
    }

    # Check for another common gzipped-tar suffix
    if(basename(tar_file, ".tgz") != basename(tar_file)){
        String tgz_suffix = ".tar.gz"
        String tgz_tar_options = "-xzvf"
    }

    # Check to see if tar file is bz2 zipped
    if(basename(tar_file, ".tar.bz2") != basename(tar_file)){
        String bz2_suffix = ".tar.bz2"
        String bz2_tar_options = "-xjvf"
    }

    # Detect final options for untarring based on suffix
    String final_suffix = select_first([bz2_suffix, gunzip_suffix, tgz_suffix, suffix])
    String final_tar_options = select_first([bz2_tar_options, gunzip_tar_options, tgz_tar_options, tar_options])

    call untar{
        input:
            tar_file = tar_file,
            suffix = final_suffix,
            tar_options = final_tar_options
    }

    output{
        Array[File] output_files = untar.output_files
    }
}
