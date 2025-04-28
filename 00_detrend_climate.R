## If climate variables have trends over time, the model trained on historical 
## data is no longer applicable to predict future values. To address this problem,
## we detrend the climate variables, group by year, and centralize at zero.

library(scales)
library(data.table)

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

group_by_location <- data %>% group_by(lat, lon)
group_by_location %>% 
    group_keys() %>% 
    mutate(id = 1:n()) %>% 
    as.data.table()
locations <- group_by_location %>% group_split()
locations[[1]]

count_water_receive <- group_by_location %>% 
    group_map(~table(factor(.x$Water_receive, levels = c(0,1)))) %>% 
    do.call(rbind,.) %>% 
    bind_cols(group_by_location %>% 
                  group_keys(), .)

count_water_receive %>% 
    as_tibble() %>% 
    filter(`0` %ni% c(0,11)) %>% 
    as.data.table()

inconsistent_locations <- count_water_receive %>% 
    as_tibble() %>% 
    filter(`0` %ni% c(0,11))
inconsistent_locations %>% as.data.table()
f_name <- sprintf("data/inconsistent_water_receive_%s.csv", area)
f_name
# write_csv(inconsistent_locations, f_name)

group_by_location %>% 
    group_keys() %>% 
    mutate(id = 1:n()) %>% 
    left_join(inconsistent_locations, by=c("lat", "lon")) %>% 
    drop_na() %>% 
    view()

group_by_location %>% 
    group_keys() %>% 
    mutate(id = 1:n()) %>% 
    left_join(inconsistent_locations, by=c("lat", "lon")) %>% 
    drop_na() %>% 
    pull(id) %>% 
    head(5)
locations[[902]] %>% select(1:3, 32)
locations[[1923]] %>% select(1:3, 32)

data %>% 
    distinct(lat, lon, .keep_all = TRUE) %>% 
    count(Water_receive)

data %>% 
    filter(year==2015) %>%
    distinct(lat, lon, .keep_all = TRUE) %>% 
    count(Water_receive)

data %>% 
    # filter(year==2015) %>% 
    distinct(lat, lon, .keep_all = TRUE) %>% 
    pull(year) %>% 
    unique()

data %>% 
    distinct(lat, lon, .keep_all = TRUE) %>% 
    count(Water_receive) %>% 
    as.matrix() %>% 
    prop.table(margin=2)

data_group <- data %>% group_by(year)
data_group %>% tally()
data_group %>% 
    group_map(~table(.x$Water_receive)) %>% 
    do.call(rbind, .)

groups <- data_group %>% group_split()
groups[[1]]$year %>% unique()
groups[[5]] %>% distinct(lat, lon, .keep_all = TRUE)
groups[[5]]$Water_receive %>% table()
groups[[1]]$Water_receive %>% table() %>% prop.table()


center_col <- function(data, cols){
    ## Mean center columns in a table
    # @data: table or data frame
    # @col: a vector of selected columns to center
    # @return A data frame with the selected columns mean-centered 
    #   (i.e., each value minus its column mean).
    
    data %>% 
        mutate_at(cols, ~.-mean(., na.rm=TRUE))
}
center_col(groups[[1]], short_name)

data_center <- data_group %>% 
    group_modify(~center_col(.x, cols = short_name))
data_center
f_name <- sprintf("data/center_at_mean/%s_line.csv", area)
write_csv(data_center, f_name)

i <- 1
# box plot of climate variables by year
for (i in seq_along(climate_vec)){
    cli <- climate_vec[i]
    print (cli)
    the_variable <- data_center %>% 
        arrange(desc(!!sym(cli))) %>% 
        select(year, lat, lon, !!sym(cli), Water_receive) 
    the_variable <- the_variable %>% 
        mutate(Water_receive = factor(Water_receive),
               year = factor(year))
    the_variable
    # group by year
    p <- ggplot(the_variable, 
                aes_string(x = "year", 
                           y = as.name(cli), 
                           fill = "Water_receive")) +
        geom_boxplot(outlier.shape = NA, outliers = FALSE) +
        mytheme +
        theme(axis.title = element_text(size=rel(1.5)),
              axis.title.x = element_blank(),
        )
    p
    f_name <- sprintf("image/climate_descrip/box_%s_by_year_center.png", cli)
    print (f_name)
    plot_png(p, f_name, 20.2, 11.7)
}
