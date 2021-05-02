load(here("data", "wrangled", "Daily_Data_10years.rda"))

############################ Global ##############################

# Creating subsets using User Inputs for the Shiny App
List_States = unique(DlyData$`State Name`)[1:50]

# Dummy Variable Entry for User Inputs (during development phase)
Sel_State = "California"
Sel_Date = lubridate::as_date(c("2014-01-01", "2019-12-31"))


# Creating some data frames for maps' plotting
UScounties = sf::st_as_sf(maps::map("county", 
                                    plot = FALSE,
                                    fill = TRUE))
temp = str_split(string = UScounties$ID, 
                 pattern = ",", 
                 simplify = TRUE,
                 n = 2) %>%
    as_tibble() %>%
    mutate(State = str_to_title(V1)) %>%
    mutate(County = str_to_title(V2)) %>%
    select(State, County)
UScounties = bind_cols(UScounties, temp)
rm(temp)

######################### Reactive Part ############################

# Counties List based on State Selection
List_Counties = DlyData %>%
    filter(`State Name` %in% Sel_State) %>%
    select(`County Name`) %>%
    unique() %>%
    as_vector()
names(List_Counties) = NULL

# Reactive User Input entry
Sel_County = List_Counties[c(1,4)]

# Creating data.frames to be used for plotting
USstates = spData::us_states %>%
    mutate(FillVar = ifelse(NAME == Sel_State,
                            yes = 1, 
                            no = 0))
Plotdata = DlyData %>%
    filter(`State Name` == Sel_State,
           `County Name` == Sel_County) %>%
    filter(Date >= Sel_Date[1] & Date <= Sel_Date[2]) %>%
    mutate(Month = lubridate::month(Date,
                                    label = TRUE)) %>%
    mutate(Year = lubridate::year(Date))

Plotmap = UScounties %>%            # for use in plotted maps
    filter(State == Sel_State) %>%
    mutate(CountyVar = ifelse(County == Sel_County,
                              yes = "Selected Counties",
                              no = "Others")) %>%
    mutate(CountyVar = as.factor(CountyVar))

############ 1. Creating a smoothed plot over years ###############
ggplot(Plotdata, aes(x = Date)) + 
    geom_smooth(aes(y = PM2.5, 
                    col = `County Name`),
                se = FALSE) +
    geom_point(aes(y = PM2.5,
                   col = `County Name`),
               alpha = 0.1,
               pch = 20) + 
    scale_y_continuous(limits = c(0,
                                  quantile(Plotdata$PM2.5, 0.99))) + 
    theme_classic() + 
    theme(legend.position = "bottom") +
    labs(x = "Years", 
         y = latex2exp::TeX("PM_{2.5} \ \ levels \ \ (ug / m^{3})"),
         title = "PM 2.5 levels over time",
         subtitle = "Actual values with Smoothed Version on top"
         )

############ 2. Creating a smoothed plot over years for cities ####
ggplot(Plotdata, aes(x = Date)) + 
    geom_smooth(aes(y = PM2.5, 
                    col = `City Name`),
                se = FALSE) +
    theme_classic() + 
    theme(legend.position = "bottom") +
    labs(x = "Years", 
         y = latex2exp::TeX("PM_{2.5} \ \ levels \ \ (ug / m^{3})"),
         title = "City-wise PM 2.5 levels within the County",
         subtitle = "Smoothed Version overlaid on actual values"
    )

############ 3. Smoothed plot of AQI for the time period ##########
ggplot(Plotdata, aes(x = Date)) + 
    geom_smooth(aes(y = AQI, 
                    col = `County Name`),
                se = FALSE,
                lty = 2) +
    theme_classic() + 
    theme(legend.position = "bottom") +
    labs(x = "Years", 
         y = "A.Q.I.",
         title = "Air Quality Index over time",
         subtitle = "Smoothed Version"
    )

############ 4. USA map showing the County Locations ##############
USstates %>%
    mutate(FillVar = ifelse(NAME == Sel_State,
                            yes = 1, 
                            no = 0)) %>%
ggplot() +
    geom_sf(data = USstates, 
            aes(fill = as.factor(FillVar)), 
            color = "black",
            alpha = 0.5) +
    coord_sf(xlim = c(-125, -66), ylim = c(24.5, 50), 
             expand = FALSE) +
    theme_void() +
    scale_fill_manual(values = c("0" = "white", "1" = "red")) +
    theme(legend.position = "none")

ggplot(data = Plotmap) +
    geom_sf(mapping = aes(fill = CountyVar),
            col = "darkgrey") +
    geom_point(data = Plotdata,
               mapping = aes(x = Longitude,
                             y = Latitude,
                             col = `City Name`)) +
    theme_void() +
    scale_fill_manual(values = c("Others" = "white", 
                                 "Selected Counties" = "grey"),
                      name = "Counties") +
    labs(title = paste0("Map of the state of ", Sel_State),
         subtitle = "Selected counties in grey")


############ 5. Month-wise average with error bars ################
ggplot(data = Plotdata) +
    geom_boxplot(mapping = aes(x = Month, 
                               y = PM2.5,
                               col = `County Name`),
                 outlier.size = 1,
                 outlier.alpha = 0.1) +
    scale_y_continuous(limits = c(0, 
                                  quantile(Plotdata$PM2.5, 0.99))) +
    theme_classic() +
    theme(legend.position = "bottom") +
    labs(x = NULL, 
         y = latex2exp::TeX("PM_{2.5} \ \ levels \ \ (ug / m^{3})"),
         title = latex2exp::TeX("Average \ Monthly \  PM_{2.5} \ \ levels"),
         subtitle = "(over the selected time period)")

############ 6. Year-wise average with error bars ################

ggplot(data = Plotdata) +
    geom_boxplot(mapping = aes(x = as.factor(Year), 
                               y = PM2.5,
                               col = `County Name`),
                 outlier.size = 1,
                 outlier.alpha = 0.1) +
    scale_y_continuous(limits = c(0, 
                                  quantile(Plotdata$PM2.5, 0.99))) +
    theme_classic() +
    theme(legend.position = "bottom") +
    labs(x = NULL, 
         y = latex2exp::TeX("PM_{2.5} \ \ levels \ \ (ug / m^{3})"),
         title = latex2exp::TeX("Annual \ Average\  PM_{2.5} \ \ levels"),
         subtitle = "(over the selected time period)")

