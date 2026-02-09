library(DBI)
library(RSQLite)
library(dplyr)
library(tidyr)

# 1) Connect to (or create) a local SQLite database file in your project folder
con <- dbConnect(RSQLite::SQLite(), "movie_ratings.sqlite")

# 2) Run your SQL script to create + populate the tables
sql_text <- paste(readLines("SQL/create_and_populate.sql"), collapse = "\n")
dbExecute(con, sql_text)

# 3) Load the data from SQL into R (joined dataset)
ratings_df <- dbGetQuery(con, "
  SELECT
    u.user_id,
    u.name AS user_name,
    m.movie_id,
    m.title,
    m.release_year,
    r.rating
  FROM ratings r
  JOIN users u  ON r.user_id = u.user_id
  JOIN movies m ON r.movie_id = m.movie_id
  ORDER BY u.user_id, m.movie_id;
")

print(ratings_df)

# 4) Missing data check (required)
missing_count <- sum(is.na(ratings_df$rating))
cat('Missing ratings (NA) count:', missing_count, '\n')

# Strategy 1: summarize while ignoring missing values
movie_summary <- ratings_df %>%
  group_by(title) %>%
  summarize(
    n_ratings = sum(!is.na(rating)),
    mean_rating = mean(rating, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_rating), desc(n_ratings))

print(movie_summary)

# Strategy 2 (demonstration): movie-mean imputation for a full user-item matrix
movie_means <- ratings_df %>%
  group_by(title) %>%
  summarize(movie_mean = mean(rating, na.rm = TRUE), .groups = "drop")

ratings_imputed <- ratings_df %>%
  left_join(movie_means, by = "title") %>%
  mutate(rating_imputed = ifelse(is.na(rating), movie_mean, rating))

rating_matrix <- ratings_imputed %>%
  select(user_name, title, rating_imputed) %>%
  pivot_wider(names_from = title, values_from = rating_imputed)

print(rating_matrix)

dbDisconnect(con)
