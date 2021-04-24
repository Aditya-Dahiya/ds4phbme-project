library(tidyverse)
library(here)
library(magrittr)


# Load Roger Peng's data
# load(here("data", "raw", "ocs_data_roger_peng.rda"))

# or, use
ocsdata = read_csv("https://raw.githubusercontent.com/opencasestudies/ocs-bp-air-pollution/master/data/raw/pm25_data.csv")

ocsdata %<>%
    mutate(across(c(id, fips, zcta), as.factor))

# ocsdata %>% skimr::skim()
# ocsdata %>% distinct(state)

# ocsdata %>%
#   group_by(city) %>%
#   count() %>%
#   arrange(desc(n))

library(corrplot)
ocsdata %>%
    select_if(is.numeric) %>%
    cor() %>%
    abs() %>%
    corrplot::corrplot(tl.cex = 0.2, cl.lim = c(0,1), order = "hclust")

library(GGally)
ocsdata %>%
    select(contains("imp")) %>%
    ggcorr(palette = "RdBu", label = TRUE)

ocsdata %>%
    select(contains("imp")) %>%
    ggpairs()

ocsdata %>%
    select(contains("pri")) %>%
    ggcorr(label = TRUE, size = 3, hjust = 0.95, layout.exp = 3)

ocsdata %>%
    select(contains("nei")) %>%
    ggcorr(label = TRUE, hjust = 0.95, size = 3, layout.exp = 4)

ocsdata %>%
    select(log_nei_2008_pm25_sum_10000, popdens_county, 
           log_pri_length_10000, imp_a10000) %>%
    ggcorr(label = TRUE, hjust = 0.9, layout.exp = 2)

#ocsdata %>%
#    mutate(log_popdens_county= log(popdens_county)) %>%
#    mutate(log_pop_county = log(county_pop))

names(ocsdata)


library(tidymodels)
set.seed(3)
ocs_split = rsample::initial_split(ocsdata, prop = 2/3)
ocs_split

# We could use strata argument in initial_split to stratify
ocsdata %>%
    count(state) %>%
    arrange(n)

train_set = training(ocs_split)
test_set = testing(ocs_split)
train_set %>%
    count(state) %>%
    arrange(n)
test_set %>%
    count(state) %>%
    arrange(n)

# Using recipes package for feature engineering
simple_rec = train_set %>% 
                recipe(value ~ .)
simple_rec
summary(simple_rec)
# Removing un-needed predictors, converting them into IDs
simple_rec = train_set %>% 
    recipe(value ~ .) %>%
    update_role(id, new_role = "id variable")

# Adding steps to the model recipe

simple_rec %<>%
    update_role("fips", new_role = "county id") %>%
    step_dummy(state, county, city, zcta, one_hot = TRUE) %>%
    step_corr(all_predictors(), - CMAQ, - aod)%>%
    step_nzv(all_predictors(), - CMAQ, - aod)
simple_rec

# Preparing a prepped-up recipe with the data set
prepped_rec = prep(simple_rec, retain = TRUE, verbose = TRUE)
names(prepped_rec)

# Checking the pre-processed data
baked_train = bake(prepped_rec, new_data = NULL)
setdiff(colnames(baked_train), colnames(train_set))
setdiff(colnames(train_set), colnames(baked_train))

# Checking out the pre-processed testing data set
baked_test = bake(prepped_rec, new_data = test_set)
glimpse(baked_test)
naniar::vis_miss(baked_test)

# Checking out Cities due to the NAs in the variable "city_Not.in.a.city"

# Number of unique cities in test set and training set
train_set %>% distinct(city) %>% nrow()
test_set %>% distinct(city) %>% nrow()

# Number of different cities between test and training set
dim(setdiff(train_set %>% distinct(city),
            test_set %>% distinct(city)
            )
    )[1]

# Number of common cities between test set and the training set
dim(intersect(train_set %>% distinct(city),
              test_set %>% distinct(city)
          )
    )[1]

# Converting the city variable into a dummy for whether the station is within or
# outside a city
ocsdata %<>%
    mutate(city = case_when(city == "Not in a city" ~ "Not in a city",
                            city != "Not in a city" ~ "In a city")
           )
# Just verifying
table(ocsdata$city)

