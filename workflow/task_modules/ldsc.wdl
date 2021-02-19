task ldsc_rg{
    # Task for running LD regression between two phenotypes using LDSC

    # Munged sumstats files for trait of interest and a second train
    File ref_munged_sumstats_file
    File w_munged_sumstats_file

    # ld files needed for each
    Array[File] ref_ld_chr_files
    Array[File] w_ld_chr_files

    # Output filenames
    String output_basename
    String output_filename = output_basename + ".log"
    
    String docker = "404545384114.dkr.ecr.us-east-1.amazonaws.com/ldsc:v1.0.1_0bb574e"
    Int cpu = 6
    Int mem = 16

    command <<<

        source activate ldsc

        mkdir ref_ld_chr
        cp -r ${sep=' ./ref_ld_chr ; cp -r ' ref_ld_chr_files} ./ref_ld_chr
        ls -l ref_ld_chr

        mkdir w_ld_chr
        cp -r ${sep=' ./w_ld_chr ; cp -r ' w_ld_chr_files} ./w_ld_chr
        ls -l w_ld_chr

        ldsc.py \
            --rg ${ref_munged_sumstats_file},${w_munged_sumstats_file} \
            --ref-ld-chr ref_ld_chr/ \
            --w-ld-chr w_ld_chr/ \
            --out ${output_basename}
    >>>
    output {
       File output_file = "${output_filename}"
    }
    runtime {
        docker: docker
        cpu: cpu
        memory: "${mem} GB"
  }
}

task munge_sumstats{
    # Task for running LDSC munge_stats.py preprocessing script
    File sumstats_file
    File merge_allele_snplist
    String snp_colname
    String a1_colname
    String a2_colname
    String pvalue_colname
    String signed_sumstats
    Int? num_samples
    String output_basename
    String output_filename = "${output_basename}.sumstats.gz"
    
    String docker = "404545384114.dkr.ecr.us-east-1.amazonaws.com/ldsc:v1.0.1_0bb574e"
    Int cpu = 2
    Int mem = 6
    
    command {

        source activate ldsc

        if [[ "${num_samples}" != "-1" ]]; then
            munge_sumstats.py \
                --sumstats ${sumstats_file} \
                --a1 ${a1_colname} \
                --a2 ${a2_colname} \
                --merge-alleles ${merge_allele_snplist} \
                --snp ${snp_colname} \
                --signed-sumstats ${signed_sumstats} \
                --out ${output_basename} ${"--N " + num_samples}
        else
            munge_sumstats.py \
                --sumstats ${sumstats_file} \
                --a1 ${a1_colname} \
                --a2 ${a2_colname} \
                --merge-alleles ${merge_allele_snplist} \
                --snp ${snp_colname} \
                --signed-sumstats ${signed_sumstats} \
                --out ${output_basename}
        fi

    }
    output {
        File output_file = "${output_filename}"
    }
    runtime {
        docker: docker
        cpu: cpu
        memory: "${mem} GB"
  }
}
