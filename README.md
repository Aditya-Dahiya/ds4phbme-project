# Final Project 

### for the class Data Science for Public Health & Biomedical Engineering

#### (Taught by Prof. Brian Caffo)

This Final Project has been prepared  by 
1. Vinayak Bhardwaj, 
2. Sejal Ghate and 
3. Aditya Dahiya.

This repo is now public, as we will be displaying our app for the entire class to see.  

Authors:  

1. Sejal Ghate (BME student, Whiting School)  

2. Vinayak Bhardwaj (DrPH student, Bloomberg School)  

3. Aditya Dahiya (MPH student, Bloomberg School)  

This project focuses on the [Air Data](https://www.epa.gov/outdoor-air-quality-data): Air Quality Data Collected at Outdoor Monitors Across the United States. It uses and combines data from three sources:-  

(a) Outdoor air quality [data](https://aqs.epa.gov/aqsweb/documents/data_api.html) collected from state, local and tribal monitoring agencies across the United States by the [EPA](https://www.epa.gov/).  

(b) Data harvested from the Air Quality System (AQS) API using the R package [aqrs](https://github.com/jpkeller/aqsr), developed by [Joshua P. Keller](https://github.com/jpkeller), [Roger D. Peng](https://github.com/rdpeng) and [Daniel Bride](https://github.com/danielbride).  

(c) A special [data set](https://raw.githubusercontent.com/opencasestudies/ocs-bp-air-pollution/master/data/raw/pm25_data.csv) created by [Roger D. Peng](https://github.com/rdpeng), used by Open Case Studies project on predicting PM 2.5 levels using machine learning algorithms in [tidymodels](https://www.tidymodels.org/).  


*Tabs in the app*:  

- The **Visualization** tab shows different visualizations of $PM_{2.5}$ levels in ${\mu}g/m^{3}$ over time periods, states, sites and seasons.  
- Then, **Data Analysis** tab adds important graphs to analyze month-wise, year-wise and smoothed trens of PM 2.5 levels in various counties selected by the user. It also allows one to examine data in cities within the selected counties.  
- Finally, the **Prediction** tab analyzes Roger D. Peng's [dataset](https://raw.githubusercontent.com/opencasestudies/ocs-bp-air-pollution/master/data/raw/pm25_data.csv) and displays important predictors. It then uses machine learning algorithms to predict $PM_{2.5}$ levels and find best predictor variables.


