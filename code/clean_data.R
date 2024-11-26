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

# split the data into the three categories
# title, abstract, mesh
title_data <- data %>% select("pmid", "year", "article_title")
abstract_data <- data %>% select("pmid", "year", "abstract")


print("Cleaning the data")
# clean the 3 datasets by
# dropping any rows with missing text data
# removing XML tags and non-alphabetical characters from text

# cleaning title data
title_data_clean <- title_data %>%
  drop_na(article_title) %>%
  mutate(article_title = str_remove_all(article_title, "<[^>]+>")) %>% # nolint
  mutate(article_title = str_remove_all(article_title, "[^a-zA-Z ]"))

# cleaning abstract data
abstract_data_clean <- abstract_data %>%
  drop_na(abstract) %>%
  mutate(abstract = str_remove_all(abstract, "<[^>]+>")) %>% # nolint
  mutate(abstract = str_remove_all(abstract, "[^a-zA-Z ]"))

print(paste0("The title data includes ", nrow(title_data_clean),
             " articles from ", min(title_data_clean$year),
             " to ", max(title_data_clean$year)))
print(paste0("The abstract data includes ", nrow(abstract_data_clean),
             " articles from ", min(abstract_data_clean$year),
             " to ", max(abstract_data_clean$year)))


print("Converting the data to a tidy format")
# tidy the data by:
# giving each row a single word (unnesting tokens)
# removing stopwords
# stemming words
tidy_data <- function(clean_data, column) {
  tidied_data <- clean_data %>%
    unnest_tokens(input = {{column}}, output = "word") %>%
    anti_join(get_stopwords(), by = "word") %>%  # nolint
    filter(! word %in% c("covid", "long"))  # nolint

  return(tidied_data)
}

title_data_tidy <- tidy_data(title_data_clean, "article_title")
abstract_data_tidy <- tidy_data(abstract_data_clean, "abstract")


print(paste0("Saving the cleaned and tidied data to ", data_dir))
# save the cleaned data
write_tsv(title_data_tidy, paste0(data_dir, "title_data.tsv"))
write_tsv(abstract_data_tidy, paste0(data_dir, "abstract_data.tsv"))
