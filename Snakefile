# -*- mode: snakemake -*-
import pandas as pd

configfile: "config.yml"

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
               suffix=["topic_trends", "topics_over_time"])

rule download:
    "Download raw data"
    input:
        "data/raw/pmids.tsv"
    output: 
        expand("data/raw/article-data-{pmid}.xml", pmid = pmids)
    shell: """
    echo Starting data download
    date
    bash code/download_data.sh
    """

rule process:
    "Process the raw data"
    input: 
        expand("data/raw/article-data-{pmid}.xml", pmid = pmids)
    output:
        "data/clean/extracted_data.tsv",
        "data/clean/title_data.tsv",
        "data/clean/abstract_data.tsv"
    shell: """
    mkdir -p data/clean
    bash code/extract_data.sh
    Rscript code/clean_data.R
    """

for article_char in config["article_characteristics"]:
    rule:
        name: f"plot_{article_char}_data"
        params: article_characteristic = f"{article_char}"
        input:
            f"data/clean/{article_char}_data.tsv"
        output: 
            expand("results/article_{article_char}_{suffix}.png",
                   article_char=article_char,
                   suffix=["topic_trends", "topics_over_time"])
        shell: """
        mkdir results
        Rscript code/visualise_data.R {params.article_characteristic}
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
    if [ -d code/clean ]; then
      rm -r code/clean
    else
      echo directory code/clean does not exist
    fi
    if [ -d results ]; then
      rm -r results
    else
      echo directory results does not exist
    fi
    """
