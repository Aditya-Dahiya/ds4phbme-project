library(tidyverse)
library(here)
library(aqsr)

# Examining the List of Sites and List of Monitors from EPA Website
# Credits: 1. https://aqs.epa.gov/aqsweb/airdata/aqs_sites.zip
#          2. https://aqs.epa.gov/aqsweb/airdata/aqs_monitors.zip

SitesList = read_csv(file = here("data", "raw", "EPA Data", "EPA_List_of_AQS_Sites.csv"))
MonitorsList = read_csv(file = here("data", "raw", "EPA Data", "EPA_List_of_AQS_Monitors.csv"))

# creating the Wrangled data sets for use
SitesList %<>% select(c("State Code", "County Code", "Site Number", "Latitude", 
                         "Longitude", "Location Setting", "Address", "Zip Code",
                         "State Name", "County Name", "City Name"))
MonitorsList %<>% select(c("State Code", "County Code", "Site Number",
                           "Latitude", "Longitude",  "Local Site Name", "Address",
                           "State Name", "County Name", "City Name"))
save(SitesList, file = here("data", "wrangled", "EPA_Sites_List.rda"))
save(MonitorsList, file = here("data", "wrangled", "EPA_Monitors_List.rda"))
rm(SitesList, MonitorsList)

# Loading the correct data sets
load(file = here("data", "wrangled", "EPA_Sites_List.rda"))
load(file = here("data", "wrangled", "EPA_Monitors_List.rda"))

# Examining Annual Summary Data from EPA's website (pre-fabricated)
# Credits: 1. https://aqs.epa.gov/aqsweb/airdata/download_files.html#Annual
#          2. https://aqs.epa.gov/aqsweb/airdata/download_files.html#Annual

# Creating a vector of Years for which data is to be used and combined
Years = seq(from = 1995, to = 2020, by = 1)
AnnData = data.frame()
for (yr in Years){
    AnnData = bind_rows(AnnData, 
                                 read_csv(here("data", "raw", "EPA Data", 
                                 paste0("annual_conc_by_monitor_", yr, ".csv")
                                 )
                            ) %>%
    filter(`Parameter Code` == "88101") %>%
    filter(`Metric Used` == "Daily Mean") %>%
    filter(`Pollutant Standard` == "PM25 24-hour 2012") %>%
    select(c("State Code", "County Code", "Site Num",
             "Parameter Code", "Latitude", "Longitude",
             "Arithmetic Mean", "Arithmetic Standard Dev",
             "State Name", "County Name", "City Name")) %>%
    rename(MeanPM2.5 = `Arithmetic Mean`) %>%
    rename(sdPM2.5 = `Arithmetic Standard Dev`) %>%
    mutate(Year = yr) %>%
    mutate(MeanPM2.5 = round(MeanPM2.5, 2)) %>%
    mutate(sdPM2.5 = round(sdPM2.5, 2))
    )
}

save(AnnData, file = here("data", "wrangled", "Annual_Data_PM2-5_Sites.rda"))

##########################################################################
###########       Daily Data on PM 2.5                       #############
##########################################################################

# Trial with 2015 dataset
Daily2015 = read_csv(file = here("data", "raw", "EPA Data", "daily_88101_2015.csv"))

Daily2015 = Daily2015 %>%
    select(c("State Code", "County Code", "Site Num",
             "Date Local", "Arithmetic Mean", "AQI", "State Name",
             "County Name", "City Name")) %>%
    rename(PM2.5 = `Arithmetic Mean`) %>%
    rename(Date = `Date Local`)

# Creating a data set for all years PM2.5 concentration
Years = 2010:2020
DlyData = data.frame()
# test = read_csv(here("data", "raw", "EPA Data", "daily_88101_2015.csv"))

for (yrs in Years){
    DlyData = bind_rows(
                DlyData,
                read_csv(file = here("data", "raw", "EPA Data", 
                                     paste0("daily_88101_", yrs, ".csv")
                                     )
                         ) %>%
                select(c("State Code", "County Code", "Site Num",
                 "Date Local", "Arithmetic Mean", "AQI", "State Name",
                 "County Name", "City Name", "Latitude", "Longitude")) %>%
                rename(PM2.5 = `Arithmetic Mean`) %>%
                rename(Date = `Date Local`) 
    )
}

save(DlyData, file = here("data", "wrangled", "Daily_Data_10years.rda"))
