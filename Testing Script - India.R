# For data wrangling
library(tidyverse)
library(magrittr)
# For easy data loading
library(here)
# For viewing data missingness
library(naniar)

cityday = read.csv(here("data", "raw", "city_day.csv"))

library(lubridate)

cityday %<>%
    mutate(Date = parse_date(Date)) %>%
    mutate(Month = month(Date)) %>%
    mutate(Year = year(Date)) 

SelectCities = cityday %>%
    group_by(City) %>%
    summarize(MissingPM10 = sum(is.na(PM10)),
              MissingXylene = sum(is.na(Xylene)),
              MissingPM2.5 = sum(is.na(PM2.5)),
              n = n()
              ) %>%
    mutate(Missings = MissingPM10 + MissingXylene + MissingPM2.5) %>%
    arrange(desc(n)) %>%
    pull(City)
SelectCities = SelectCities[1:6]

cityday1 = cityday %>%
    filter(City %in% SelectCities) %>%
    filter(Date > "2019-01-01" & Date < "2020-01-01")

ggplot(data = cityday1, mapping = aes(x = Date)) +
    geom_line(aes(y = PM10, group = City, col = City), se = FALSE) +
#    geom_line(aes(y = PM2.5, group = City, col = City), lty = 3, se = FALSE) + 
    scale_x_date(date_breaks = "1 month") + 
    theme(axis.text.x = element_text(angle = 90),
          legend.position = "bottom")

