library(plyr)
library(readr)
library(dplyr)
library(caret)
library(ggplot2)
ocsdata= load (url("https://github.com/Aditya-Dahiya/ds4phbme-project/blob/main/data/wrangled/wr_ocsdata.rda?raw=true"))
glimpse(ocsdata)

set.seed(100)
index = sample(1:nrow(ocsdata), 0.7*nrow(ocsdata))

train = ocsdata[index,] #create training data 
test = ocsdata[-index,] #create test data

dim(train)
dim(test)

#scaling the numeric features/variables

cols = c('fips', 'CMAQ', 'zcta', 'zcta_area', 'zcta_pop', 'imp_a500', 'imp_a1000', 'imp_a5000', 'imp_a10000', 'imp_a15000', 'county_area','county_pop', 'log_dist_to_prisec', 'log_pri_length_5000', 'log_pri_length_10000', 'log_pri_length_15000', 'log_pri_length_25000', 'log_prisec_length_500', 'log_prisec_length_1000', 'log_prisec_length_5000', 'log_prisec_length_10000', 'log_prisec_length_15000', 'log_prisec_length_15000', 'log_prisec_length_25000', 'log_nei_2008_pm25_sum_10000', 'log_nei_2008_pm25_sum_15000', 'log_nei_2008_pm25_sum_25000', 'popdens_county', 'popdens_zcta','nohs', 'somehs', 'hs','somecollege','associate','bachelor','grad','pov','hs_orless','urc2013','urc2006','aod','log_popdens_county','log_pop_county')

pre_proc_val = preProcess(train[,cols], method = c("center",  "scale"))

train [,cols] = predict(pre_proc_val, train[,cols])
test[,cols]= predict(pre_proc_val, test[,cols])
summary (train)

#run linear regression on entire set of variables 

lr = lm(value ~ fips + CMAQ+ zcta+ zcta_area+ zcta_pop + imp_a500 + imp_a1000 + imp_a5000 + imp_a10000 + imp_a15000 + county_area + county_pop + log_dist_to_prisec + log_pri_length_5000 + log_pri_length_10000 + log_pri_length_15000 + log_pri_length_25000 + log_prisec_length_500 + log_prisec_length_1000 + log_prisec_length_5000 + log_prisec_length_10000 + log_prisec_length_15000 + log_prisec_length_15000 + log_prisec_length_25000 + log_nei_2008_pm25_sum_10000 + log_nei_2008_pm25_sum_15000 + log_nei_2008_pm25_sum_25000 + popdens_county + popdens_zcta + nohs + somehs + hs + somecollege + associate + bachelor + grad + pov + hs_orless + urc2013 + urc2006 + aod + log_popdens_county + log_pop_county, data = ocsdata)
summary(lr)

#create model evaluation metrics

eval_metrics = function(model, df, predictions, target){
  resids = df[,target] - predictions
  resids2 = resids**2
  N = length(predictions)
  r2=as.character(round(summary(model)$r.squared,2))
  adj_r2=as.character(round(summary(model)$adj.r.squared,2))
  print(adj_r2)
  print(as.character(round(sqrt(sum(resids2)/N),2)))
}


#predicting and evaluating the model on train data predictions

predictions = predict(lr, newdata=train)
eval_metrics(lr, train, predictions, target = 'value')

#predicting and evaluating the model on test data 

predictions = predict(lr,newdata= test)
eval_metrics(lr,train, predictions, target = 'value')


#output shows that RMSE is 0.05 million for train data and 5.5 million for test data. R-squared is 0.87 for train data and for test data
#regularization


cols_reg = c('value', 'fips', 'CMAQ', 'zcta', 'zcta_area', 'zcta_pop', 'imp_a500', 'imp_a1000', 'imp_a5000', 'imp_a10000', 'imp_a15000', 'county_area','county_pop', 'log_dist_to_prisec', 'log_pri_length_5000', 'log_pri_length_10000', 'log_pri_length_15000', 'log_pri_length_25000', 'log_prisec_length_500', 'log_prisec_length_1000', 'log_prisec_length_5000', 'log_prisec_length_10000',  'log_prisec_length_15000', 'log_prisec_length_25000', 'log_nei_2008_pm25_sum_10000', 'log_nei_2008_pm25_sum_15000', 'log_nei_2008_pm25_sum_25000', 'popdens_county', 'popdens_zcta','nohs', 'somehs', 'hs','somecollege','associate','bachelor','grad','pov','hs_orless','urc2013','urc2006','aod','log_popdens_county','log_pop_county')

dummies = dummyVars(value ~ ., data= ocsdata[,cols_reg])

train_dummies=predict(dummies, newdata=train[,cols_reg])

test_dummies = predict(dummies, newdata= test[,cols_reg])

print(dim(train_dummies)); print(dim(test_dummies))


#Ridge regression

library(glmnet)

x= as.matrix(train_dummies)
y_train = train$value

x_test = as.matrix(test_dummies)
y_test= test$value

lambdas = 10^seq(2, -3, by = -.1)
ridge_reg=glmnet(x,y_train, nlambda = 25, alpha =0, family = 'gaussian', lambda=lambdas)

summary(ridge_reg)


#finding the optimal lambda 
cv_ridge= cv.glmnet(x,y_train, alpha=0,lambda=lambdas)
optimal_lambda = cv_ridge$lambda.min
optimal_lambda

#optimal lambda is 0.32

#we can use this to build the ridge regression model 

#we will also create a function to calculate and print the results 

#Compute the r^2 from true and predicted values 
eval_results = function (true, predicted, df){
  SSE = sum((predicted-true)^2)
  SST = sum((true- mean(true))^2)
  R_square = 1 - SSE/SST
  RMSE = sqrt(SSE/nrow(df))


#Model performance metrics

data.frame(
  RMSE = RMSE,
  Rsquare = R_square
)

}

#Prediction and evaluation on train data

predictions_train = predict(ridge_reg, s= optimal_lambda, newx=x)
eval_results(y_train, predictions_train, train)

#prediction and evaluation on test data 

predictions_test = predict(ridge_reg, s= optimal_lambda, newx=x_test)
eval_results(y_test, predictions_test, test)



##### Lasso Regression


lambdas = 10^seq(2,-3, by = -.1)

#setting alpha = 1 implements lasso regression

lasso_reg = cv.glmnet(x, y_train, alpha = 1, lambda = lambdas, standardize = TRUE, nfolds= 5)

#Best

lambda_best= lasso_reg$lambda.min
lambda_best


#using this optimal lambda value we train the lasso model below

lasso_model = glmnet(x, y_train, alpha = 1, lambda = lambda_best, standardize = TRUE)
predictions_train = predict(lasso_model, s = lambda_best, newx = x)
eval_results(y_train, predictions_train, train)

predictions_test= predict(lasso_model, s = lambda_best, newx=x_test)
eval_results (y_test, predictions_test, test)


#Results show that RMSE and R-squared values on the training data are 0.5 million and 96% respectively 
#Results on the test data are 1.6 million and 52% respectively.



