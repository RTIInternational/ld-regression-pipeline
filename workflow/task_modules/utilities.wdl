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

task untar {
    String tar_file
    Boolean gunzip = false
    String suffix = if gunzip then ".tar.gz" else ".tar"
    String output_dir = basename(tar_file, suffix)
    command{
        tar ${true="-xzvf" false="-xvf" gunzip} ${tar_file}
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
