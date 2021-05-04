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
             "Arithmetic Mean", "1st Max Value",
             "State Name", "County Name", "City Name")) %>%
    rename(MeanPM2.5 = `Arithmetic Mean`) %>%
    rename(MaxPM2.5 = `1st Max Value`) %>%
    mutate(Year = yr) %>%
    mutate(MeanPM2.5 = round(MeanPM2.5, 2)) %>%
    mutate(MaxPM2.5 = round(MaxPM2.5, 2))
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



######################## Post-App Creation Phase ##########################
library(tidyverse)
library(here)
library(magrittr)

# The huge Data Set DlyData is not picked up by Shiny App.
# So, we create smaller data sets for each state
# We can call these data sets for use during Shiny App separately
load(here("data", "wrangled", "Daily_Data_10years.rda"))
List_States = unique(DlyData$`State Name`)[1:50]

for (i in 1:length(List_States)){
    StateDlyData = DlyData %>%
        filter(`State Name` == List_States[i]) %>%
        mutate(Month = lubridate::month(Date, label = TRUE)) %>%
        mutate(Year = lubridate::year(Date))
    
    saveRDS(StateDlyData, file = here("data", "wrangled", 
                         paste0("Statewise_DailyData_", List_States[i], ".rds" )
                         )
             )
}

# Creating a master data set for State, County and City Name
# We will keep its name as ListDlyData

ListDlyData = DlyData %>%
                select(`State Name`, `County Name`, `City Name`) %>%
                distinct(`State Name`, `County Name`, `City Name`)

save(ListDlyData, file = here("data", 
                              "wrangled", 
                              "List_of_States_Counties_Cities.rda"))



