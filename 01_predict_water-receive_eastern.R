# Predict water receive
# 东线是12年通水的； 中线是Dec.2014底通水
# 总的话，可以2014作为之前之后的分界。
# 分东中的话，东线是2013年，中线是2014年。

library(tidyverse)
library(ranger)

kfoldSplit <- function(x, k=10, train=TRUE){
    # Randomly splits indices into k folds for cross-validation.  
    # Returns a list with each component containing train (or test) indices
    
    # @x: a numeric vector of indices;
    # @k: number of folds; defaults to 10;
    # @train: TRUE for training indices; FALSE for testing
    
    x <- sample(x, size = length(x), replace = FALSE)
    out <- suppressWarnings(split(x, factor(1:k)))
    if (train) {
        out <- lapply(out, FUN = function(x, len) (1:len)[-x], len = length(unlist(out)))
    }
    return(out)
}
# use example
# kfolds <- kfoldSplit(1:nrow(data), k = 10, train = TRUE)


## --------------------------------------------------------------------------- ##
data <- read_csv("data/eastern_line.csv")
data
# No missing values
is.na(data) %>% colSums()

data_group <- data %>% group_by(lat, lon)
groups <- data_group %>% group_split()
# Number of locations: N=3723
length(groups)
groups[[1]] %>% 
    column_to_rownames(var="year") %>% 
    t() %>% 
    view()
# Number of years: T=11
data$year %>% n_distinct()
# Time period: 2010-2020
data$year %>% unique()

long_name <- colnames(data)[c(-1:-3, -ncol(data))]
long_name
short_name <- c("sensible_heat_flux", "humidity", "radiation", "snow_depth", "rad_temp", "soil_temp_40",
  "snow_equiv", "snowfall", "precip", "subsurface_runoff", "soil_moisture", "water_stress",
  "land_use", "spei", "population", "sc_pdsi", "air_temp", "evapo", 
  "soil_temp_10", "net_radiation", "pdsi", "latent_heat_flux", "wind_speed", "soild_heat_flux",
  "surface_runoff", "soil_moisture_10", "snow_cover", "night_light")
variable_name <- cbind(long_name, short_name) %>% data.frame()
variable_name

colnames(data)[c(-1:-3, -ncol(data))] <- short_name
colnames(data)

data_1yr <- data %>% filter(year==2010)
data_1yr %>% 
    select(year, lat, lon, Water_receive, everything()) %>% 
    view()

data_1yr %>% count(Water_receive)
# Water_receive     n
#             0  3143
#             1   580 
data_1yr %>% count(Water_receive) %>% as.matrix() %>% prop.table(margin=2)
# Water_receive         n
#             0  0.8442117
#             1  0.1557883
# Note that 85% of the locations are False; 15% are TRUE.

## ========================================================================== ##
## Random Forest ---------------------------------------------------------------
formula <- as.formula(
    paste("Water_receive", 
          paste(short_name, collapse = " + "), 
          sep = " ~ "))

set.seed(123)
kfolds <- kfoldSplit(1:nrow(data_1yr), k = 10, train = TRUE)
kfolds %>% str()

i <- 1
idx <- kfolds[[i]]
RF_ranger <- ranger(formula = formula, 
                    data = data_1yr[idx,], 
                    probability = T,
                    importance = "permutation", 
                    scale.permutation.importance = TRUE,
                    )
print(RF_ranger)

rf.pred.test <- predict(RF_ranger, data=data_1yr[-idx,])$predictions
rf.pred.test %>% str()
rf.pred.test %>% head(5)
rf.class.test <- max.col(rf.pred.test) - 1
rf.class.test %>% table()

obs.test <- data_1yr[-idx,] %>% pull(Water_receive)

confusion_matrix <- table(rf.class.test, obs.test)
confusion_matrix
#                 obs.test
# rf.class.test   0   1
#             0 311  17
#             1   5  40
TN <- confusion_matrix[1,1]
FN <- confusion_matrix[1,2]
TP <- confusion_matrix[2,2]
FP <- confusion_matrix[2,1]
accuracy <- (TP+TN)/sum(confusion_matrix)
recall <- TP/(TP+FN)
precision <- TP/(TP+FP)
F1 <- 2*precision*recall / (precision+recall)
F1

# False Negative is high
c("accuracy"=accuracy, "recall"=recall,
  "precision"=precision, "F1"=F1)
# accuracy    recall precision        F1 
# 0.9410188 0.7017544 0.8888889 0.7843137 

mosaicplot(t(confusion_matrix),
           xlab="Observation", ylab="Prediction", 
           main="", cex.axis = 1.2)


# Deal with imbalance ----------------------------------------------------------
# sample.fraction = c(0.5, 0.5)
RF_ranger <- ranger(formula = formula, 
                    data = data_1yr[idx,], 
                    probability = T,
                    sample.fraction = c(0.5, 0.5), 
                    importance = "permutation", 
                    scale.permutation.importance = TRUE,
)
# class.weights, cost sensitive learning
RF_ranger <- ranger(formula = formula, 
                    data = data_1yr[idx,], 
                    probability = T,
                    importance = "permutation", 
                    scale.permutation.importance = TRUE,
)
print(RF_ranger)

rf.pred.test <- predict(RF_ranger, data=data_1yr[-idx,])$predictions
rf.class.test <- max.col(rf.pred.test) - 1
rf.class.test %>% table()

obs.test <- data_1yr[-idx,] %>% pull(Water_receive)

confusion_matrix <- table(rf.class.test, obs.test)
confusion_matrix
#                 obs.test
# rf.class.test   0   1
#             0 311  17
#             1   5  40
TN <- confusion_matrix[1,1]
FN <- confusion_matrix[1,2]
TP <- confusion_matrix[2,2]
FP <- confusion_matrix[2,1]
accuracy <- (TP+TN)/sum(confusion_matrix)
recall <- TP/(TP+FN)
precision <- TP/(TP+FP)
F1 <- 2*precision*recall / (precision+recall)
F1

# False Negative is high
c("accuracy"=accuracy, "recall"=recall,
  "precision"=precision, "F1"=F1)
# accuracy    recall precision        F1 
# 0.9329759 0.6140351 0.9210526 0.7368421 

mosaicplot(t(confusion_matrix),
           xlab="Observation", ylab="Prediction", 
           main="", cex.axis = 1.2)

# Increase threshold to minimize FN --------------------------------------------
rf.pred.test %>% head(5)
rf.pred.test %>% 
    as_tibble() %>% 
    filter(V1<V2)

(rf.pred.test[,2]>0.55) %>% table()

rf.class.test <- max.col(rf.pred.test) - 1
rf.class.test %>% table()

obs.test %>% table()







