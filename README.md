# Applied Health Data Science - Summative Mini Project

## Overview
The aim of this mini project is to explore trends in COVID-19 publications. To achieve this, we
will download, process and visualize data on the text of research articles.

All tasks are designed to run on the high performance computer (HPC) BlueCrystal as part of a SnakeMake pipeline.


## More Information
### Project
This project aims to explore trends in PubMed articles about long COVID-19. The project can be split into 4 main steps to achieve this; Data download, Data extraction, Data cleaning, and Data visualisation.
The data are downloaded as XML files from PubMed using the E-utilities application programming interface (API) using shell scripts.
The data are then cleaned and tidied using Shell and R so that the data can be easily analysed.
Finally, the data are analysed using Latent Dirichlet Allocation (LDA) topic modelling and visualised in R.

### Tech Stack
Environment management:
        - conda
Programming languages:
        - Shell
        - R (version 4.4.2)
                - tidyverse
                - janitor
                - tidytext
                - topicmodels
                - ggplot2
        - Python (version 3.12.7)
                - snakemake
                - pandas
High performance computing:
        - BlueCrystal
        - Slurm

### Instructions
#### One time set-up
Before running the pipeline on the HPC for the first time you must follow some set-up steps.
First, clone this git repository to a suitable area of the login node in the HPC by running the following command:
```
git clone https://github.com/RhodriDavidJohn/ahds-mini-project.git
```
Before starting the set-up, ensure you have cloned the git repository and you are in the root directory of the repository.

##### Set up Slurm profile to run pipeline
You will only need to set up the Slurm profile once.
To do this run the following command to submit a Slurm job to set up your Slurm profile:
```
sbatch code/setup/hpc_setup_job.sh
```
You can check the progress of the job by running the command:
```
sacct -j {job-id} -X
```
Note, you will need to replace {job-id} with the job ID given by the first command.

##### Set up Conda environment
First you will need to ensure that you have correctly set up Conda on the HCP.
Then you can create and activate the environment for the pipeline by running the following commands, again ensuring you are in the root directory of the repository:
```
source ~/initConda.sh
CONDA_SUBDIR=linux-64 conda env create -n ahds-summative-env --file environment.yml
conda activate ahds-summative-env
```
Note, you will only need to create the environment once.
After you have created the environment, if you ever want to activate it, simply run the following commands:
```
source ~/initConda.sh
conda activate ahds-summative-env
```

#### Running the pipeline
If you have successfully completed the HCP set-up steps above and the Conda environment is active, then you can run the pipeline.

##### tmux
It is useful to run the pipeline within a tmux session so that you can continue to use the HCP while the pipeline is running. This is particularly useful as the pipeline takes about an hour and a quarter to complete.

To create a new tmux session run the following command in the HCP login node: `tmux`
To return to the login node, type:
```
Ctrl+b,d  # Windows
Cmd+b,d   # Mac
```
To return to the tmux session run the following command: `tmux a`

To kill the tmux session run the following command: `exit`


##### Pipeline commands
To produce the most up to date set of article PMIDs, run the following command:
```
snakemake --executor slurm --profile ahds_slurm_profile reset_articles
```

To run the full pipeline, run the following command:
```
snakemake --executor slurm --profile ahds_slurm_profile
```

If you want to clean the repository (i.e., remove all article data [not the PMIDs], remove the cleaned data and remove the results), run the following command:
```
snakemake --executor slurm --profile ahds_slurm_profile clean
```


## Data
The data for this project are downloaded from PubMed (https://pubmed.ncbi.nlm.nih.gov/) which is a free online database of research articles, including their titles, abstracts and meta data such as publication date and author list. Each
article has a PubMed ID (PMID) that is unique for that article. PubMed has an application programming interface (API) that allows us to access the database programmatically (by writing commands and scripts) rather than through the website.

First the get_pmids.sh shell script in the code directory downloads the article PubMed IDs (PMID) as an XML file and then extracts the PMIDs and saves them in a tab-seperated values (TSV) file in data/raw/pmids.tsv. There are 6,526 article PMIDs for this project. Note that this step is not part of the pipeline.

The 6,526 long covid article data are then downloaded using the download_data.sh shell script in the code directory. The data from PubMed are of the form of XML files.

The shell script extract_data.sh in the code directory then extracts the PMID, article publish year, title and abstact from each article and saves the data from all articles as a single tab seperated values (TSV) file called extracted_data.tsv. This file is then used for the analysis.


## Methods
### Packages
The data are pre-processed and analysed using R version 4.4.2 and the following R packages; janitor, tidyverse, tidytext, topicmodels, and ggplot2.

### Pre-processing
After extracting the relevant PubMed article data, the data are then pre-processed ready for analysis. The pre-processing includes two main steps; data cleaning and transforming the data to a tidy (long) format.

#### Data cleaning
The first steps of the data cleaning are to transform the column headers from CamelCase to snake_case and to remove any rows with missing PMID or year values. Missing PMIDs can occur if article data are currupt which causes the data extraction to confuse XML tags. Years can be missing within the XML files, and since there is not an order to the XML files it is difficult to iput the publish year using methods like forward fill. Furthermore, since there are only 35 and 4 articles with a publish year of 2020 and 2025, respectively, articles published in 2020 and 2025 are removed for the analysis.

At this point the etracted data are split into two tables, one for the article title data and the other for the article abstract data. The following cleaning steps are then performed on both datasets; drop any row with missing text data, remove all XML tags such as \<i\>\<\i\> from the text, remove all non-alphabetic characters from the text.

#### Data tidying
The two cleaned datasets then have the same tidying process applied to each of them. The process is as follows; unnest the text tokens, remove standard English stopwords, remove subject specific stopwords which are detected using term frequency - inverse document frequency (tf-idf). This tidying step ensures the data is ready for analysis. Both datasets are then saved as TSV files to data/clean/title_data.tsv and data/clean/abstract_data.tsv, respectfully. Furthermore, a plot highlighting the most common words by year is outputed as data/analysis/article_title_common_words.png and data/analysis/article_abstract_common_words.png. These plots are usefult to visualize some of the subject specific stopwords.


### Analysis/Visualisation
The article text data are analysed using Latent Dirichlet Allocation (LDA) topic modelling. This is an unsupervised machine learning approach that aims to understand the topics of the articles. The number of topics can be chosen by the user using the config/config.yml file. This allows the user to experiment with different topic number values. However, the default for this analysis is to assume that there are 3 main topics of articles; this was decided by trialling different number of topics and assessing the interpretability of them, with 3 topics providing the most interperatable topics.

The 5 most common terms within each topic, as well as their probability of being generated from the topic (beta), is outputed as a PNG file results/article_{article_characteristic}_topic_terms.png.

The analysis of the text data is visually outputed as a PNG file to results/article_{article_characteristic}_topics_over_time.png. This plot shows the proportion of articles for each topic (predicted by the LDA model) over time (2021-2024). This shows how the general article topic trends change over time.