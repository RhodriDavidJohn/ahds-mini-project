#!/bin/bash

date
echo "Downloading list of PubMed article IDs..."

# download the PubMed article IDs
curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=%22long%20covid%22&retmax=10000" > data/raw/pmids.xml


# download each article using the article IDs downloaded in the step above

# first get a list of all the ids
pmids=`cat data/raw/pmids.xml | sed -n 's|<Id>\(.*\)</Id>|\1|p'`

n_articles=${#pmids}

echo "Downloaded $n_articles article IDs."
echo 

load_time=$((n_articles/4))  # assuming it takes quarter of a second to download each article
est_time_s=$((n_articles+load_time)) # adding the number of articles because of sleep. this is the estimate in seconds
est_time_m=$((est_time_s/60))   # dividing by 60 to get estimate in minutes
est_time_h=$((est_time_m/60))   # divide by 60 again to get estimate in hours

sleep 1

echo "Downloading PubMed articles..."
echo "Estimated completion time: $est_time_h hours from..."
date
echo

sleep 1


# now loop through the list of ids and save each article to the raw data folder


counter=1
for pmid in $pmids
do
  curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=${pmid}" > data/raw/article-data-$pmid.xml
  echo "Downloaded $counter/$n_articles articles..."
  counter=$((counter+1))
  sleep 1
done

echo
echo "Finished data download."
date
