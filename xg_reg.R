library(data.table)
library(xgboost)
library(mlr)
library(caret)
library(tidyverse)
library(mltools)
library(caret)
library(vip)
library(randomForest)

load (url("https://github.com/Aditya-Dahiya/ds4phbme-project/blob/main/data/wrangled/wr_ocsdata.rda?raw=true"))
data = ocsdata


ocsdata = ocsdata %>% mutate(polluted = case_when(value>10 ~ 1, value <= 10 ~ 0))
label = as.numeric(factor(ocsdata$polluted)) - 1
ocsdata = ocsdata %>% select(CMAQ,aod,log_pri_length_15000,somehs,log_nei_2008_pm25_sum_10000)


# get the numb 70/30 training test split
numberOfTrainingSamples <- round(length(label) * .7)

# training data
train_data <- ocsdata[1:numberOfTrainingSamples,]
train_labels <- label[1:numberOfTrainingSamples]

# testing data
test_data <- ocsdata[-(1:numberOfTrainingSamples),]
test_labels <- label[-(1:numberOfTrainingSamples)]

setDT(train_data)
setDT(test_data)

new_tr <- model.matrix(~.+0,data = train_data) 
new_ts <- model.matrix(~.+0,data = test_data)


# put our testing & training data into two separated Dmatrixs objects
dtrain <- xgb.DMatrix(data = new_tr, label= train_labels)
dtest <- xgb.DMatrix(data = new_ts, label= test_labels)


params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.3, gamma=0, max_depth=6, min_child_weight=1, subsample=1, colsample_bytree=1)

xgbcv <- xgb.cv( params = params, data = dtrain, nrounds = 100, nfold = 5, showsd = T, stratified = T, print_every_n = 10, early_stopping_rounds = 20, maximize = F)

xgb1 <- xgb.train (params = params, data = dtrain, nrounds = 9, watchlist = list(val=dtest,train=dtrain), print_every_n = 10, early_stopping_rounds = 10, maximize = F,eval = 'rmse')
xgbpred <- predict (xgb1,dtest)
xgbpred <- ifelse (xgbpred > 0.5,1,0)
confusionMatrix (as.factor(xgbpred), as.factor(test_labels))

mat <- xgb.importance (feature_names = colnames(ocsdata),model = xgb1)
xgb.plot.importance (importance_matrix = mat[1:20])

saveRDS(xgb1,'xgb_model.rds')
