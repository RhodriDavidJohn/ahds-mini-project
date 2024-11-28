# -*- mode: snakemake -*-
import pandas as pd

configfile: "config/config.yml"

# get a list of all the PubMed article IDs
# to be used in the pipeline
pmid_df = pd.read_csv("data/raw/pmids.tsv",
                      sep = "\t")
pmids = pmid_df.loc[:,'PMID'].values.tolist()


rule all:
    "The default rule"
    input:
        expand("results/article_{article_char}_{suffix}.png",
               article_char=config["article_characteristics"],
               suffix=["topic_terms", "topics_over_time"])

rule download:
    "Download raw data"
    input:
        "data/raw/pmids.tsv"
    output: 
        expand("data/raw/article-data-{pmid}.xml", pmid = pmids)
    log:
        "logs/snakemake/download_data.log"
    shell: """
    mkdir -p logs/snakemake 2>&1 | tee {log}
    echo Starting data download 2>&1 | tee -a {log}
    date 2>&1 | tee -a {log}
    bash code/download_data.sh 2>&1 | tee -a {log}
    """

rule extract:
    "Extract from the raw data"
    input: 
        expand("data/raw/article-data-{pmid}.xml", pmid = pmids)
    output:
        "data/clean/extracted_data.tsv"
    log:
        "logs/snakemake/extract_data.log"
    shell: """
    echo "Begin extracting data from XML files" 2>&1 | tee {log}
    date 2>&1 | tee -a {log}
    mkdir -p data/clean 2>&1 | tee -a {log}
    bash code/extract_data.sh 2>&1 | tee -a {log}
    echo "Extraction complete" 2>&1 | tee -a {log}
    date 2>&1 | tee -a {log}
    """

for article_char in config["article_characteristics"]:
    rule:
        name: f"pre_process_{article_char}_data"
        params: article_characteristic = f"{article_char}"
        input:
            "data/clean/extracted_data.tsv"
        output: 
            f"data/clean/{article_char}_data.tsv",
            f"data/analysis/article_{article_char}_common_terms.png"
        log:
            f"logs/snakemake/pre_processing_{article_char}.log"
        shell: """
        echo "Begin pre-processing {params.article_characteristic} data" 2>&1 | tee {log}
        date 2>&1 | tee -a {log}
        mkdir -p data/analysis 2>&1 | tee -a {log}
        Rscript code/pre_processing.R {params.article_characteristic} 2>&1 | tee -a {log}
        echo "Finished pre-processing {params.article_characteristic} data" 2>&1 | tee -a {log}
        date 2>&1 | tee -a {log}
        """

for article_char in config["article_characteristics"]:
    rule:
        name: f"plot_{article_char}_data"
        params: article_characteristic = f"{article_char}"
        input:
            f"data/clean/{article_char}_data.tsv"
        output: 
            expand("results/article_{article_char}_{suffix}.png",
                   article_char = article_char,
                   suffix = ["topic_terms", "topics_over_time"])
        log:
            f"logs/snakemake/plot_{article_char}.log"
        shell: """
        echo "Begin plotting {params.article_characteristic} data" 2>&1 | tee {log}
        date 2>&1 | tee -a {log}
        mkdir -p results 2>&1 | tee -a {log}
        Rscript code/visualise_data.R {params.article_characteristic} 2>&1 | tee -a {log}
        echo "Finished plotting {params.article_characteristic} data" 2>&1 | tee -a {log}
        date 2>&1 | tee -a {log}
        """

rule clean:
    "Clean up"
    shell: """
    if [ `ls data/raw/* | wc -w` -gt 1 ];
    then
      echo "Directory 'data/raw' is populated with article data."
      echo "Removing all article data (XML files) in directory"
      rm data/raw/article-data-*.xml
    else
      echo "Directory 'data/raw' is empty of article data, continue with downloads"
    fi
    if [ -d data/clean ]; then
      echo "Removing directory data/clean"
      rm -r data/clean
    else
      echo directory code/clean does not exist
    fi
    if [ -d results ]; then
      echo "Removing directory results"
      rm -r results
    else
      echo directory results does not exist
    fi
    """
