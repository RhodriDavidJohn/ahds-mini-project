rule all:
    "The default rule"
    input: "results/topics_over_time.png"

rule download:
    "Download raw data"
    output: "data/raw/*"
    shell: """
    mkdir -p data/raw
    bash code/download_data.sh
    """

rule process:
    "Process the raw data"
    input: "data/raw/article-data-*.xml"
    output: "data/clean/*"
    shell: """
    mkdir -p data/clean
    bash code/extract_data.sh
    python code/process_data.py
    """

rule plot:
    "Make a plot of the article topic trends over time"
    input:
        "data/clean/*"
    output: "results/*.png"
    shell: """
    mkdir results
    python code/analysis.py
    """

rule clean:
    "Clean up"
    shell: """
    if [ -d code/raw ]; then
      rm -r code/raw
    else
      echo directory code/raw does not exist
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
