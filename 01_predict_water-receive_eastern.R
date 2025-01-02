# Predict water receive
# 东线是12年通水的； 中线是Dec.2014底通水
# 总的话，可以2014作为之前之后的分界。
# 分东中的话，
#   - before: 东线是 ≤ 2012年，
#   - before: 中线是 ≤ 2014年。

# Random Forest baseline model

library(tidyverse)
library(ranger)
source("fun_script_water.R")

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

## -------------------------------------------------------------------------- ##

# Central and eastern line collectively
eastern <- read_csv("data/eastern_line.csv")
central <- read_csv("data/central_line.csv")

data <- bind_rows(eastern, central)
nrow(data)

# Load eastern or central individually
# data <- read_csv("data/eastern_line.csv")
data <- read_csv("data/central_line.csv") # central line has missing values
data

# time period: 2010-2020 (T=11 years)
data$year %>% unique()

# Number of missing values per col
is.na(data) %>% colSums()

# Total number of locations: 
#   N = 3723 (eastern)
#   N = 3893 (central)
#   N = 7616 (eastern + central)
data_group <- data %>% group_by(lat, lon)
groups <- data_group %>% group_split()
length(groups)
# data for one location
groups[[1]] %>% 
    column_to_rownames(var="year") %>% 
    t() %>% 
    view()

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

data_before <- data %>% filter(year <= 2014) # all and central
# data_before <- data %>% filter(year <= 2012) # eastern
data_before %>% 
    select(year, lat, lon, Water_receive, everything()) %>% 
    view()

data_before %>% 
    distinct(lat, lon, .keep_all = TRUE) %>% 
    count(Water_receive)
# Eastern
# Water_receive     n
#             0  3143
#             1   580 
data_before %>% 
    distinct(lat, lon, .keep_all = TRUE) %>% 
    count(Water_receive) %>% 
    as.matrix() %>% 
    prop.table(margin=2)
# Eastern
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
kfolds <- kfoldSplit(1:nrow(data_before), k = 10, train = TRUE)
kfolds %>% str()

i <- 1
performance_df <- matrix(nrow=4, ncol=0)
varImp_df <- tibble(name=short_name)
for (i in 1:10){
    # 10-fold cross validation
    print (i)
    idx <- kfolds[[i]]
    RF_ranger <- ranger(formula = formula, 
                        data = data_before[idx,], 
                        probability = T,
                        importance = "permutation", 
                        scale.permutation.importance = TRUE,
    )
    # print(RF_ranger)
    
    rf.pred.test <- predict(RF_ranger, data=data_before[-idx,])$predictions
    colnames(rf.pred.test) <- c("class0", "class1")
    print (rf.pred.test %>% head(5))
    # save predictions
    f_name <- sprintf("ouput/prediction_porbability_G%s_central.csv", i)
    write_csv(data_before[-idx, c("lat", "lon")] %>% bind_cols(rf.pred.test), f_name)
    rf.class.test <- max.col(rf.pred.test) - 1
    rf.class.test %>% table()
    
    obs.test <- data_before[-idx,] %>% pull(Water_receive)
    
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
    
    # False Negative is high
    performance_metric <- c("accuracy" = accuracy, 
                           "recall" = recall,
                           "precision" = precision, 
                           "F1" = F1) 
    print (performance_metric)
    performance_df <- cbind(performance_df, performance_metric)
    # accuracy    recall  precision        F1 
    # 0.9410188 0.7017544 0.8888889 0.7843137 
    
    f_name <- sprintf("image/mosaic_G%s_central.png", i)
    ppi <- 300
    png(f_name, width=8.48*ppi, height=7.18*ppi, res=ppi)
    mosaicplot(t(confusion_matrix),
               xlab="Observation", ylab="Prediction", 
               main=sprintf("Group %s", i), cex.axis = 1.2)
    dev.off()
    
    # Variable importance ------------------------------------------------------
    varImp <- RF_ranger$variable.importance %>% 
        sort(decreasing = TRUE) %>% 
        enframe()
    varImp_df <- varImp_df %>% left_join(varImp, by="name")
    plot_data <- varImp
    plot_data <- plot_data %>% mutate(name=factor(name, levels=name))
    plot_data$name %>% str()
    plot_data <- plot_data %>% mutate(sub=rep(1:2, each=14))
    p <- ggplot(plot_data, aes(name, value)) +
        geom_col() +
        labs(y="Vaiable importance", title=sprintf("Group %s", i)) +
        theme(axis.text.x = element_text(size=rel(1.2), angle=90, hjust=1),
              axis.title.x = element_blank(),
        )
    p
    f_name <- sprintf("image/varImp_G%s_central.png", i)
    plot_png(p, f_name, 13.6, 7.07)
    
}

colnames(performance_df) <- paste0("G", 1:10)
f_name <- "performance/performance_df_central.csv"
write.csv(as.data.frame(performance_df), f_name)

varImp_df <- data.frame(varImp_df, row.names = "name")
colnames(varImp_df) <- paste0("G", 1:10)
f_name <- "performance/varImp_df_central.csv"
write.csv(varImp_df, f_name)


## ========================================================================== ##
# Variable ranking
f_name <- "performance/varImp_df.csv"
varImp_df <- read.csv(f_name, row.names = 1)
index_df <- varImp_df %>% 
    lapply(sort.int, index.return = TRUE) %>% 
    map(2) %>% 
    data.frame()

name_df <- lapply(1:10, function(col) rownames(varImp_df)[index_df[,col]]) %>% 
    do.call(cbind, .)
name_df
colnames(name_df) <- paste0("G", 1:10)
f_name <- "performance/varImp_name.csv"
write.csv(name_df, f_name)




