pacman::p_load(tidyverse)


# Exercise 1 ####

get_mode <- function(v) {
  v <- v %>% na.omit()
  uniq_v <- v %>% unique()
  return(uniq_v[which.max(tabulate(match(v, uniq_v)))])
}

# Exercise 2 ####
get_mode(study$bmi_3cat)


# Exercise 3 ####

study$emotions[study$emotions == 'netural'] <- 'neutral'

replace_w_emoticons <- function(x) {
  if (x == "happy") {
    ":)"
  } else if (x == "sad") {
    ":("
  } else {
    ":/"
  }
}

# vectorize function:
replace_w_emoticons_vectorized <- Vectorize(replace_w_emoticons)


# to change the emotions column in the study dataframe, either use the vectorized function, a solution from below

# 1
study <- study %>% 
  rowwise() %>% # otherwise the function will only evaluate the first argument
  mutate(emoticons2 = replace_with_emoticons(emotions))

# 2
study <- study %>% 
  mutate(emoticons = map_chr(emotions, replace_with_emoticons))

# 3
study$emoticons <- study$emotions %>% replace_w_emoticons_vectorized()


# Exercise 4 ####
mean_sd <- function(x) {
  list('mean' = mean(x, na.rm=T), 'sd' = sd(x, na.rm=T))
}

# Exercise 5 ####
map_df(study %>% select(where(is.numeric)), mean_sd) %>% 
  cbind(
    'col' = study %>% 
      select(where(is.numeric)) %>% 
      colnames()
  )
# or just use any other map

# Exercise 6 ####
study %>% select(where(is.character)) %>% map_df(tolower)



# Debugging solutions ####

# solutions are now also commented in line

geod_dist <- function(lat1, lon1, lat2, lon2, earth.radius = 6371) {
  # from degrees to radians
  deg2rad <- function(deg) return(deg*pi/180)
  lon1 <- deg2rad(lon1)
  lat1 <- deg2rad(lat1)
  lon2 <- deg2rad(lon2) # replace with lon2
  lat2 <- deg2rad(lat2)
  # calculation
  delta.long <- (lon2 - lon1)
  delta.lat <- (lat2 - lat1)
  a <- sin(delta.lat/2)^2 + cos(lat1) * cos(lat2) * sin(delta.long/2)^2 # replace sing with sin
  c <- 2 * asin(min(1,sqrt(a)))
  d = earth.radius * c # replace earth_radius with earth.radius
  return(d)
}

geod_dist(lat1 = 49.5, lon1 = 8.4, lat2 = 52.5, lon2 = 13.4)


# Take home debugging exercise ####

library(tidyverse)
library(legislatoR) 

political_df <- left_join(x = get_political(legislature = 'deu') %>% filter(session == 18), 
            y = get_core(legislature = "deu"), by = "pageid")


traffic_df <- get_traffic(legislature = "deu") %>% 
  filter(date >= "2013-10-22" & date <= "2017-10-24") %>% 
  group_by(pageid) %>% 
  summarize(traffic_mean = mean(traffic, na.rm = TRUE),
            traffic_max = max(traffic, na.rm = TRUE))

sessions_served_df <- get_political(legislature = "deu") %>% 
  group_by(pageid) %>% 
  dplyr::summarize(sessions_served = n())


get_age <- function(birth, date_at) {
  date_at_fmt <- date_at
  birth_fmt <- birth
  diff <- difftime(lubridate::ymd(date_at_fmt), lubridate::ymd(birth_fmt))
  diff_years <- lubridate::time_length(diff, "years")
  diff_years
}
legislator_df$age_in_years <- round(get_age(legislator_df$birth, "2017-10-24"), 0)

# plot top 10 pageviews
legislator_df <- arrange(legislator_df, desc(traffic_mean))
legislator_df$rank <- 1:nrow(legislator_df)
legislator_df_table <- legislator_df %>% dplyr::select(rank, name, traffic_mean, traffic_max)
colnames(legislator_df_table) <- c("Rank", "Representative", "Mean", "Maximum")
legislator_df_table <- head(legislator_df_table, 10)


ggplot(legislator_df_table, aes(y = Mean, x = -Rank)) + 
  xlab("Rank") + ylab("Avg. daily page views") + 
  labs(title = "Top 10 representatives by average daily page views") + 
  geom_col(stats = "identity") + 
  scale_x_continuous(breaks = -nrow(legislator_df_table):-1, labels = rev(1:nrow(legislator_df_table))) +
  geom_text(aes(y = 10, label = Representative), hjust = 0, color = "white", size = 2) + 
  coord_flip() + 
  theme_minimal()


# run model of page views as a function of sessions served, party, sex, and age in years
legislator_df$traffic_log <- log(legislator_df$traffic_mean)

covars <- c("sessions_served", "party", "sex", "age_in_years")
fmla <- paste("traffic_log", paste(covars, collapse = " + "), sep = " ~ ") 
summary(log_traffic_model <- lm(fmla, legislator_df))

# plot table
sjPlot::tab_model(log_traffic_model)
