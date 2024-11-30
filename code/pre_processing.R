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
} else if (article_characteristic == "abstract") {
  col <- "abstract"
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


print("Cleaning the data")
# clean the dataset by
# dropping any rows with missing text data
# removing XML tags and non-alphabetical characters from text
# XML tags should have been removed during extraction but this
# is just to make sure
data_clean <- data %>%
  drop_na(col) %>%
  mutate(!!sym(col) := str_remove_all(!!sym(col), "<[^>]+>")) %>% # nolint
  mutate(!!sym(col) := str_remove_all(!!sym(col), "[^a-zA-Z ]"))

print(paste0("The ", article_characteristic, " data includes ",
             nrow(data_clean), " articles from ", min(data_clean$year),
             " to ", max(data_clean$year)))


# establish common words that do not
# add much value to the analysis
year_words <- data_clean %>%
  unnest_tokens(input = {{col}}, output = "word") %>%
  anti_join(get_stopwords(), by = "word") %>% # nolint
  count(year, word, sort = TRUE)

total_words <- year_words %>%
  group_by(year) %>%
  summarize(total = sum(n))

year_words <- left_join(year_words, total_words)

# calculate tf-idf
year_tf_idf <- year_words %>%
  bind_tf_idf(word, year, n)

common_words <- year_tf_idf %>%
  filter(idf == 0) %>%
  group_by(year, word) %>%
  summarise(n = sum(n)) %>%
  slice_max(n, n = 20) %>%
  ungroup()

common_words_plot <- common_words %>%
  ggplot(aes(n, fct_reorder(word, n), fill = year)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~year, ncol = 2, scales = "free") +
  labs(
    title = paste0(
      "Most common words in article ", article_characteristic, " by year"
    ),
    x = "Word count", y = NULL
  )

# save the plot
filename <- paste0(
  output_dir, "article_", article_characteristic, "_common_terms.png"
)
suppressMessages(
  ggsave(filename,
         plot = common_words_plot, bg = "white")
)


print("Converting the data to a tidy format")
# tidy the data by:
# giving each row a single word (unnesting tokens)
# removing regular english stopwords
# and subject specific stopwords
# based off the data
subject_stopwords <- common_words %>%
  distinct(word)

tidied_data <- data_clean %>%
  unnest_tokens(input = {{col}}, output = "word") %>%
  anti_join(get_stopwords(), by = "word") %>%  # nolint
  anti_join(subject_stopwords, by = "word")  # nolint


print(paste0("Saving the cleaned and tidied data to ", data_dir))
# save the cleaned data
write_tsv(tidied_data, paste0(data_dir, article_characteristic, "_data.tsv"))
