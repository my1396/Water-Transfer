'%ni%' <- Negate('%in%')

plot_png <- function(p, fn, width=5.5, height=4, ppi=300){
    png(fn, width=width*ppi, height=height*ppi, res=ppi)
    print (p)
    dev.off()
}

library(ggplot2)
mytheme <- theme(legend.margin = margin(t=0, b=0, unit="mm"), # legend box margins
                 title = element_text(size=rel(1.2)),
                 axis.title = element_text(size=rel(1.2)), # axis title
                 axis.text = element_text(size=rel(1.2)), # tick labels along axes
                 panel.grid.minor = element_blank() # remove minor grid lines
                 )
                 

get_performance <- function(prediction, observation){
    ## Confusion table performance metrics
    # @prediction: vector of predicted 0-1 class 
    # @observation: vector of observed 0-1 class
    # @return: a list containing 
    #   - a confusion matrix, and 
    #   - a vector of performance metrics
    
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


