plot_png <- function(p, fn, width=5.5, height=4, ppi=300){
    png(fn, width=width*ppi, height=height*ppi, res=ppi)
    print (p)
    dev.off()
}

library(ggplot2)
mytheme <- theme(legend.position = "none", # disable legend
                 legend.spacing.y = unit(0, 'mm'), # spacing between legend title and legend items
                 legend.key.height=unit(0.8,"line"), # vertical spacing between legend items
                 legend.margin = margin(t=0, b=0, unit="mm"), # legend box margins
                 title = element_text(size=rel(1.2)),
                 axis.title = element_text(size=rel(1.2)), # use `rel()` to change proportionally to base font size; or a number to specify absolute size as follows;
                 axis.text = element_text(size=rel(1.2)), # tick labels along axes
                 panel.grid.minor = element_blank() # remove minor gridlines
                 )
