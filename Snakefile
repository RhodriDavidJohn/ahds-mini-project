# -*- mode: snakemake -*-
import pandas as pd

configfile: "config/config.yml"

# get a list of all the PubMed article IDs
# to be used in the pipeline
try:
    pmid_df = pd.read_csv("data/raw/pmids.tsv",
                          sep = "\t")
    pmids = pmid_df.loc[:,'PMID'].values.tolist()
    pmid_batches = sorted(set([str(pmid)[:2] for pmid in pmids]))
    pmids_dict = {
        batch: [pmid for pmid in pmids if str(pmid).startswith(batch)] for batch in pmid_batches
    }
except Exception as e:
    print(f"{e}: Check data/raw/pmids.tsv")
    raise(e)


rule all:
    "The default rule"
    input:
        expand("results/article_{article_char}_{n_topics}_{suffix}.png",
               article_char=config["article_characteristics"],
               n_topics=config["number_of_topics"],
               suffix=["topic_terms", "topics_over_time"])

rule reset_articles:
    "Reload the available PMIDs to analyse more/new articles"
#    output:
#        "data/raw/pmids.tsv"
    log:
        "logs/snakemake/reset_articles.log"
    shell: """
    echo Loading set of article PMIDs 2>&1 | tee {log}
    bash code/get_pmids.sh 2>&1 | tee -a {log}
    echo Downloaded set of article PMIDs 2>&1 | tee -a {log}
    """

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

for batch, ids in pmids_dict.items():
    rule:
        name:
            f"extract_batch_{batch}"
        params:
            batch = f"{batch}"
        input:
            expand("data/raw/article-data-{pmid}.xml", pmid = ids)
        output:
            f"data/clean/{batch}_extracted_data.tsv"
        log:
            f"logs/snakemake/{batch}_extract_data.log"
        shell: """
        echo "Begin extracting data from XML files beginning with {params.batch}" 2>&1 | tee {log}
        date 2>&1 | tee -a {log}
        mkdir -p data/clean 2>&1 | tee -a {log}
        bash code/extract_data.sh {params.batch} 2>&1 | tee -a {log}
        echo "Extraction of batch {params.batch} complete" 2>&1 | tee -a {log}
        date 2>&1 | tee -a {log}
        """

for article_char in config["article_characteristics"]:
    rule:
        name: f"pre_process_{article_char}_data"
        params: 
            article_characteristic = f"{article_char}",
            batches = ",".join(list(pmid_batches))
        input:
            expand("data/clean/{batch}_extracted_data.tsv", batch = pmid_batches)
        output: 
            f"data/clean/{article_char}_data.tsv",
            f"data/analysis/article_{article_char}_common_terms.png"
        log:
            f"logs/snakemake/pre_processing_{article_char}.log"
        shell: """
        echo "Begin pre-processing {params.article_characteristic} data" 2>&1 | tee {log}
        date 2>&1 | tee -a {log}
        mkdir -p data/analysis 2>&1 | tee -a {log}
        Rscript code/pre_processing.R {params.article_characteristic} {params.batches} 2>&1 | tee -a {log}
        echo "Finished pre-processing {params.article_characteristic} data" 2>&1 | tee -a {log}
        date 2>&1 | tee -a {log}
        """

for article_char in config["article_characteristics"]:
    rule:
        name: f"plot_{article_char}_data"
        params: 
            article_characteristic = f"{article_char}",
            n_topics = config["number_of_topics"]
        input:
            f"data/clean/{article_char}_data.tsv"
        output: 
            expand("results/article_{article_char}_{n_topics}_{suffix}.png",
                   article_char = article_char,
                   n_topics = config["number_of_topics"],
                   suffix = ["topic_terms", "topics_over_time"])
        log:
            f"logs/snakemake/plot_{article_char}.log"
        shell: """
        echo "Begin plotting {params.article_characteristic} data" 2>&1 | tee {log}
        date 2>&1 | tee -a {log}
        mkdir -p results 2>&1 | tee -a {log}
        Rscript code/visualise_data.R {params.article_characteristic} {params.n_topics} 2>&1 | tee -a {log}
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
