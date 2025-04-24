## Predict after operation using model trained on before operation
library(ranger)
library(tidyverse)
library(knitr)
library(flextable) # confusion table
library(officer)

# Load data --------------------------------------------------------------------
area <- "all"
area <- "eastern"
area <- "central"

f_name <- sprintf("data/center_at_mean/%s_line.csv", area)
print (f_name)
data <- read_csv(f_name)

data
nrow(data)
data$year %>% unique()

## predictors
short_name <- c("sensible_heat_flux", "humidity", "radiation", "snow_depth", 
                "rad_temp", "soil_temp_40", "snow_equiv", "snowfall", "precip",
                "subsurface_runoff", "soil_moisture", "water_stress", 
                "land_use", "spei", "population", "sc_pdsi", "air_temp", 
                "evapo",  "soil_temp_10", "net_radiation", "pdsi",
                "latent_heat_flux", "wind_speed", "soild_heat_flux", 
                "surface_runoff", "soil_moisture_10", "snow_cover", "night_light"
                )
colnames(data)[c(-1:-3, -ncol(data))] <- short_name
colnames(data)



## Same period ----
# random sample to train and test
data_before <- data %>% filter(year==2013) # eastern

cast <- rbinom(n = 3723, size = 1, prob = c(.50))
cast <- cast %>% as.logical()
cast
sum(cast)
data_before <- data %>% filter(year== 2013) %>% subset(cast)
data_after <- data %>% filter(year==2013) %>% subset(!cast)

## Before/after period ----
# before operation: train; after: test;
data_before <- data %>% filter(year <= 2014) # all and central
data_after <- data %>% filter(year>2014)

data_before <- data %>% filter(year<=2013) # eastern
data_after <- data %>% filter(year>2013)

data_before$year %>% unique()
data_after$year %>% unique()

# Model setup ------------------------------------------------------------------
formula <- as.formula(
    paste("Water_receive", 
          paste(short_name, collapse = " + "), 
          sep = " ~ "))

## rebalance classes
weights <- rep(0, nrow(data_before))
w <- data_before[, "Water_receive"] %>% table()
w <- 1/w
w <- w/(sum(w))
# apply larger weight to smaller sample size
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

# Model prediction -------------------------------------------------------------

# rf.pred.test <- predict(RF_ranger, data=data_before)$predictions
rf.pred.test <- predict(RF_ranger, data=data_after)$predictions

colnames(rf.pred.test) <- c("class0", "class1")
print (rf.pred.test %>% head(5))

threshold <- 0.77
# threshold <- 0.5
rf.class.test <- ifelse(rf.pred.test[,"class0"]>threshold, 0, 1)
rf.class.test %>% table()

## same period
obs.test <- data_before %>% pull(Water_receive)
prediction_after <- data_before[, c("year", "lat", "lon")] %>% 
    bind_cols(rf.pred.test,                         # predict: probability
              tibble("Prediction" = rf.class.test), # predict: class
              data_before[, "Water_receive"],        # observation
              )

## divided period
obs.test <- data_after %>% pull(Water_receive)
prediction_after <- data_after[, c("year", "lat", "lon")] %>% 
    bind_cols(rf.pred.test,                         # predict: probability
              tibble("Prediction" = rf.class.test), # predict: class
              data_after[, "Water_receive"],        # observation
              )
## overall performance ----
with(prediction_after, get_performance(Prediction, Water_receive))
# accuracy    recall precision        F1 
# 0.6916082 0.4625616 0.2428553 0.3184940 

prediction_after %>% filter(Water_receive==1) %>% view()
f_name <- "output/prediction_after_summary.csv"
write_csv(prediction_after %>% 
              group_by(lat, lon) %>% 
              summarize(class0=mean(class0),
                        class1=mean(class1),
                        Prediction=sum(Prediction), 
                        Water_receive=Water_receive[1],
              ), f_name)

# predict 1 if there is one year predicted 1
# helps marginally
prediction_filter <- prediction_after %>% 
    group_by(lat, lon) %>% 
    summarize(class0=mean(class0),
        class1=mean(class1),
        Prediction=sum(Prediction), 
        Water_receive=Water_receive[1],
        )
prediction_filter <- prediction_filter %>% 
    mutate(Prediction = ifelse(Prediction==0, 0, 1))
with(prediction_filter, get_performance(Prediction, Water_receive))
# accuracy    recall precision        F1 
# 0.8310502 0.2741379 0.4332425 0.3357973

