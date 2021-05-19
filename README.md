# Final Project 

### for the class Data Science for Public Health & Biomedical Engineering

#### (Taught by Prof. Brian Caffo)

This Final Project has been prepared  by 
1. Vinayak Bhardwaj, 
2. Sejal Ghate and 
3. Aditya Dahiya.

This repo is now public, as we will be displaying our app for the entire class to see.  

Authors:  

1. **Sejal Ghate (BME student, Whiting School)**  
Focus was mainly for the prediction tab and the appearance of the app. I ran the dataset with SVM and XGBoost Models for classification, and decided to go ahead with XGBoost for better accruacy, and with linear regression to get predicted value. Apart from this, I assessed and plotted variable importance metrics for different models created and studied by my team member and implemented user inputs into the app. I was also played around  with the reactivity element within shiny, and used css for themeing and formatting of the app and finally integrated the teams work together by stiching together the respective components of the app.

    Here is the link! Check it out: https://sejal-ghate.shinyapps.io/DS4PH-BME_CapstoneProject/

    [**Click here to get a demonstration of the app!**](https://livejohnshopkins-my.sharepoint.com/:v:/g/personal/sghate1_jh_edu/EeCu9fxue0hKrijiQ1jpjAsBrdGcHNl6K3Mm57mbtvbKFQ?e=2PSgDV)

2. **Vinayak Bhardwaj (DrPH student, Bloomberg School)**  
Contribution to the project - focus was on identifying the best predictors for the dataset that we were working on. Using the ridge and lasso regression techniques I worked on creating a model with above 50% predictive power on the training data set (ridge regression and lasso regression R script given in the repo). Additionally, I worked on using the Variable Importance Predictor method to work out the most important variables in the given dataset. The results of this are provided in a separate r-script in the repo and referred to in the final write-up of the app (in the "Prediction" tab). URL to video: https://drive.google.com/file/d/15uY51ddknRcA74i3V5nvqhDStlxWsSRT/view?usp=sharing

3. **Aditya Dahiya (MPH student, Bloomberg School)**  
Contribution to the project: focus was on data harvesting from EPA's [website](https://www.epa.gov/) API using the the R package [aqrs](https://github.com/jpkeller/aqsr). Further, data visualizations were created, first, as animated maps and graphs for displaying overall PM 2.5 level trends in last two decades using `gganimate`. Then, data visualizations were made in the **Visualizations** tab to generate color-coded average and maximum PM 2.5 levels at sites across US, selected state and trends of a particular state as compared to others. Lastly, data analysis tab was created to dispaly monthly, yearly, county-wise and city-wise levels of PM 2.5 to identify patterns emerging in the data. This is the [link](https://youtu.be/85P9knkBVXY) to the hosted video on Youtube. And, this is the [link](https://aditya-dahiya.shinyapps.io/Capstone-ds4phbme/) to the live app online at Shinyapps.io. 

This project focuses on the [Air Data](https://www.epa.gov/outdoor-air-quality-data): Air Quality Data Collected at Outdoor Monitors Across the United States. It uses and combines data from three sources:-  

(a) Outdoor air quality [data](https://aqs.epa.gov/aqsweb/documents/data_api.html) collected from state, local and tribal monitoring agencies across the United States by the [EPA](https://www.epa.gov/).  

(b) Data harvested from the Air Quality System (AQS) API using the R package [aqrs](https://github.com/jpkeller/aqsr), developed by [Joshua P. Keller](https://github.com/jpkeller), [Roger D. Peng](https://github.com/rdpeng) and [Daniel Bride](https://github.com/danielbride).  

(c) A special [data set](https://raw.githubusercontent.com/opencasestudies/ocs-bp-air-pollution/master/data/raw/pm25_data.csv) created by [Roger D. Peng](https://github.com/rdpeng), used by Open Case Studies project on predicting PM 2.5 levels using machine learning algorithms in [tidymodels](https://www.tidymodels.org/).  


*Tabs in the app*:  

- The **Visualization** tab shows different visualizations of PM 2.5 levels in micrograms per cubic metre over time periods, states, sites and seasons.  
- Then, **Data Analysis** tab adds important graphs to analyze month-wise, year-wise and smoothed trens of PM 2.5 levels in various counties selected by the user. It also allows one to examine data in cities within the selected counties.  
- Finally, the **Prediction** tab analyzes Roger D. Peng's [dataset](https://raw.githubusercontent.com/opencasestudies/ocs-bp-air-pollution/master/data/raw/pm25_data.csv) and displays important predictors. It then uses machine learning algorithms to predict PM 2.5 levels and find best predictor variables.


