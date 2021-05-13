library(data.table)
library(xgboost)
library(mlr)
library(caret)
library(tidyverse)
library(mltools)


load (url("https://github.com/Aditya-Dahiya/ds4phbme-project/blob/main/data/wrangled/wr_ocsdata.rda?raw=true"))
data = ocsdata

ocsdata = ocsdata %>% mutate(polluted = case_when(value>10 ~ 1, value <= 10 ~ 0))
ocsdata$polluted = as.factor(ocsdata$polluted)



label = as.numeric(factor(ocsdata$polluted))

label[label == "1"] <- "0"
label[label == "2"] <- "1"

State = model.matrix(~state-1,ocsdata)
Region = model.matrix(~county-1,ocsdata)

ocsdata = ocsdata%>% mutate_if(is.character,as.factor) %>% select(-id,-fips,-zcta, -city,-polluted,-state,-county)




ocsdata2 <- cbind(ocsdata, State, Region)
dat <- data.matrix(ocsdata2)


# get the numb 70/30 training test split
numberOfTrainingSamples <- round(length(label) * .7)

# training data
train_data <- dat[1:numberOfTrainingSamples,]
train_labels <- label[1:numberOfTrainingSamples]

# testing data
test_data <- dat[-(1:numberOfTrainingSamples),]
test_labels <- label[-(1:numberOfTrainingSamples)]


# put our testing & training data into two seperates Dmatrixs objects
dtrain <- xgb.DMatrix(data = train_data, label= train_labels)
dtest <- xgb.DMatrix(data = test_data, label= test_labels)


xgb1 <- xgb.train (params = params, data = dtrain, nrounds = 32, watchlist = list(val=dtest,train=dtrain), print_every_n = 10, early_stopping_rounds = 10, maximize = F , eval_metric = "error")
pred <- predict(bstSparse, dtest)
prediction <- as.numeric(pred > 0.5)
print(head(prediction))






