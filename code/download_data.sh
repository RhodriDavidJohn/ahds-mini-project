#!/bin/bash

# create an array of PubMed IDs
arr_pmids=($(tail -n +2 data/raw/pmids.tsv))

# get the total number of articles
n_articles=${#arr_pmids[@]}

echo
echo "There are $n_articles articles to download."

# specify the number of articles to download at one
max_batch_size=3 # Requests without an API key have a rate limit of 3 requests/second
n_batches=$(((n_articles+(max_batch_size-1))/max_batch_size))
echo "Articles IDs are divided into $n_batches batches of size $max_batch_size to download."

sleep 1

# calculate an estimate for download time
load_time=$((n_batches/2))  # assuming it takes half a second to download each batch
est_time_s=$((n_batches+load_time)) # adding the number of articles because of sleep. this is the estimate in seconds
est_time_m=$((est_time_s/60))   # dividing by 60 to get estimate in minutes


# Split into subarrays and loop through
source code/utils/progress_bar.sh

echo
echo "Downloading PubMed articles..."
echo "Estimated completion time: $est_time_m minutes from"
date
echo

counter=1

for ((i=0; i<n_articles; i+=max_batch_size)); do
  subarray=("${arr_pmids[@]:i:max_batch_size}")
  
  # Loop over elements in the subarray
  for pmid in "${subarray[@]}"; do
    curl -s \
    "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=${pmid}" \
    > data/raw/article-data-$pmid.xml & # & simble makes the 3 downloads happen concurrently
  done

  wait # wait for all downloads to finish before proceeding
  show_progress $counter $n_batches # track the progress e.g. [####-----] 40.00%
  counter=$((counter+1))
  sleep 1 # so the api doesn't get overwhelmed
done

echo "Finished data download"
date
echo