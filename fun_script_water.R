plot_png <- function(p, fn, width=5.5, height=4, ppi=300){
    png(fn, width=width*ppi, height=height*ppi, res=ppi)
    print (p)
    dev.off()
}