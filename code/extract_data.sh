#!/bin/bash

batch=$1

# Directory containing XML files
INPUT_DATA="data/raw/article-data-${batch}*.xml"

# Output TSV file
OUTPUT_TSV="data/clean/${batch}_extracted_data.tsv"

# Create or clear the output file
echo -e "PMID\tYear\tArticleTitle\tAbstract" > "$OUTPUT_TSV"

# Function to process a single XML file
process_file() {
    local file="$1"

    # Check if the file is valid XML
    if ! xmllint --noout "$file" 2>/dev/null; then
        echo "Invalid XML file: $file" >&2
        return 1
    fi

    # Extract PMID
    pmid=$(xmllint --xpath "string(//PubmedArticleSet/PubmedArticle/MedlineCitation/PMID)" "$file" 2>/dev/null || echo "N/A")

    # Extract Year
    year=$(xmllint --xpath "string(//PubmedArticleSet/PubmedArticle/MedlineCitation/Article/Journal/JournalIssue/PubDate/Year)" "$file" 2>/dev/null || echo "N/A")

    # Extract ArticleTitle
    title=$(xmllint --xpath "string(//PubmedArticleSet/PubmedArticle/MedlineCitation/Article/ArticleTitle)" "$file" 2>/dev/null || echo "N/A")

    # Extract AbstractText including text within tags
    abstract=$(xmllint --xpath "//PubmedArticleSet/PubmedArticle/MedlineCitation/Article/Abstract/AbstractText" "$file" 2>/dev/null | \
               sed -E 's/<[^>]+>//g' | tr '\n' ' ' || echo "N/A")

    # Print the result as tab-separated values
    echo -e "${pmid}\t${year}\t${title}\t${abstract}"
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