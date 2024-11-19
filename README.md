# Applied Health Data Science - Summative Mini Project

## Overview
The aim of this mini project is to explore trends in COVID-19 publications. To achieve this, we
will download, process and visualize data on the text of research articles.

All tasks are designed to run on the high performance computer (HPC) BlueCrystal as part of a SnakeMake pipeline.


## Background




## Data
The data for this project are downloaded from PubMed (https://pubmed.ncbi.nlm.nih.gov/) which is a free online database of research articles, including their titles, abstracts and meta data such as publication date and author list. Each
article has a PubMed ID that is unique for that article. PubMed has an application programming interface (API) that allows us to access the database programmatically (by writing commands and scripts) rather than through the website.

The data are downloaded using the download_data.sh shell script in the code directory. The data from PubMed are of the form of XML files; first an XML file including all relevent article PubMed IDs (PMID) is downloaded and used to to download 64,799 articles.

The shell script extract_data.sh in the code directory then extracts the PMID, article year, title and abstact and keywords/MESH terms from each article and saves the data from all articles as a single tab seperated values (TSV) file called extracted_data.tsv. This file is then used for the analysis.


## Analysis
