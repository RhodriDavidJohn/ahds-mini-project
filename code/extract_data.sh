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
        # Track whether we are inside the <ArticleDate> tag
        if (clean_tag($2) == "ArticleDate") {
            in_article_date = 1
        }
        if (clean_tag($2) == "/ArticleDate") {
            in_article_date = 0
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

        # Capture Year within the <ArticleDate> block
        if (clean_tag($2) == "Year" && in_article_date == 1) {
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

        # Capture Keyword within the <KeywordList> block
        if (clean_tag($2) == "Keyword" && in_keyword == 1) {
            keywords = $3
        }

        # Output the data at the end of a PubmedArticle
        if (clean_tag($2) == "/PubmedArticle") {
            print pmid, year, title, abstract, keywords
            pmid = ""; year = ""; title = ""; abstract = ""; keywords = ""
        }
    }'
}




echo "Extracting the PMID, Article Year, Article Title, and Article Abstract from each article..."

# Create or clear the output file
echo -e "PMID\tYear\tArticleTitle\tAbstract\tKeywords" > "$OUTPUT_TSV"

source code/progress_bar.sh

n_articles=`ls $INPUT_DATA | wc -l`
counter=1

# Loop through all XML files in the directory
for file in $INPUT_DATA; do
    if [[ -f "$file" ]]; then
        process_file "$file" >> "$OUTPUT_TSV"
        show_progress $counter $n_articles
	counter=$((counter+1))
    fi
done

echo "Extraction complete. Data saved to $OUTPUT_TSV"

