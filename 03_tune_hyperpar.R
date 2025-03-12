# Tune hyperparameters for RF


# Tuning num.trees -------------------------------------------------------------
# num.trees: Number of trees.
i <- 8
idx <- kfolds[[i]]

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


# Tuning mtry ------------------------------------------------------------------
# mtry: the number of variables that are randomly chosen to be candidates at each split