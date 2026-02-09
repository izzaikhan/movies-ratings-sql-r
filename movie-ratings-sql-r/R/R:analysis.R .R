library(DBI)
library(RSQLite)
library(dplyr)
library(tidyr)

# Connect/create SQLite DB
con <- dbConnect(RSQLite::SQLite(), "movie_ratings.sqlite")

# Read SQL file directly
sql_text <- paste(readLines("SQL/create_and_populate.sql"), collapse = "\n")

# Execute SQL
dbExecute(con, sql_text)

# Pull joined data
ratings_df <- dbGetQuery(con, "
SELECT
    u.user_id,
    u.name AS user_name,
    m.movie_id,
    m.title,
    m.release_year,
    r.rating
FROM ratings r
JOIN users u ON r.user_id = u.user_id
JOIN movies m ON r.movie_id = m.movie_id
ORDER BY u.user_id, m.movie_id;
")

print(ratings_df)

# Count missing ratings
cat('Missing ratings:', sum(is.na(ratings_df$rating)), '\n')

# Summary ignoring missing
movie_summary <- ratings_df %>%
  group_by(title) %>%
  summarize(
    n_ratings = sum(!is.na(rating)),
    mean_rating = mean(rating, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_rating), desc(n_ratings))

print(movie_summary)

dbDisconnect(con)