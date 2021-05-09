install.packages("vip")

set.seed(101)

trn = as.data.frame (ocsdata)

tibble::as.tibble(trn)

install.packages("xgboost")
library(xgboost)
library(dplyr)
install.packages("ranger")
library(ranger)
library(rpart)
library(ggplot2)

tree = rpart(value ~ .,data = ocsdata)

#Fit a random forest

set.seed(101)

rfo = ranger(value ~., data=ocsdata, importance = "impurity")

#Fit a GBM

# Fit a GBM
set.seed(102)
bst <- xgboost(
  data = data.matrix(subset(ocsdata, select = -value)),
  label = ocsdata$value, 
  objective = "reg:linear",
  nrounds = 100, 
  max_depth = 5, 
  eta = 0.3,
  verbose = 0  # suppress printing
)


#Vi plot for single regression tree

(vi_tree = tree$variable.importance)

barplot(vi_tree,horiz = TRUE, las = 0.5)


#VI plot for RF

(vi_rfo = rfo$variable.importance)

(vi_bst = xgb.importance(model=bst))

xgb.ggplot.importance(vi_bst)

install.package("Ckmeans.1d.dp")



library(vip)
vi(tree)

vi(rfo)

vi(bst)

library(vip)
p1 = vip(tree)
p2 = vip(rfo, width = 0.5, aesthetics = list(fill = "green3"))

p3 = vip(bst, aesthetics = list(col = "purple2"))

grid.arrange(p1, p2, p3, ncol = 3)

library(ggplot2)

vip(bst,num_features = 5, geom = "point", horizontal = FALSE,
    aesthetics = list(color = "red", shape = 17, size = 4))+ 
  theme_light()

### Linear Models

#reference: https://koalaverse.github.io/vip/articles/vip.html

library(ggplot2)

#fit a LM

linmod <- lm(value ~ .^2, data = ocsdata)
backward <- step(linmod, direction = "backward", trace = 0)


vi(backward)


p1 = vip(backward, num_features = length(coef(backward)),
         geom="point", horizontal = FALSE)
p2 = vip(backward, num_features= length(coef(backward)), 
         geom = "point", horizontal = FALSE, 
         mapping = aes_string(color = "Sign"))
grid.arrange(p1, p2, nrow = 1)
