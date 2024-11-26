# Applied Health Data Science - Summative Mini Project

## Overview
The aim of this mini project is to explore trends in COVID-19 publications. To achieve this, we
will download, process and visualize data on the text of research articles.

All tasks are designed to run on the high performance computer (HPC) BlueCrystal as part of a SnakeMake pipeline.


## More Information




## Data
The data for this project are downloaded from PubMed (https://pubmed.ncbi.nlm.nih.gov/) which is a free online database of research articles, including their titles, abstracts and meta data such as publication date and author list. Each
article has a PubMed ID that is unique for that article. PubMed has an application programming interface (API) that allows us to access the database programmatically (by writing commands and scripts) rather than through the website.

First the get_pmids.sh shell script in the code directory downloads the article PubMed IDs (PMID) as an XML file and then extracts the PMIDs and saves them in a tab-seperated values (TSV) file in data/raw/pmids.tsv. There are 6,488 article PMIDs for this project.

The 6,488 long covid article data are then downloaded using the download_data.sh shell script in the code directory. The data from PubMed are of the form of XML files.

The shell script extract_data.sh in the code directory then extracts the PMID, article publish year, title and abstact from each article and saves the data from all articles as a single tab seperated values (TSV) file called extracted_data.tsv. This file is then used for the analysis.


## Methods
### Packages
The data are pre-processed and analysed using R version 4.4.2 and the following R packages; janitor, tidyverse, tidytext, topicmodels, and ggplot2.

### Pre-processing
After extracting the relevant PubMed article data, the data are then pre-processed ready for analysis. The pre-processing includes two main steps; data cleaning and transforming the data to a tidy (long) format.

#### Data cleaning
The first steps of the data cleaning are to transform the column headers from CamelCase to snake_case and to remove any rows with missing PMID or year values. Missing PMIDs can occur if article data are currupt which causes the data extraction to confuse XML tags. Years can be missing within the XML files, and since there is not an order to the XML files it is difficult to iput the publish year using methods like forward fill. Furthermore, since there are only 5 articles with a publish year of 2025, articles published in 2025 are removed for the analysis.

At this point the etracted data are split into two tables, one for the article title data and the other for the article abstract data. The following cleaning steps are then performed on both datasets; drop any row with missing text data, remove all XML tags such as \<i\>\<\i\> from the text, remove all non-alphabetic characters from the text.

#### Data tidying
The two cleaned datasets then have the same tidying process applied to each of them. The process is as follows; unnest the text tokens, remove stopwords, remove the words 'covid' and 'long' (since all articles are about long covid). This tidying step ensures the data is ready for analysis. Both datasets are then saved as TSV files to data/clean/title_data.tsv and data/clean/abstract_data.tsv, respectfully.


### Analysis
The article text data are analysed using Latent Dirichlet Allocation (LDA) topic modelling. This is an unsupervised machine learning approach that aims to understand the topics of the articles. In particular, the analysis assumes there are 3 main topics of articles; this was decided by trialling different number of topics and assessing the interpretability of them, with 3 topics providing the most interperatable topics.

The 5 most common terms within each topic, as well as their probability of being generated from the topic, is outputed as a PNG file results/article_{article_characteristic}_topic_terms.png.

The analysis of the text data is visually outputed as a PNG file to results/article_{article_characteristic}_topics_over_time.png. This plot shows the proportion of articles for each topic (predicted by the LDA model) over time (2020-2024). This shows how the general article topic trends change over time.