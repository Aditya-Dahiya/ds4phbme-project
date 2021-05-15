library(tidyverse)
library(magrittr)
library(here)

### Reading in the Data

# Signing up for the EPA
# https://aqs.epa.gov/data/api/signup?email=**your-email-here**

# Using the R package for accessing AQS API of the EPA
# devtools::install_github("jpkeller/aqsr")
library(aqsr)

# Create variables AQS_EMAIL="........", AQS_KEY="......." 
# from the email you received


# Creating authentication for the data fetch from EPA's API
MyUser = aqsr::create_user(email = AQS_EMAIL, key = AQS_KEY)

# Viewing the API services, 
list_services()
list_endpoints(service = "dailyData")
list_required_vars(endpoint = "byCounty")

  # Checking the list of states
aqs_list_states(MyUser)
aqs_list_parameters(MyUser, pc = "CRITERIA")

StateCode = c(paste0("0", 1:9),
              seq(10, 56) %>% as.character())

# Testing
df = data.frame()
for (i in 1:56) {
df = bind_rows(df,
               aqs_annualData(aqs_user = MyUser,
                     endpoint = "byState",
                     state = StateCode[i],
                     bdate = "20150101",
                     edate = "20150131",
                     param = "88101")
                )
}

counties = unique(ocsdata$county)

# Getting Daily Data for all Counties in 2015

df2015 = data.frame()

for (j in 1:56){

  Sel_State = StateCode[j]
  TotCounties = aqs_list_counties(MyUser, state = Sel_State)[, "value_represented"]
  Sel_Counties = which(TotCounties %in% counties)
  Sel_Counties = sprintf("%03d", Sel_Counties)

    for (i in 1:length(Sel_Counties)) {
    df2015 = bind_rows(df2015,
                       aqs_dailyData_byCounty(
                         aqs_user = MyUser,
                         bdate = "20150101",
                         edate = "20150131",
                         state = Sel_State,
                         county = Sel_Counties[i],
                         param = "88101")
                       )
    }
}
write_csv2(df2015, file = here("data", "wrangled", "EPA_County_Daily_2015.csv"))

# For year 2016
df2016 = data.frame()

for (j in 1:56){
  
  Sel_State = StateCode[j]
  TotCounties = aqs_list_counties(MyUser, state = Sel_State)[, "value_represented"]
  Sel_Counties = which(TotCounties %in% counties)
  Sel_Counties = sprintf("%03d", Sel_Counties)
  
  for (i in 1:length(Sel_Counties)) {
    df2016 = bind_rows(df,
                       aqs_dailyData_byCounty(
                         aqs_user = MyUser,
                         bdate = "20160101",
                         edate = "20160131",
                         state = Sel_State,
                         county = Sel_Counties[i],
                         param = "88101")
    )
  }
}
write_csv2(df2016, file = here("data", "wrangled", "EPA_County_Daily_2016.csv"))






######################################################################

# Working with OCS Data to generate the parameters to use in data
# scraping from EPA website using API package "aqsr"

# Getting the IDs from Roger Peng's DataSet
IDsToExtract = as.character(ocsdata$id)

# Just to view the diversity and different forms of IDs
# table(str_length(IDsToExtract))

# Creating different subsets of IDs by their string length
IDs10 = IDsToExtract[str_length(IDsToExtract) == 10]
IDs9 = IDsToExtract[str_length(IDsToExtract) == 9]
IDs8 = IDsToExtract[str_length(IDsToExtract) == 8]

# Starting to create a dataframe by splitting IDs with 10 characters
IDs = data.frame(OriginalData = IDs10,
                 State = str_sub(IDs10, start = 1, end = 2),
                 County = str_sub(IDs10, start = 3, end = 5),
                 Site = str_sub(IDs10, start = -4, end = -1)
                 )  

# Appending the DataFrame with splits of IDs with 9 characters
IDs %<>%
  bind_rows(data.frame(OriginalData = IDs9,
                       State = dplyr::if_else(str_length(str_split(IDs9, "[.]", simplify = TRUE)[,1]) == 4,
                                              true = str_sub(str_split(IDs9, "[.]", simplify = TRUE)[,1], start = 1, end = 1),
                                              false = str_sub(str_split(IDs9, "[.]", simplify = TRUE)[,1], start = 1, end = 2))  ,
                       County = dplyr::if_else(str_length(str_split(IDs9, "[.]", simplify = TRUE)[,1]) == 4,
                                               true = str_sub(str_split(IDs9, "[.]", simplify = TRUE)[,1], start = 2, end = 4),
                                               false = str_sub(str_split(IDs9, "[.]", simplify = TRUE)[,1], start = 3, end = 5))  ,
                       Site = str_split(IDs9, "[.]", simplify = TRUE)[,2]
                       )
            ) 

# Appending the DataFrame with splits of IDs with 8 characters
IDs %<>%
  bind_rows(data.frame(OriginalData = IDs8,
                       State = dplyr::if_else(str_length(str_split(IDs8, "[.]", simplify = TRUE)[,1]) == 4,
                                              true = str_sub(str_split(IDs8, "[.]", simplify = TRUE)[,1], start = 1, end = 1),
                                              false = str_sub(str_split(IDs8, "[.]", simplify = TRUE)[,1], start = 1, end = 2)),
                       County = dplyr::if_else(str_length(str_split(IDs8, "[.]", simplify = TRUE)[,1]) == 4,
                                               true = str_sub(str_split(IDs8, "[.]", simplify = TRUE)[,1], start = 2, end = 4),
                                               false = str_sub(str_split(IDs8, "[.]", simplify = TRUE)[,1], start = 3, end = 5)),
                       Site = str_split(IDs8, "[.]", simplify = TRUE)[,2]
                       )
            )

# Appending the DataFrame with splits of last ID with 6 characters (easier manually)
IDs %<>%
  bind_rows(data.frame(OriginalData = IDsToExtract[str_length(IDsToExtract) == 6],
                       State = "04",
                       County = "015",
                       Site = "1000"))

# Correcting the format of few left out split IDs by pre/post-fixing "0" or "00" as required
IDs$State = if_else(str_length(IDs$State) == 1,
                   true = paste0("0", IDs$State),
                   false = IDs$State)
IDs$Site = if_else(str_length(IDs$Site) == 4,
                   true = IDs$Site,
                   false = if_else(str_length(IDs$Site) == 3,
                                   true = paste0(IDs$Site, "0"),
                                   false = paste0(IDs$Site, "00"))
                   )

# Data Frame to use the ID codes is ready for using in aqsr package
df2015 = data.frame()
for (i in nrow(IDs)){
  df2015 = bind_rows(df2015,
                     aqs_dailyData_bySite(
                       aqs_user = MyUser,
                       bdate = "20150101",
                       edate = "20150131",
                       state = IDs[i, "State"],
                       county = IDs[i, "County"],
                       site = IDs[i, "Site"],
                       param = "88101")
                     )
}
