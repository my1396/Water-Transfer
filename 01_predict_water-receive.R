# Predict water receive
# 东线是12年通水的； 中线是Dec.2014底通水
# 总的话，可以2014作为之前之后的分界。
# 分东中的话，
#   - before: 东线是 ≤ 2012年，
#   - before: 中线是 ≤ 2014年。

# Random Forest baseline model

library(tidyverse)
library(ranger)
library(cowplot)
library(abind) # combine 3d array
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
## 1. Load Data ----------------------------------------------------------------
# 1.1 Central and eastern line collectively
eastern <- read_csv("data/eastern_line.csv")
central <- read_csv("data/central_line.csv")
data <- bind_rows(eastern, central)
nrow(data)

# 1.2 Load eastern or central individually
area <- "eastern"
# area <- "central"
f_name <- sprintf("data/%s_line.csv", area)
data <- read_csv(f_name)
data

# time period: 2010-2020 (T=11 years)
data$year %>% unique()

# Number of missing values per col
is.na(data) %>% colSums()

# Total number of locations: 
#   N = 3723 (Eastern)
#   N = 3893 (Central)
#   N = 7616 (Eastern + Central)
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

# data_before <- data %>% filter(year <= 2014) # all and central
data_before <- data %>% filter(year <= 2012) # eastern
data_before %>% 
    select(year, lat, lon, Water_receive, everything()) %>% 
    view()

## Check Water_receive 0-1 distribution
data_before %>% 
    distinct(lat, lon, .keep_all = TRUE) %>% 
    count(Water_receive)
# Eastern
# Water_receive     n
#             0  3143
#             1   580 

## Check Water_receive 0-1 proportion
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
## 2. Random Forest ------------------------------------------------------------
formula <- as.formula(
    paste("Water_receive", 
          paste(short_name, collapse = " + "), 
          sep = " ~ "))

set.seed(123)
kfolds <- kfoldSplit(1:nrow(data_before), k = 10, train = TRUE)
kfolds %>% str()

i <- 1
# Initialize model output containers
prediction_df <- matrix(nrow=0, ncol=7)
confusion_matrix_all <- array(numeric(), dim = c(2,2,0))
performance_df <- matrix(nrow=0, ncol=4)
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

    rf.class.test <- max.col(rf.pred.test) - 1
    rf.class.test %>% table()
    obs.test <- data_before[-idx,] %>% pull(Water_receive)
    
    ## Merge predictions
    the_prediction <- data_before[-idx, c("lat", "lon")] %>% 
        bind_cols(rf.pred.test, # predict: probability
                  tibble("Prediction" = rf.class.test), # predict: class
                  data_before[-idx, "Water_receive"], # observation
                  tibble("Group" = sprintf("G%s", i) ),
                  )
    prediction_df <- rbind(prediction_df, the_prediction)
    
    confusion_matrix <- table(rf.class.test, obs.test)
    confusion_matrix
    confusion_matrix_all <- confusion_matrix_all %>% 
        abind(confusion_matrix, along=3)
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
    performance_df <- rbind(performance_df, performance_metric)
    # accuracy    recall  precision        F1 
    # 0.9410188 0.7017544 0.8888889 0.7843137 
    
    ## Variable importance 
    varImp <- RF_ranger$variable.importance %>% 
        sort(decreasing = TRUE) %>% 
        enframe()
    varImp_df <- varImp_df %>% left_join(varImp, by="name")
} # End 10-fold CV

prediction_df
f_name <- sprintf("output/prediction_%s.csv", area)
write_csv(prediction_df, f_name)

confusion_matrix_all
confusion_ftable <- ftable(confusion_matrix_all)
cont <- confusion_ftable %>% format(method="col.compact", quote = FALSE)
f_name <- sprintf("output/confusion_table_%s.csv", area)
write.table(cont, sep = ",", file = f_name,
            row.names = FALSE, col.names = FALSE)

rownames(performance_df) <- paste0("G", 1:10)
performance_df <- performance_df %>% as_tibble(rownames="Group")
f_name <- sprintf("performance/performance_df_%s.csv", area)
write_csv(as.data.frame(performance_df), f_name)

colnames(varImp_df)[-1] <- paste0("G", 1:10)
f_name <- sprintf("performance/varImp_df_%s.csv", area)
write_csv(varImp_df, f_name)


## ========================================================================== ##
## Variable importance ---------------------------------------------------------
f_name <- "performance/varImp_df_eastern.csv"
varImp_df <- read_csv(f_name)
#### Visualization -------------------------------------------------------------
p_list <- list()
for (i in 1:10){
    plot_data <- varImp_df[, i, drop=FALSE] %>% 
        arrange(desc(.[1])) %>% 
        as_tibble(rownames = "name") %>% 
        mutate(name=factor(name, levels=name))
    colnames(plot_data)[2] <- "value"
    plot_data
    p <- ggplot(plot_data, aes(name, value)) +
        geom_col() +
        labs(y="Vaiable importance", title=sprintf("Group %s", i)) +
        theme(axis.text.x = element_text(size=rel(1.2), angle=90, hjust=1, face = "bold"),
              axis.title.x = element_blank(),
        )
    p_list[[i]] <- p    
}
length(p_list)
p_all <- plot_grid(plotlist = p_list[1:9], ncol = 3)
p_all
f_name <- "image/varImp_eastern.png"
# plot_png(p_all, f_name,  27.7, 13.4)

#### Rank table: show names ----------------------------------------------------
index_df <- varImp_df[,-1] %>% 
    lapply(sort.int, index.return = TRUE) %>% 
    map(2) %>% 
    data.frame()

name_df <- lapply(1:10, function(col) rownames(varImp_df)[index_df[,col]]) %>% 
    do.call(cbind, .)
name_df
colnames(name_df) <- paste0("G", 1:10)
f_name <- "performance/varImp_name.csv"
# write.csv(name_df, f_name)


## ========================================================================== ##
## Visualize Confusion Matrix --------------------------------------------------
# load confusion table
f_name <- sprintf("output/confusion_table_%s.csv", area)
confusion_ftable <- read.table(f_name, sep=",", skip = 2)
confusion_ftable <- array(confusion_ftable[,3:12] %>% unlist(), 
                          dim = c(2,2,10) ) %>% 
    aperm(perm=c(2,1,3))
dimnames(confusion_ftable) <- list(rf.class.test = c(0, 1),
                                   obs.test = c(0,1),
                                   Group = paste0("G",1:10))
confusion_ftable
# verify the loading is correct
# confusion_matrix

# start plotting
x11()
f_name <- sprintf("image/mosaic_%s.png", area)
ppi <- 300
# png(f_name, width=12.9*ppi, height=9.19*ppi, res=ppi)
par(mfrow=c(3,3))
i <- 1
repeat {
    plot_data <- confusion_ftable[,,i]
    mosaicplot(t(plot_data),
               xlab="Observation", ylab="Prediction",
               main=sprintf("Group %s", i), cex.axis = 1.2 )
    i <- i+1
    if (i==10) break
}
dev.off()

# par(mfrow=c(1,1))






