#!/bin/bash

batch=$1
pmids=$2

# Directory containing XML files
n_pmids=$(echo "$pmids" | wc -w)
echo "Number of articles to be processed: $n_pmids"

# Output TSV file
OUTPUT_TSV="data/clean/${batch}_extracted_data.tsv"

# Create or clear the output file
printf "PMID\tYear\tArticleTitle\tAbstract\n" > "$OUTPUT_TSV"

# Function to process a single XML file
process_file() {
    local pmid="$1"
    local file="data/raw/article-data-${pmid}.xml"

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
            "$file" 2>/dev/null | sed -E 's/<[^>]+>//g' | tr -d '\r\n' || echo "N/A")

    # Extract AbstractText including text within tags
    abstract=$(xmllint --xpath \
               "//PubmedArticleSet/PubmedArticle/MedlineCitation/Article/Abstract/AbstractText" \
               "$file" 2>/dev/null | sed -E 's/<[^>]+>//g' | tr -d '\r\n' || echo "N/A")

    # Print the result as tab-separated values, trimming whitespace
    printf "%s\t%s\t%s\t%s\n" \
           "$pmid" "$year" "$title" "$abstract"
}

# Loop through all PMIDs and process files in parallel
temp_dir=$(mktemp -d)
for pmid in ${pmids[@]}; do
    process_file "$pmid" > "$temp_dir/${pmid}.tsv" &
done

# Wait for all processes to complete
wait

# Combine temporary files into the final output
cat "$temp_dir"/*.tsv >> "$OUTPUT_TSV"
rm -r "$temp_dir"

# Ensure the file has consistent Unix-style line endings
dos2unix "$OUTPUT_TSV" 2>/dev/null || true

n_articles=$(wc -l < "$OUTPUT_TSV")
echo "Extraction complete. $((n_articles-1)) lines saved to $OUTPUT_TSV"
