#!/bin/bash

# Directory containing XML files
INPUT_DATA="data/raw/article-data-*.xml"

# Output TSV file
OUTPUT_TSV="data/clean/extracted_data.tsv"

# Create or clear the output file
echo -e "PMID\tYear\tArticleTitle\tAbstract" > "$OUTPUT_TSV"

# Function to process a single XML file
process_file() {
    local file="$1"
    
    # Extract the PMID, Year, ArticleTitle, and concatenate AbstractText values with space
    sed '/<!DOCTYPE/d' "$file" | xmlstarlet sel -t -m "//PubmedArticleSet/PubmedArticle/MedlineCitation" \
        -v "PMID" -o "\t" \
        -v "Article/Journal/JournalIssue/PubDate/Year" -o "\t" \
        -v "Article/ArticleTitle" -o "\t" \
        -m "Article/Abstract/AbstractText" -v "." -o " " -b -n | sed $'s/\\\\t/\t/g'
}

# Loop through all XML files in the directory
# and append data to the output file
for file in $INPUT_DATA; do
    process_file "$file" >> "$OUTPUT_TSV" &
done

# Wait until all files have been processed
wait

echo "Extraction complete."
echo "Data saved to $OUTPUT_TSV"
