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

############### R Scripts for Creating Animations ###################

# Loading the wrangled data sets
load(here("data", "wrangled", "Annual_Data_PM2-5_Sites.rda"))

# Generating data.frames for plotting the Annual Average Data on PM 2.5 on USA map

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

library(gganimate)
g = ggplot(data = USmap) +
    geom_sf(data = USstates, 
            fill = NA, 
            color = "grey",
            alpha = 0.5) +
    coord_sf(xlim = c(-125, -66), ylim = c(24.5, 50), 
             expand = FALSE) +
    ggthemes::theme_map() + 
    labs(title = "Air Quality Monitoring Sites: Mean Annual PM 2.5 levels") +
    geom_point(data = AnnData,
               mapping = aes(x = Longitude, 
                             y = Latitude,
                             col = MeanPM2.5),
               size = 2.5,
               alpha = 0.3,
               pch = 20) +
    geom_text(data = AnnData, 
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
                          name = TeX("PM_{2.5} \ (ug/m^{3})")) +
    theme(legend.position = "right")

ganim = g + transition_states(states = Year,
                              transition_length = 0.5,
                              state_length = 40,
                              wrap = TRUE) +
    enter_recolor() +
    exit_recolor()

animate(ganim,
        start_pause = 0,
        end_pause = 4)

anim_save("gganim1995-2020.gif")

###################### Second Animation ########################

AnnData1 = AnnData %>%
    group_by(Year) %>%
    mutate(MMPM2.5 = mean(MeanPM2.5)) %>%
    ungroup()


g1 = ggplot(AnnData1) +
    geom_jitter(mapping = aes(x = Year, 
                              y = MeanPM2.5,
                              col = MeanPM2.5),
                alpha = 0.3,
                size = 0.1) +
    geom_line(mapping = aes(x = Year, 
                              y = MMPM2.5),
                col = "darkgrey",
                lwd = 1.5) + 
    scale_y_continuous(limits = c(quantile(AnnData$MeanPM2.5, 0.01),
                                  quantile(AnnData$MeanPM2.5, 0.99))) +
    scale_color_gradientn(colours = topo.colors(7), 
                          na.value = "transparent",
                          breaks = c(0, 5, 10, 15),
                          labels = c(0, 5, 10, 15),
                          limits = c(0, 20), 
                          name = "PM 2.5 (ug/m3)")+
    theme_classic() +
    labs(x = "Year",
         y = "PM 2.5 (ug/m3)",
         title = "PM 2.5 levels trend over the Years",
         subtitle = "(with overlaid mean curve)") +
    theme(legend.position = "none")

ggsave("g1-lineplot.png",
       device = "png")

g1anim = g1 + transition_reveal(Year) +
    shadow_mark() +
    enter_fade()

animate(g1anim)

anim_save("g1lineplot.gif")


