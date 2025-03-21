## Predict after operation using model trained on before operation


## Load data -------------------------------------------------------------------
area <- "all"
area <- "eastern"
area <- "central"

if (area=="all"){
    print ("Eastern and Central line combined.")
    eastern <- read_csv("data/eastern_line.csv")
    central <- read_csv("data/central_line.csv")
    data <- bind_rows(eastern, central)
} else {
    f_name <- sprintf("data/%s_line.csv", area)
    print (f_name)
    data <- read_csv(f_name)
}
data
nrow(data)
data$year %>% unique()

# predictors
short_name <- c("sensible_heat_flux", "humidity", "radiation", "snow_depth", "rad_temp",
                "soil_temp_40", "snow_equiv", "snowfall", "precip", "subsurface_runoff",
                "soil_moisture", "water_stress", "land_use", "spei", "population", 
                "sc_pdsi", "air_temp", "evapo",  "soil_temp_10", "net_radiation", 
                "pdsi", "latent_heat_flux", "wind_speed", "soild_heat_flux",  "surface_runoff",
                "soil_moisture_10", "snow_cover", "night_light")
colnames(data)[c(-1:-3, -ncol(data))] <- short_name
colnames(data)

# data_before <- data %>% filter(year <= 2014) # all and central
data_before <- data %>% filter(year== 2013) # eastern
data_after <- data %>% filter(year==2013)

cast <- rbinom(n = 3723, size = 1, prob = c(.50))
cast <- cast %>% as.logical()
cast
sum(cast)
data_before <- data %>% filter(year== 2013) %>% subset(cast)
data_after <- data %>% filter(year==2013) %>% subset(!cast)

data_before$year %>% unique()
data_before
data_after$year %>% unique()
data_after

formula <- as.formula(
    paste("Water_receive", 
          paste(short_name, collapse = " + "), 
          sep = " ~ "))

## rebalance classes
weights <- rep(0, nrow(data_before))
w <- data_before[, "Water_receive"] %>% table()
w <- 1/w
w <- w/(sum(w))
# apply larger weight to smaller sample
weights[data_before[, "Water_receive", drop=TRUE] %>% as.logical()] <- w[2]
weights[!data_before[, "Water_receive", drop=TRUE]] <- w[1]
weights %>% table()

RF_ranger <- ranger(formula = formula, 
                    data = data_before, 
                    probability = TRUE,
                    mtry = 9,
                    num.trees = 200,
                    min.node.size = 10,
                    keep.inbag = TRUE, 
                    case.weights = weights,
                    importance = "permutation", 
                    scale.permutation.importance = TRUE,
                    )
# check sample distribution
inbag <- do.call(cbind, RF_ranger$inbag.counts)
inbag[data_before[, "Water_receive", drop=TRUE] %>% as.logical(), ] %>% colSums()
inbag[!data_before[, "Water_receive", drop=TRUE], ] %>% colSums()

# print(RF_ranger)

## Variable importance 
# varImp <- RF_ranger$variable.importance %>% 
#     sort(decreasing = TRUE) %>% 
#     enframe()


# rf.pred.test <- predict(RF_ranger, data=data_before)$predictions
rf.pred.test <- predict(RF_ranger, data=data_after)$predictions

colnames(rf.pred.test) <- c("class0", "class1")
print (rf.pred.test %>% head(5))

rf.class.test <- max.col(rf.pred.test) - 1
rf.class.test %>% table()


obs.test <- data_before %>% pull(Water_receive)
prediction_after <- data_before[, c("year", "lat", "lon")] %>% 
    bind_cols(rf.pred.test,                         # predict: probability
              tibble("Prediction" = rf.class.test), # predict: class
              data_before[, "Water_receive"],        # observation
    )

obs.test <- data_after %>% pull(Water_receive)
prediction_after <- data_after[, c("year", "lat", "lon")] %>% 
    bind_cols(rf.pred.test,                         # predict: probability
              tibble("Prediction" = rf.class.test), # predict: class
              data_after[, "Water_receive"],        # observation
              )
# overall performance
with(prediction_after, get_performance(Prediction, Water_receive))

## performance by year
prediction_group <- prediction_after %>% group_by(year)
prediction_group %>% tally()
groups <- prediction_group %>% group_split()

the_group <- groups[[1]]
the_group
with(the_group, get_performance(Prediction, Water_receive))

get_performance <- function(prediction, observation){
    ## Confusion table performance metrics
    # @prediction: predicted 0-1 class 
    # @observation: observed 0-1 class
    confusion_matrix <- table(prediction, observation)
    confusion_matrix
    #                 observation
    # prediction      0      1
    #             0  21710   3801
    #             1    291    259
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
    # print (performance_metric)
    return (list(confusion_matrix, performance_metric))
}




















