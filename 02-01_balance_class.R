# Loop through all groups, run RF with re-balanced classes.
# Continue with 01_predict_water-receive.R

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

# short_name defined in 01_predict_water-receive.R
colnames(data)[c(-1:-3, -ncol(data))] <- short_name
colnames(data)

data_before <- data %>% filter(year <= 2014) # all and central
# data_before <- data %>% filter(year <= 2012) # eastern

## Check Water_receive 0-1 distribution
data_before %>% 
    distinct(lat, lon, .keep_all = TRUE) %>% 
    count(Water_receive) %>% 
    as.matrix() %>% 
    prop.table(margin=2)

set.seed(123)
kfolds <- kfoldSplit(1:nrow(data_before), k = 10, train = TRUE)
## ========================================================================== ##
## RF prediction ---------------------------------------------------------------
# Initialize model output containers
prediction_df <- matrix(nrow=0, ncol=7)
confusion_matrix_all <- array(numeric(), dim = c(2,2,0))
performance_df <- matrix(nrow=0, ncol=4)
varImp_df <- tibble(name=short_name)
i <- 2
for (i in 1:10){
    # 10-fold cross validation
    print (i)
    idx <- kfolds[[i]]
    
    ## Assign weights to classes
    weights <- rep(0, nrow(data_before[idx,]))
    w <- data_before[idx, "Water_receive"] %>% table()
    w <- 1/w
    w <- w/(sum(w))
    weights[data_before[idx, "Water_receive", drop=TRUE] %>% as.logical()] <- w[2]
    weights[!data_before[idx, "Water_receive", drop=TRUE]] <- w[1]
    print (weights %>% table())
    
    ## Run RF
    RF_ranger <- ranger(formula = formula, 
                        data = data_before[idx,], 
                        probability = TRUE,
                        mtry = 9,
                        num.trees = 200,
                        min.node.size = 10,
                        keep.inbag = TRUE, 
                        case.weights = weights,
                        importance = "permutation", 
                        scale.permutation.importance = TRUE,
                        )
    # print(RF_ranger)
    
    # check sample distribution, should be balanced
    inbag <- do.call(cbind, RF_ranger$inbag.counts)
    inbag[data_before[idx, "Water_receive", drop=TRUE] %>% as.logical(), ] %>% colSums()
    inbag[!data_before[idx, "Water_receive", drop=TRUE], ] %>% colSums()
    
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
f_name <- sprintf("output/prediction_%s_rebalance.csv", area)
f_name
write_csv(prediction_df, f_name)

confusion_matrix_all
confusion_ftable <- ftable(confusion_matrix_all)
cont <- confusion_ftable %>% format(method="col.compact", quote = FALSE)
f_name <- sprintf("output/confusion_table_%s_rebalance.csv", area)
f_name
write.table(cont, sep = ",", file = f_name,
            row.names = FALSE, col.names = FALSE)

rownames(performance_df) <- paste0("G", 1:10)
performance_df <- performance_df %>% as_tibble(rownames="Group")
f_name <- sprintf("performance/performance_df_%s_rebalance.csv", area)
f_name
write_csv(as.data.frame(performance_df), f_name)

colnames(varImp_df)[-1] <- paste0("G", 1:10)
f_name <- sprintf("performance/varImp_df_%s_rebalance.csv", area)
f_name
write_csv(varImp_df, f_name)


## ========================================================================== ##
## Variable importance ---------------------------------------------------------
f_name <- sprintf("performance/varImp_df_%s_rebalance.csv", area)
f_name
varImp_df <- read.table(f_name, row.names = 1, sep = ",", header = TRUE)
varImp_df
#### Visualization -------------------------------------------------------------
p_list <- list()
i <- 1
for (i in 1:10){
    plot_data <- varImp_df[, i, drop=FALSE] %>% 
        arrange(.[1]) %>% 
        as_tibble(rownames = "name") %>% 
        mutate(name=factor(name, levels=name))
    colnames(plot_data)[2] <- "value"
    plot_data
    p <- ggplot(plot_data, aes(name, value)) +
        geom_point() +
        coord_flip() +
        labs(y="Vaiable importance", title=sprintf("Group %s", i)) +
        theme(axis.text.y = element_text(size=rel(1.2), face = "bold"),
              axis.title.y = element_blank(),
              )
    p_list[[i]] <- p    
}
length(p_list)
p_all <- plot_grid(plotlist = p_list[1:9], ncol = 3)
p_all
f_name <- sprintf("image/varImp_%s_rebalance.png", area)
f_name
plot_png(p_all, f_name,  21.5, 13.5)

#### Rank table: show names ----------------------------------------------------
index_df <- varImp_df %>% 
    lapply(sort.int, index.return = TRUE) %>% 
    map(2) %>% 
    data.frame()

name_df <- lapply(1:10, function(col) rownames(varImp_df)[index_df[,col]]) %>% 
    do.call(cbind, .)
name_df
colnames(name_df) <- paste0("G", 1:10)
f_name <- sprintf("performance/varImp_name_%s_rebalance.csv", area)
f_name
write.csv(name_df, f_name)


## ========================================================================== ##
## Visualize Confusion Matrix --------------------------------------------------
# load confusion table
f_name <- sprintf("output/confusion_table_%s_rebalance.csv", area)
f_name
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
f_name <- sprintf("image/mosaic_%s_rebalance.png", area)
f_name
ppi <- 300
png(f_name, width=12.9*ppi, height=9.19*ppi, res=ppi)
par(mfrow=c(3,3))
par(cex.lab=1.5, cex.main=1.5)
i <- 1
repeat {
    plot_data <- confusion_ftable[,,i]
    mosaicplot(t(plot_data),
               xlab="Observation", ylab="Prediction",
               main=sprintf("Group %s", i), 
               cex.axis = 1.5)
    i <- i+1
    if (i==10) break
}
dev.off()

# par(mfrow=c(1,1))

