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
library(parallel)
library(dplyr)


args <- commandArgs(trailingOnly = TRUE)

article_characteristic <- args[1]
batches_string <- args[2]

batches <- strsplit(batches_string, ",")[[1]]

if (article_characteristic == "title") {
  col <- "article_title"
  top_n_terms <- 20
} else if (article_characteristic == "abstract") {
  col <- "abstract"
  top_n_terms <- 50
} else {
  throw(
    "Article characteristic ", article_characteristic, "does not exist. ",
    "Article characteristic must be either 'title' or 'abstract'"
  )
}

print(paste0("Pre-processing ", article_characteristic, " data"))

print("Loading the extracted data")
# load the data
data_dir <- "data/clean/"
output_dir <- "data/analysis/"

# ensure the data can be read properly
# by including quote argument
load_data <- function(batch) {
  batch_data <- read.delim(
    file = paste0(data_dir, batch, "_extracted_data.tsv"),
    sep = "\t",
    na = c("[Not Available].", ""),
    quote = ""
  )
  return(batch_data)
}
# load all the extracted data
data <- mclapply(batches, load_data, mc.cores = length(batches))
# join them into one dataframe
data <- do.call(rbind, data)


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
  filter(!(year %in% c(2020, 2025)))

# split the data into the article characteristic
data <- data %>% select("pmid", "year", {{col}})
colnames(data) <- c("pmid", "year", "text")

print("Cleaning the data")
# clean the dataset by
# dropping any rows with missing text data
# removing XML tags and non-alphabetical characters from text
# XML tags should have been removed during extraction but this
# is just to make sure
data_clean <- data %>%
  drop_na(text) %>%
  mutate(text = str_remove_all(text, "<[^>]+>")) %>% # nolint
  mutate(text = str_remove_all(text, "[^a-zA-Z ]"))

print(paste0("The ", article_characteristic, " data includes ",
             nrow(data_clean), " articles from ", min(data_clean$year),
             " to ", max(data_clean$year)))


# establish common subject specific words that do not
# add much value to the analysis
tfidf_stopwords <- data_clean %>%
  unnest_tokens(input = "text", output = "word") %>%
  anti_join(get_stopwords(), by = "word") %>% # remove generic english stopwords
  count(year, word, sort = TRUE) %>%
  bind_tf_idf(word, year, n) %>%
  filter(tf_idf == 0) %>%
  group_by(year) %>%
  slice_max(n, n = top_n_terms)

stopword_candidates <- tfidf_stopwords %>%
  group_by(word) %>%
  summarize(year_count = n_distinct(year)) %>%
  arrange(desc(year_count))  # Sort by year_count for review

num_years <- length(unique(data$year))  # Total number of years in the dataset

# Filter words appearing in >50% of years
subject_specific_stopwords <- stopword_candidates %>%
  filter(year_count > num_years * 0.5)

# save the subject specific stopwords as a tsv file
write_tsv(
  subject_specific_stopwords,
  paste0(
    data_dir,
    "article_", article_characteristic, "_subject_specific_stopwords.tsv"
  )
)

print("Converting the data to a tidy format")
# tidy the data by:
# giving each row a single word (unnesting tokens)
# removing regular english stopwords
# and subject specific stopwords
# based off the data

tidied_data <- data_clean %>%
  unnest_tokens(input = "text", output = "word") %>%
  anti_join(get_stopwords(), by = "word") %>%  # nolint
  anti_join(subject_specific_stopwords, by = "word")  # nolint


print(paste0("Saving the cleaned and tidied data to ", data_dir))
# save the cleaned data
write_tsv(tidied_data, paste0(data_dir, article_characteristic, "_data.tsv"))
