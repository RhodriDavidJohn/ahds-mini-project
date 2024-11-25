#!/bin/bash

echo
echo "Checking if directory 'data/raw' is populated"
sleep 1
if [ `ls data/raw/* | wc -w` -gt 0 ];
then
  echo "Directory 'data/raw' is populated. Removing all files in directory"
  rm data/raw/*
else
  echo "Directory 'data/raw' is empty, continue with downloads"
fi

sleep 1

echo
echo "Downloading PMIDs from PubMed and saving as 'data/raw/pmids.xml'"

# download the PubMed article IDs
curl -s \
"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=%22long%20covid%22&retmax=10000" \
> data/raw/pmids.xml

# get a string of all the ids
pmids=`cat data/raw/pmids.xml | sed -n 's|<Id>\(.*\)</Id>|\1|p'`

sleep 1

# create a new tab-separated values file for the PMIDs
echo "Saving PMIDs as 'data/raw/pmids.tsv'"

echo -e "PMID" > "data/raw/pmids.tsv"

for id in $pmids;
do
  echo -e "$id" >> "data/raw/pmids.tsv" & # ¶ simble makes process concurrent
done

# remove the xml file as it is now not needed
echo
echo "Removing the XML file downloaded from PubMed 'data/raw/pmids.xml'"
rm data/raw/pmids.xml

echo
echo "FINISHED"
echo
