task ldsc{
    # Task for running S-PrediXcan on a single tissue expression database
    File model_db_file
    File covariance_file
    Array[File] gwas_files
    String snp_column
    String effect_allele_column
    String non_effect_allele_column
    String beta_column
    String pvalue_column
    String se_column
    String output_base = basename(model_db_file, ".db")
    String output_file = output_base + ".ldsc_results.txt"
    command {

        source activate ldsc

        ldsc.py \
            --model_db_path ${model_db_file} \
            --covariance ${covariance_file} \
            --gwas_folder ./gwas_dir \
            --beta_column ${beta_column} \
            --pvalue_column ${pvalue_column} \
            --effect_allele_column ${effect_allele_column} \
            --non_effect_allele_column ${non_effect_allele_column} \
            --snp_column ${snp_column} \
            --se_column ${se_column} \
            --output_file ${output_file}
    }
    output {
        File ldsc_output = output_file
    }
    runtime {
        docker: "rticode/ldsc:7618f4943d8f31a37cbd207f867ba5742d03373f"
        cpu: "6"
        memory: "16 GB"
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
        docker: "rticode/ldsc:7618f4943d8f31a37cbd207f867ba5742d03373f"
        cpu: "2"
        memory: "6 GB"
  }
}