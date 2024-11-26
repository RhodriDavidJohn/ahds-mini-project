# script to clean the extracted article data

# cleaning envolves:
## removing any XML tags that are in the title
## removing articles without titles
## imputing missing year values (last value carried forward)
## stripping the title and abstract text ready for analysis


# load packages
library(janitor)
library(tidyverse)
library(tidytext)
library(dplyr)


args <- commandArgs(trailingOnly = TRUE)

article_characteristic <- args[1]

if (article_characteristic == "title") {
  col <- "article_title"
} else if (article_characteristic == "abstract") {
  col <- "abstract"
}


print(paste0("Pre-processing ", article_characteristic, " data"))

print("Loading the extracted data")
# load the data
data_dir <- "data/clean/"

data <- read.delim(file = paste0(data_dir, "extracted_data.tsv"),
                   sep = "\t", na = c("[Not Available].", ""),
                   comment.char = '"')

# convert data to tibble and
# make the column names snake case
# and make the years and pmids numeric instead of string
# and drop any rows with missing pmid or year
data <- as_tibble(data) %>%
  clean_names() %>%
  mutate(pmid = suppressWarnings(as.numeric(pmid)),
         year = suppressWarnings(as.numeric(year))) %>%
  drop_na(pmid, year)


article_dist <- data %>%
  group_by(year) %>%
  summarise(n_articles = n())

print("Distribution of articles by year:")
print(article_dist)

# since there's onle 4 articles in 2025
# remove those areticles
data <- data %>%
  filter(year != 2025)

# split the data into the article characteristic
data <- data %>% select("pmid", "year", {{col}})


print("Cleaning the data")
# clean the dataset by
# dropping any rows with missing text data
# removing XML tags and non-alphabetical characters from text
data_clean <- data %>%
  drop_na(col) %>%
  mutate(!!sym(col) := str_remove_all(!!sym(col), "<[^>]+>")) %>% # nolint
  mutate(!!sym(col) := str_remove_all(!!sym(col), "[^a-zA-Z ]"))

print(paste0("The ", article_characteristic, " data includes ",
             nrow(data_clean), " articles from ", min(data_clean$year),
             " to ", max(data_clean$year)))


print("Converting the data to a tidy format")
# tidy the data by:
# giving each row a single word (unnesting tokens)
# removing stopwords
# stemming words
tidied_data <- data_clean %>%
  unnest_tokens(input = {{col}}, output = "word") %>%
  anti_join(get_stopwords(), by = "word") %>%  # nolint
  filter(! word %in% c("covid", "long"))  # nolint


print(paste0("Saving the cleaned and tidied data to ", data_dir))
# save the cleaned data
write_tsv(tidied_data, paste0(data_dir, article_characteristic, "_data.tsv"))
