#!/bin/bash

batch=$1
pmids=$2

# Directory containing XML files
n_pmids=$(echo $pmids | wc -w)
echo "Number of articles to be processed: n_pmids"

# Output TSV file
OUTPUT_TSV="data/clean/${batch}_extracted_data.tsv"

# Create or clear the output file
echo -e "PMID\tYear\tArticleTitle\tAbstract" > "$OUTPUT_TSV"

# Function to process a single XML file
process_file() {
    local pmid="$1"
    file="data/raw/article-data-${pmid}.xml"

    # Check if the file is valid XML
    if ! xmllint --noout "$file" 2>/dev/null; then
        echo "Invalid XML file: $file" >&2
        return 1
    fi

    # Extract PMID
    pmid=$(xmllint --xpath \
           "string(//PubmedArticleSet/PubmedArticle/MedlineCitation/PMID)" \
           "$file" 2>/dev/null || echo "N/A")

    # Extract Year
    year=$(xmllint --xpath \
           "string(//PubmedArticleSet/PubmedArticle/MedlineCitation/Article/Journal/JournalIssue/PubDate/Year)" \
           "$file" 2>/dev/null || echo "N/A")

    # Extract ArticleTitle
    title=$(xmllint --xpath \
            "string(//PubmedArticleSet/PubmedArticle/MedlineCitation/Article/ArticleTitle)" \
            "$file" 2>/dev/null |  sed -E 's/<[^>]+>//g' || echo "N/A")

    # Extract AbstractText including text within tags
    abstract=$(xmllint --xpath \
               "//PubmedArticleSet/PubmedArticle/MedlineCitation/Article/Abstract/AbstractText" \
               "$file" 2>/dev/null | sed -E 's/<[^>]+>//g' | tr '\n' ' ' || echo "N/A")

    # Print the result as tab-separated values
    echo -e "${pmid}\t${year}\t${title}\t${abstract}"
}

# Loop through all XML files in the directory
# and append data to the output file
for pmid in ${pmids[@]}; do
    process_file "$pmid" >> "$OUTPUT_TSV" &
done

# Wait until all files have been processed
wait
n_articles=`wc -l $OUTPUT_TSV`

echo "Extraction complete."
echo "Data saved to $OUTPUT_TSV"