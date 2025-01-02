# Issue: Recall is low
# Trial: 
#   1. data bootstrap
#   2. improve threshold for classification

# Deal with imbalance ----------------------------------------------------------
# sample.fraction = c(0.5, 0.5)
RF_ranger <- ranger(formula = formula, 
                    data = data_before[idx,], 
                    probability = T,
                    sample.fraction = c(0.5, 0.5), 
                    importance = "permutation", 
                    scale.permutation.importance = TRUE,
)
# class.weights, cost sensitive learning
RF_ranger <- ranger(formula = formula, 
                    data = data_before[idx,], 
                    probability = T,
                    importance = "permutation", 
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
F1

# False Negative is high
c("accuracy"=accuracy, "recall"=recall,
  "precision"=precision, "F1"=F1)
# Eastern
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







