# Issue: Recall is low
# Trial: 
#   1. data bootstrap
#   2. improve threshold for classification

## Continue 01_predict_water-receive.R
# Deal with imbalance ----------------------------------------------------------
# sample.fraction = c(0.5, 0.5)

i <- 8
idx <- kfolds[[i]]

weights <- rep(0, nrow(data_before[idx,]))
weights[data_before[idx, "Water_receive", drop=TRUE] %>% as.logical()] <- 0.9
weights[!data_before[idx, "Water_receive", drop=TRUE]] <- 0.1
weights %>% table()

RF_ranger <- ranger(formula = formula, 
                    data = data_before[idx,], 
                    probability = TRUE,
                    num.trees = 200,
                    keep.inbag = TRUE, 
                    case.weights = weights,
                    importance = "permutation", 
                    scale.permutation.importance = TRUE,
                    )
inbag <- do.call(cbind, RF_ranger$inbag.counts)
inbag %>% str()
inbag[,1] %>% table()
inbag[,1] %>% table() %>% sum()

data_before[idx, "Water_receive", drop=TRUE] %>% as.logical()
inbag[data_before[idx, "Water_receive", drop=TRUE] %>% as.logical(), ] %>% colSums()
inbag[!data_before[idx, "Water_receive", drop=TRUE], ] %>% colSums()


# class.weights, cost sensitive learning
RF_ranger <- ranger(formula = formula, 
                    data = data_before[idx,], 
                    probability = TRUE,
                    importance = "permutation",
                    mtry = 9,
                    num.trees = 200,
                    min.node.size = 10,
                    scale.permutation.importance = TRUE,
                    )
print(RF_ranger)

rf.pred.test <- predict(RF_ranger, data=data_before[-idx,])$predictions
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
c("accuracy"=accuracy, "recall"=recall,
  "precision"=precision, "F1"=F1)
# Eastern
# accuracy    recall precision        F1 
# 0.9329759 0.6140351 0.9210526 0.7368421 

# After adjusting sample weights
# accuracy    recall   precision        F1 
# 0.9203223 0.8806818  0.6950673  0.7769424 
# Con: improved recall, reduced precision
mosaicplot(t(confusion_matrix),
           xlab="Observation", ylab="Prediction", 
           main="", cex.axis = 1.2)


# Tuning mtry ------------------------------------------------------------------
# mtry: the number of variables that are randomly chosen to be candidates at each split
nt <- seq(1, 500, 10)
oob_mse <- vector("numeric", length(nt))
for(i in 1:length(nt)){
    rf <- ranger(formula = formula, 
                 data = data_before[idx,], 
                 probability = T,
                 num.trees = nt[i], 
                 write.forest = FALSE)
    oob_mse[i] <- rf$prediction.error
}

f_name <- "performance/ntrees_oob_mse.csv"
write_csv(as_tibble_col(oob_mse, column_name = "MSE") %>% 
              add_column(mtry = nt, .before = 1),
          f_name)
plot(x = nt, y = oob_mse, col = "red", type = "l",
     xlab="num.trees")

# Increase threshold to minimize FN --------------------------------------------
rf.pred.test %>% head(5)
rf.pred.test %>% 
    as_tibble() %>% 
    filter(V1<V2)

(rf.pred.test[,2]>0.55) %>% table()

rf.class.test <- max.col(rf.pred.test) - 1
rf.class.test %>% table()

obs.test %>% table()







