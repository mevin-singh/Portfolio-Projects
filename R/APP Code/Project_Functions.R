
# Getting 2-hour forecast
get2hrData <- function(date, time) {
  # date must in format "yyyy-MM-dd"
  # time must in format "HH:mm:ss"
  url <- "https://api.data.gov.sg/v1/environment/2-hour-weather-forecast?date_time="
  url <- paste0(url,date,"T",time)
  weather_data <- fromJSON(url)
  data <- as.data.frame(weather_data$items$forecasts)
  location_coordinates <- as.data.frame(weather_data$area_metadata$label_location)
  data <- cbind(data, location_coordinates)
  names(data) <- c('area', 'forecast', 'lat', 'long')
  data
}


# Getting 24-hour forecast
get24hrData <- function(date) {
  # date must in format "yyyy-MM-dd"
  # time must in format "HH:mm:ss"
  url <- "https://api.data.gov.sg/v1/environment/24-hour-weather-forecast?date="
  url <- paste0(url, date)
  weather_data_24hr <- fromJSON(url)
  data <- as.data.frame(weather_data_24hr$items$periods[[1]]$regions)
  names(data) <- c('West', 'East', 'Central', 'South', 'North')
  
  # choosing only 2nd row
  data <- data[2, ]
  data <- data %>% gather() %>% rename(region = key, forecast = value)
  data$lat <- c(1.329490, 1.352480, 1.350400, 1.302570, 1.448200)
  data$long <- c(103.738258, 103.944611, 103.848747,103.834686, 103.819489) # coordinates represents the roughly in the middle of each region
  
  # newly formatted data
  data
}

# Getting UV data
getUVdata <- function(date) {
  # date must in format "yyyy-MM-dd"
  # time must in format "HH:mm:ss"
  url <- 'https://api.data.gov.sg/v1/environment/uv-index?date='
  url <- paste0(url, date)
  uvdata <- fromJSON(url)
  n <- length(uvdata$items$index)
  data <- uvdata$items$index[[n]]
  
  # Reversing the order so 7am appears first
  data <- data[seq(dim(data)[1],1),]
  
  # Reformatting timestamp column
  timestamp <- c()
  for (i in 1:nrow(data)) {
    timestamp <- c(timestamp, substr(data[i, 'timestamp'], start = 12, stop = 16))
  }
  
  data$timestamp <- timestamp
  
  data$color <- cut(as.numeric(data$value), breaks = c(0, 2, 5, 7, 10, Inf), 
                    labels = c('Low', 'Moderate', 'High', 'Very High', 'Extreme'), 
                    include.lowest = TRUE)
  
  data
}

get4dayData <- function(date) {
  url <- 'https://api.data.gov.sg/v1/environment/4-day-weather-forecast?date='
  url <- paste0 (url, date)
  url <- fromJSON(url)
  forecast <- as.data.frame(url$items$forecasts[[1]]$forecast)
  date <- as.data.frame(url$items$forecasts[[1]]$date)
  data <- cbind(date, forecast)
  data$day <- weekdays(as.Date(data[, 1]))
  colnames(data) <- c('Date', 'Forecast', 'Day')
  col_order <- c('Date', 'Day', 'Forecast')
  data <- data[, col_order]
  data
}

# Getting color for valueBox color for 4 day forecast
getColor <- function(date) {
  colours <- data.frame(Day = c('Monday', 
                                'Tuesday', 
                                'Wednesday',
                                'Thursday',
                                'Friday',
                                'Saturday',
                                'Sunday'),
                        Color = c('yellow',
                                  'blue',
                                  'orange',
                                  'purple',
                                  'teal',
                                  'olive',
                                  'green'))
  
  data <- get4dayData(date)
  df <- inner_join(data, colours, by = c('Day' = 'Day'))
  df
}

getAirdata <- function(date){
  url <- 'https://api.data.gov.sg/v1/environment/air-temperature?date='
  url <- paste0(url, date)
  data <- fromJSON(url)
  n <- length(data$items$readings)
  data <- data$items$readings[[n]]$value
  num <- round(mean(data), 1)
  num
}

getRaindata <- function(date){
  url <- 'https://api.data.gov.sg/v1/environment/rainfall?date='
  url <- paste0(url, date)
  data <- fromJSON(url)
  n <- length(data$items$readings)
  data <- data$items$readings[[n]]$value
  num <- round(mean(data), 1)
  num
}

getHumiditydata <- function(date){
  url <- 'https://api.data.gov.sg/v1/environment/relative-humidity?date='
  url <- paste0(url, date)
  data <- fromJSON(url)
  n <- length(data$items$readings)
  data <- data$items$readings[[n]]$value
  num <- round(mean(data))
  num
}

getWinddata <- function(date){
  url <- 'https://api.data.gov.sg/v1/environment/wind-speed?date='
  url <- paste0(url, date)
  data <- fromJSON(url)
  n <- length(data$items$readings)
  data <- data$items$readings[[n]]$value
  num <- round(mean(data), 1)
  num
}