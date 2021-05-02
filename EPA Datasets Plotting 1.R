# Loading libraries
library(tidyverse)
library(here)
library(lubridate)
library(latex2exp)
library(sf)
library(maps)
library(rgeos)
library(rnaturalearth)
library(plotly)

############################# Global #################################

# Loading the wrangled data sets
load(here("data", "wrangled", "Annual_Data_PM2-5_Sites.rda"))
load(here("data", "wrangled", "Daily_Data_10years.rda"))

# Plotting the Annual Average Data on PM 2.5 on USA map

USmap = ne_countries(country = "united states of america",
                     scale = "medium",
                     returnclass = "sf")
USstates = spData::us_states

UScounties = sf::st_as_sf(
    maps::map("county", 
              plot = FALSE,
              fill = TRUE))
AnnData = AnnData %>%
            mutate(xloc = - 110, 
                   yloc = 27)
######################### User Input #############################

Sel_Year = 2015

Sel_State = "California"

########################## Reactive ##############################
ggplotly(
    ggplot(data = USmap) +
    geom_sf(data = USstates, 
            fill = NA, 
            color = "grey",
            alpha = 0.5) +
    coord_sf(xlim = c(-125, -66), ylim = c(24.5, 50), 
             expand = FALSE) +
    ggthemes::theme_map() + 
    labs(title = "Air Quality Monitoring Sites: Mean Annual PM 2.5 levels") +
    geom_point(data = AnnData[AnnData$Year == Sel_Year, ],
               mapping = aes(x = Longitude, 
                             y = Latitude,
                             col = MeanPM2.5,
                             text = `County Name`,
                             text1 = `City Name`),
               size = 0.7,
               alpha = 0.5,
               pch = 20) +
    geom_text(data = AnnData[AnnData$Year == Sel_Year, ], 
              aes(y = yloc, x = xloc, 
                  label = as.character(Year)), 
              check_overlap = TRUE, 
              size = 5, 
              fontface="bold") + 
    scale_color_gradientn(colours = topo.colors(7), 
                          na.value = "transparent",
                          breaks = c(0, 5, 10, 15),
                          labels = c(0, 5, 10, 15),
                          limits = c(0, 20), 
                          name = "PM 2.5 (ug/m3)"),
    tooltip = c("text", "text1", "MeanPM2.5")
)


AnnData %>%
    group_by(`State Name`, Year) %>%
    summarize(MMPM2.5 = mean(MeanPM2.5)) %>%
    mutate(ColState = ifelse(`State Name` == Sel_State, 1, 0.2)) %>%
    mutate(ColState = as.factor(ColState)) %>%
    
    ggplot(aes(x = Year, y = MMPM2.5)) +
    geom_line(aes(col = ColState,
                  group = `State Name`,
                  alpha = ColState),
              lwd = 1) +
    scale_y_continuous(limits = c(4, 16)) +
    scale_color_manual(values = c("grey", "black"),
                       name = "States",
                       labels = c("Other States", Sel_State)) +
    theme_classic() +
    theme(legend.position = "bottom") +
    labs(y = "Mean PM 2.5 (ug/m3) levels in State",
         title = "State-wise Mean PM 2.5 level trends",
         subtitle = "(1995 - 2020)") +
    guides(alpha = FALSE)