# Now we repeat all steps with a new recipe
# Split data again
ocs_split = initial_split(ocsdata, prop = 2/3)
train_set = training(ocs_split)
test_set = testing(ocs_split)
novel_rec = recipe(train_set) %>%
    update_role(everything(), new_role = "predictor") %>%
    update_role(value, new_role = "outcome") %>%
    update_role(id, new_role = "id variable") %>%
    update_role("fips", new_role = "county id") %>%
    step_dummy(state, county, city, zcta, one_hot = TRUE) %>%
    step_corr(all_numeric()) %>%
    step_nzv(all_numeric()) 
novel_rec    

# Prepped recipe
prepped_rec = prep(novel_rec, verbose = TRUE, retain = TRUE)
baked_train = bake(prepped_rec, new_data = NULL)

# Checking that the baked data from the recipe has no missing values
baked_test = bake(prepped_rec, new_data = test_set)
naniar::vis_miss(baked_test)

# Using different models from parsnip package (just like caret)
library(parsnip)
model1 = parsnip::linear_reg() %>%
            set_engine("lm") %>%
            set_mode("regression")
model1

# Using workflow package to combine the recipe and the model

wf1 = workflow() %>%
        add_recipe(novel_rec) %>%
        add_model(model1)
fit1 = fit(object = wf1, data = train_set)

# Displaying the fit output (coefficients of regression)
output1 = fit1 %>%
    pull_workflow_fit() %>%
    broom::tidy()
library(kableExtra)
output1 %>%
    arrange(p.value) %>% 
    kbl(digits = 3) %>% kable_classic()

# Displaying important variables
library(vip)
library(ggthemes)
fit1 %>%
    pull_workflow_fit() %>%
    vip(num_features = 10) +
    theme_clean()

# Displaying the fitted values in the training data set
wffit = fit1 %>%
        pull_workflow_fit()

fitted_values <- fitted(wffit[["fit"]])

fitted_actual_df = tibble(
    Fitted = fitted_values,
    Actual = train_set$value,
    ID = train_set$id,
    FIPS = train_set$fips
)
fitted_actual_df

# Plotting the fitted vs. actual values
ggplot(fitted_actual_df) +
    geom_point(aes(x = Actual, y = Fitted), alpha = 0.5) +
    geom_segment(x = 5, y = 5, xend = 25, yend = 25,
                 lwd = 1.2, col = "blue") +
    theme_clean() + 
    labs(x = "Actual Values of PM2.5",
         y = "Fitted / Predicted values for PM2.5",
         title = "Predicted vs. Actual Values")

# Evaluating model performance
yardstick::metrics(fitted_actual_df,
                   truth = Actual,
                   estimate = Fitted)
rmse(fitted_actual_df, truth = Actual, estimate = Fitted)
mae(fitted_actual_df, truth = Actual, estimate = Fitted)
rsq(fitted_actual_df, truth = Actual, estimate = Fitted)

# Using cross-validation
set.seed(3)
vfold1 = rsample::vfold_cv(train_set, v = 4)
pull(vfold1, splits)

# Assessing model performance on v-folds using tune
resample_fit = fit_resamples(wf1, vfold1)
show_best(resample_fit, metric = "rmse")


# Using a RandomForest now on the data set
library(randomForest)

# New recipe to remove the variables with more than 51 factors
RF_rec <- recipe(train_set) %>%
    update_role(everything(), new_role = "predictor")%>%
    update_role(value, new_role = "outcome")%>%
    update_role(id, new_role = "id variable") %>%
    update_role("fips", new_role = "county id") %>%
    step_novel("state") %>%
    step_rm("county") %>%
    step_rm("zcta") %>%
    step_string2factor("state", "city") %>%
    step_corr(all_numeric())%>%
    step_nzv(all_numeric())

# Starting to create the model using parsnip
modelRF = parsnip::rand_forest(mtry = 10, min_n = 3) %>%
          set_engine("randomForest") %>%
          set_mode("regression")
modelRF

# Starting a work-flow and fitting the model

RFworkflow = workflow() %>%
    add_recipe(RF_rec) %>%
    add_model(modelRF)
fit2 = parsnip::fit(RFworkflow, data = train_set)
fit2

# Creating plot for best predictors
fit2 %>%
    pull_workflow_fit() %>%
    vip(num_features = 10) +
    theme_clean()

# Fitting data with cross validation
resample_fit2 = fit_resamples(RFworkflow, vfold1)
show_best(resample_fit2, metric = "rmse")
bind_rows(show_best(resample_fit, metric = "rmse"),
          show_best(resample_fit2, metric = "rmse"))

# Using tune() to find best hyper-parameters for the randomForests Model
tuningRFmodel = rand_forest(mtry = tune(), min_n = tune()) %>%
    set_engine("randomForest") %>%
    set_mode("regression")
