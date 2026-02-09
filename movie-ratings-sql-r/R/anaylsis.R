library(DBI)
library(RSQLite)
library(dplyr)
library(tidyr)

# Create SQLite database
con <- dbConnect(SQLite(), "movie_ratings.sqlite")

# Create tables directly in R (bypass SQL file)
users <- data.frame(
  user_id = 1:4,
  name = c("Alice", "Bob", "Carol", "Dave")
)

movies <- data.frame(
  movie_id = 1:3,
  title = c("Inception", "Titanic", "Avatar"),
  release_year = c(2010, 1997, 2009)
)

ratings <- data.frame(
  user_id = c(1, 1, 2, 3, 4),
  movie_id = c(1, 2, 1, 3, 2),
  rating = c(5, 4, 4, 5, NA)
)

# Write tables to database
dbWriteTable(con, "users", users, overwrite = TRUE)
dbWriteTable(con, "movies", movies, overwrite = TRUE)
dbWriteTable(con, "ratings", ratings, overwrite = TRUE)

# Load joined data
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
")

print(ratings_df)

# Count missing
cat("Missing ratings:", sum(is.na(ratings_df$rating)), "\n")

# Summary
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
cat("DONE\n")
