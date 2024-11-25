#!/bin/bash

# Directory containing XML files
INPUT_DATA="data/raw/article-data-*.xml"

# Output TSV file
OUTPUT_TSV="data/clean/extracted_data.tsv"



# Function to process a single XML file
process_file() {
    local file="$1"
    xmllint --format "$file" | awk '
    BEGIN { FS = "[<>]"; OFS = "\t" }
    
    # Function to strip attributes and get tag value
    function clean_tag(tag) {
        gsub(/ [^>]+/, "", tag)  # Remove attributes from tag
        return tag
    }
    
    {
        # Track whether we are inside the <PubDate> tag
        if (clean_tag($2) == "PubDate") {
            in_pub_date = 1
        }
        if (clean_tag($2) == "/PubDate") {
            in_pub_date = 0
        }

        # Track whether we are inside the <KeywordList> tag
        if (clean_tag($2) == "KeywordList") {
            in_keyword = 1
        }
        if (clean_tag($2) == "/KeywordList") {
            in_keyword = 0
        }

        # Capture PMID (clean attributes from the tag name)
        if (clean_tag($2) == "PMID") {
            pmid = $3
        }

        # Capture Year within the <PubDate> block
        if (clean_tag($2) == "Year" && in_pub_date == 1) {
            year = $3
        }

        # Capture ArticleTitle
        if (clean_tag($2) == "ArticleTitle") {
            title = $3
        }

        # Capture and concatenate AbstractText
        if (clean_tag($2) == "AbstractText") {
            abstract = (abstract == "" ? $3 : abstract " " $3)
        }

        # Output the data at the end of a PubmedArticle
        if (clean_tag($2) == "/PubmedArticle") {
            print pmid, year, title, abstract, keywords
            pmid = ""; year = ""; title = ""; abstract = ""
        }
    }'
}


echo
echo "Extracting the PMID, Publish Year, Article Title and Article Abstract from each article..."

# Create or clear the output file
echo -e "PMID\tYear\tArticleTitle\tAbstract" > "$OUTPUT_TSV"

# Loop through all XML files in the directory
# and append dat to the output file
# the & simble parellalizes the process
for file in $INPUT_DATA; do
    process_file "$file" >> "$OUTPUT_TSV" &
done

# wait untill all files have been processed
wait

echo "Extraction complete."
echo "Data saved to $OUTPUT_TSV"
echo
