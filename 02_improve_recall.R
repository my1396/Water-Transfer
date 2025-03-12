# Issue: Recall is low
# Trial: 
#   1. data bootstrap
#   2. improve threshold for classification

## Continue with 01_predict_water-receive.R
# Deal with imbalance ----------------------------------------------------------
# Fix: Stratified sampling by providing case.weights

# For one group in this script, loop is in 
i <- 8
idx <- kfolds[[i]]

weights <- rep(0, nrow(data_before[idx,]))
w <- data_before[idx, "Water_receive"] %>% table()
w <- 1/w
w <- w/(sum(w))
# apply larger weight to smaller sample
weights[data_before[idx, "Water_receive", drop=TRUE] %>% as.logical()] <- w[2]
weights[!data_before[idx, "Water_receive", drop=TRUE]] <- w[1]
weights %>% table()

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
# check sample distribution
inbag <- do.call(cbind, RF_ranger$inbag.counts)
inbag[data_before[idx, "Water_receive", drop=TRUE] %>% as.logical(), ] %>% colSums()
inbag[!data_before[idx, "Water_receive", drop=TRUE], ] %>% colSums()

# class.weights, cost sensitive learning
# RF_ranger <- ranger(formula = formula, 
#                     data = data_before[idx,], 
#                     probability = TRUE,
#                     importance = "permutation",
#                     mtry = 9,
#                     num.trees = 200,
#                     min.node.size = 10,
#                     scale.permutation.importance = TRUE,
#                     )
# print(RF_ranger)

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
  "precision"=precision, "F1"=F1) %>% 
    round(4)
# Eastern
# accuracy    recall precision        F1 
# 0.9329759 0.6140351 0.9210526 0.7368421 

# After adjusting sample weights
# accuracy  recall   precision       F1 
# 0.9266    0.8409    0.7327     0.7831 
# Con: improved recall, reduced precision

## Mosaic plot
mosaicplot(t(confusion_matrix),
           xlab="Observation", ylab="Prediction", 
           main="", cex.axis = 1.2)

## Variable importance
varImp <- RF_ranger$variable.importance %>% 
    sort(decreasing = FALSE) %>% 
    enframe() %>% 
    mutate(name=factor(name, levels=name))
varImp
ggplot(varImp, aes(name, value)) +
    geom_point() +
    coord_flip() +
    labs(y="Vaiable importance", title=sprintf("Group %s", i)) +
    theme(axis.text.y = element_text(size=rel(1.2), face = "bold"),
          axis.title.y = element_blank(),
          )


# Increase threshold to minimize FN --------------------------------------------
# To be continued 
rf.pred.test %>% head(5)
rf.pred.test %>% 
    as_tibble() %>% 
    filter(V1<V2)

(rf.pred.test[,2]>0.55) %>% table()

rf.class.test <- max.col(rf.pred.test) - 1
rf.class.test %>% table()

obs.test %>% table()







