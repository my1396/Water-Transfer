# Fill missing values in central line 
data <- read_csv("data/central_line.csv")
data

# time period: 2010-2020 (T=11 years)
data$year %>% unique()

# Number of missing values per col
# No missing values except for Water_receive
is.na(data) %>% colSums()

# check 270 locations with missing Water_receive 
data[is.na(data$Water_receive), c(1:4, 32)] %>% 
    count(lat, lon) %>% view()

data %>% filter(lat==34.9 & lon==111.7) %>% select(c(1:4, 32) ) %>% arrange(year) %>% fill(Water_receive, .direction = "downup")
data %>% filter(lat==38.0 & lon==117.3) %>% select(c(1:4, 32) ) %>% arrange(year) %>% fill(Water_receive, .direction = "downup")

# fill missing values
data_group <- data %>% group_by(lat, lon)
groups <- data_group %>% group_split()
data <- data_group %>% 
    group_modify( ~ fill(.x, Water_receive, .direction = "downup") )
data <- data %>% ungroup()
f_name <- "data/central_line.csv"
write_csv(data, f_name)