tuningRFmodel

# Creating Workflow in this tuning model
tuningRFwf = workflow() %>%
    add_model(tuningRFmodel) %>%
    add_recipe(RF_rec)
tuningRFwf

# Detect number of cores on the computer
parallel::detectCores()

# Do the calculation on 2 cores, parallely to imporve speed
doParallel::registerDoParallel(cores=2)
set.seed(3)
tuneRFresults = tune_grid(object = tuningRFwf, 
                          resamples = vfold1, 
                          grid = 20)
tuneRFresults %>%
    collect_metrics()

show_best(tuneRFresults, metric = "rmse", n = 1)
# Saving the hyper-parameters' values for best CV model
Rfvals = select_best(tuneRFresults, "rmse")
Rfvals

# Final the work-flow with tuned best values
finalRFflow = finalize_workflow(tuningRFwf, Rfvals)

# Final evaluation on the test set
overallFit = last_fit(finalRFflow, ocs_split)
collect_metrics(overallFit)
preds = collect_predictions(overallFit)
preds

# Data Visualization
library(sf)
library(maps)
library(rnaturalearth)
library(rgeos)
world = ne_countries(scale = "medium", returnclass = "sf",
                     country = "united states of america")
pillar::glimpse(world)
pryr::object_size(world)
ggplot(data = world) + 
    geom_sf() + 
    theme_void() + 
    coord_sf(xlim = c(-125, -66), ylim = c(24.5, 50), 
             expand = FALSE) +
    geom_point(data = ocsdata, 
               mapping = aes(x = lon, y = lat),
               alpha = 0.5, col = "darkred")

# Adding counties
counties = sf::st_as_sf(maps::map("county", plot = FALSE,
                                  fill = TRUE))
# Separating state and county names 
counties %<>%
    tidyr::separate(ID, into = c("state", "county"), sep = ",") %>%
    mutate(county = stringr::str_to_title(county))

# Combining the data sets using inner_join() of dplyr()
ComData = dplyr::inner_join(counties, ocsdata, by = "county")
glimpse(ComData)

# Creating map of monitors with counties
monitors = ggplot(data = world) + 
    geom_sf(data = counties, fill = NA, col = "grey") + 
    theme_void() + 
    coord_sf(xlim = c(-125, -66), ylim = c(24.5, 50), 
             expand = FALSE) +
    geom_point(data = ocsdata, 
               mapping = aes(x = lon, y = lat),
               alpha = 0.5, col = "darkred") + 
    labs(title = "Monitors Location")
monitors

# Plotting counties with color gradients based on the pollution levels
ggplot(data = world) + 
    geom_sf(data = ComData, aes(fill = value)) + 
    coord_sf(xlim = c(-125, -66), ylim = c(24.5, 50), expand = FALSE) +
    scale_fill_gradientn(colours = topo.colors(3), 
                         na.value = "transparent",
                         breaks = c(0,10,20),
                         labels = c(0,10,20),
                         limits = c(0,23.5), 
                         name = "PM2.5 ug/m3") +
    labs(title = "True PM 2.5 Levels in different counties with Monitors") +
    theme_void()

# Calculating the predicted values
FinalFitTrain = parsnip::fit(finalRFflow, data = train_set)
FinalFitTest = parsnip::fit(finalRFflow, data = test_set)

Preds_Train = predict(FinalFitTrain, train_set) %>%
    bind_cols(train_set %>% select(value, fips, county, id))
Preds_Test = predict(FinalFitTest, test_set) %>%
    bind_cols(test_set %>% select(value, fips, county, id))
OCSpredictions = bind_rows(Preds_Train, Preds_Test)

ComData1 = inner_join(counties, OCSpredictions, by = "county") %>%
    dplyr::rename(Predictions = '.pred')
glimpse(ComData1)
ggplot(data = world) + 
    geom_sf(data = ComData1, 
            aes(fill = Predictions)) + 
    coord_sf(xlim = c(-125, -66), 
             ylim = c(24.5, 50), 
             expand = FALSE) +
    scale_fill_gradientn(colours = topo.colors(3), 
                         na.value = "transparent",
                         breaks = c(0,10,20),
                         labels = c(0,10,20),
                         limits = c(0,23.5), 
                         name = "PM2.5 ug/m3") +
    labs(title = "Predicted PM 2.5 Levels") +
    theme_void()
names(ComData)
names(ComData1)