## tuning threshold ----
tuning_performance <- NULL
tuning_performance_filter <- NULL
for (threshold in seq(0.5, 0.9, by=0.01)){
    print (threshold)
    rf.class.test <- ifelse(rf.pred.test[,"class0"]>threshold, 0, 1)
    rf.class.test %>% table()
    obs.test <- data_after %>% pull(Water_receive)
    prediction_after <- data_after[, c("year", "lat", "lon")] %>% 
        bind_cols(rf.pred.test,                         # predict: probability
                  tibble("Prediction" = rf.class.test), # predict: class
                  data_after[, "Water_receive"],        # observation
        )
    result <- with(prediction_after, get_performance(Prediction, Water_receive)[[2]])
    tuning_performance <- bind_rows(tuning_performance, c("threshold" = threshold, result))
    print (result)
    
    # predict 1 if there is one year predicted 1
    prediction_filter <- prediction_after %>% 
        group_by(lat, lon) %>% 
        summarize(class0=mean(class0),
                  class1=mean(class1),
                  Prediction=sum(Prediction), 
                  Water_receive=Water_receive[1],
                  )
    prediction_filter <- prediction_filter %>% 
        mutate(Prediction = ifelse(Prediction>2, 1, 0))
    result <- with(prediction_filter, get_performance(Prediction, Water_receive)[[2]])
    tuning_performance_filter <- bind_rows(tuning_performance_filter, c("threshold" = threshold, result))
    print (result)
}

tuning_performance
tuning_performance %>% arrange(desc(F1))
# set threshold to max F1
threshold <- 0.5
rf.class.test <- ifelse(rf.pred.test[,"class0"]>threshold, 0, 1)
obs.test <- data_after %>% pull(Water_receive)
prediction_after <- data_after[, c("year", "lat", "lon")] %>% 
    bind_cols(rf.pred.test,                         # predict: probability
              tibble("Prediction" = rf.class.test), # predict: class
              data_after[, "Water_receive"],        # observation
    )
## overall performance ----
with(prediction_after, get_performance(Prediction, Water_receive))
# accuracy    recall precision        F1 
# 0.7878823 0.5810345 0.3813450 0.4604724 

p <- tuning_performance %>% 
    gather(key = "key", value = "value", -threshold) %>% 
    mutate(key = factor(key, levels=c("accuracy", "recall", "precision", "F1"))) %>% 
    ggplot(aes(threshold, value)) +
    geom_line() +
    facet_wrap(~key, ncol=1, scales="free") +
    labs(x="Probability threshold") +
    theme(axis.title.y = element_blank())
p
f_name <- "image/tuning_threshold_center.png"
# plot_png(p, f_name, 10.7, 11)

tuning_performance_filter %>% 
    gather(key = "key", value = "value", -threshold) %>% 
    mutate(key = factor(key, levels=c("accuracy", "recall", "precision", "F1"))) %>% 
    ggplot(aes(threshold, value)) +
    geom_line() +
    facet_wrap(~key, ncol=1, scales="free") +
    labs(x="Probability threshold") +
    theme(axis.title.y = element_blank())

## performance by year ----
prediction_group <- prediction_after %>% group_by(year)
prediction_group %>% tally()
groups <- prediction_group %>% group_split()

the_group <- groups[[1]]
the_group
with(the_group, get_performance(Prediction, Water_receive))

performance_per_year <- list()
for (i in 1:length(groups)){
    the_group <- groups[[i]]
    performance_per_year[[i]] <- with(the_group, get_performance(Prediction, Water_receive))
}
performance_per_year[[1]]

yr <- 2
map(performance_per_year, 1)[[yr]] %>% 
    as_flextable() %>% 
    set_caption(
        as_paragraph(
            as_chunk(sprintf("Year: %s", seq(2014, 2020)[yr]), 
                     props = fp_text(bold = TRUE,
                                     font.family = "Helvetica")
                     )
        )
    )
confusion_matrix_all <- array(as.numeric(unlist(map(performance_per_year, 1))),
                              dim=c(2, 2, 7))
confusion_ftable <- ftable(confusion_matrix_all)
attributes(confusion_ftable)
attr(confusion_ftable, "row.vars") <- list(c(0,1),c(0,1))
attr(confusion_ftable, "col.vars") <- list(seq(2014,2020))
cont <- confusion_ftable %>% format(method="col.compact", quote = FALSE)
f_name <- sprintf("output/confusion_table_%s_prediction_center_p%s.csv", area, threshold)
f_name
write.table(cont, sep = ",", file = f_name,
            row.names = FALSE, col.names = FALSE)


metric_per_year <- map(performance_per_year, 2) %>% 
    bind_rows() %>% 
    add_column(year = 2014:2020,
               .before = 1)
kable(metric_per_year,
      format = "pipe",
      digits = 4, align = "l")










