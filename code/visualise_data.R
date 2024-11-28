
options(warn = -1)

library(tidyverse)
library(tidytext)
library(topicmodels)
library(tm)
library(ggplot2)
library(dplyr)


args <- commandArgs(trailingOnly = TRUE)

article_characteristic <- args[1]
n_topics <- as.numeric(args[2])

data_dir <- "data/clean/"
output_dir <- "results/"


print(paste0("Loading tidy ", article_characteristic, " data"))
# Load your data (replace this with your actual data source)
articles_data <- read.delim(
  paste0(data_dir, article_characteristic, "_data.tsv"),
  sep = "\t"
)

# untockenise the data so we have the year each
# article was published in
untokenized_data <- articles_data %>%
  group_by(pmid, year) %>% # Group by article ID and year
  summarize(text = paste(word, collapse = " "), # Combine tokens
            .groups = "drop") %>%
  select(pmid, year) %>%
  mutate(pmid = as.numeric(pmid),
         year = as.numeric(year))


# Create a document-term matrix (DTM)
dtm <- articles_data %>%
  count(pmid, word) %>%
  cast_dtm(pmid, word, n)  # DTM: term frequency matrix

print(paste0("Training LDA model with ", n_topics, " topics"))
# Fit LDA model with n topics
lda_model <- LDA(dtm, k = n_topics, control = list(seed = 42))


print("Creating plot to interpret topics")
# get the top 5 terms for each topic
topics <- tidy(lda_model, matrix = "beta")

top_terms <- topics %>%
  group_by(topic) %>%
  slice_max(beta, n = 5) %>%
  ungroup() %>%
  arrange(topic, -beta)

topic_terms_plot <- top_terms %>%
  mutate(term = reorder_within(term, beta, topic)) %>%
  ggplot(aes(beta, term, fill = factor(topic))) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ topic, scales = "free") +
  scale_y_reordered()


# save the plot
filename <- paste0(
  output_dir, "article_", article_characteristic,
  "_", n_topics, "_topic_terms.png"
)
suppressMessages(
  ggsave(filename,
         plot = topic_terms_plot, bg = "white")
)

print(paste0("Topic interpretation visualisation saved to ", filename))



print("Assinging each article a topic based off the model")
# use the model to assign each article
# with the most probable topic it belongs to
post_topics <- posterior(lda_model, dtm)
pred_topics <- apply(post_topics$topics, 1, which.max)


# create a tibble for the predicted topics
# join the untokenised data to get the year for each article as well
pred_topics <- tibble(pmid = names(pred_topics),
                      topic = pred_topics) %>%
  mutate(pmid = as.numeric(pmid))

pred_topics <- pred_topics %>%
  left_join(untokenized_data, by = "pmid")


print("Creating data visualisation for topics over time")
# calculate the number of articles for each
# topic-year combination
topic_counts <- pred_topics %>%
  group_by(year, topic) %>%
  summarise(count = n(), .groups = "drop")

# calculate total number of articles per year
total_per_year <- pred_topics %>%
  group_by(year) %>%
  summarise(total = n(), .groups = "drop")

# join the total count with topic counts
plot_data <- topic_counts %>%
  left_join(total_per_year, by = "year") %>%
  mutate(proportion = count / total,
         topic = as.factor(topic))


# plot the trends using ggplot2
tot_plot <- plot_data %>%
  ggplot(aes(x = year, y = proportion,
             color = as.factor(topic), group = topic)) +
  geom_line(linewidth = 1) +
  labs(title = "Proportion of Topics Over Time",
       x = "Year", y = "Proportion of Articles",
       color = "Topic") +
  theme_minimal() +
  theme(plot.title = element_text(size = 18, face = "bold", hjust = 0.5),
        axis.title = element_text(size = 14, face = "bold"),
        axis.text = element_text(size = 12),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_text(size = 14, face = "bold"),
        legend.text = element_text(size = 12),
        legend.position.inside = c(.9, .95),
        legend.justification = c("right", "top"))

# save the plot
filename <- paste0(
  output_dir, "article_", article_characteristic,
  "_", n_topics, "_topics_over_time.png"
)
suppressMessages(
  ggsave(filename,
         plot = tot_plot, bg = "white")
)

print(paste0("Topics over time visualisation saved to ", filename))
