## This file is used to test and debug coding chunks
require(dplyr)
require(ggplot2)
require(scales)

data.fn <- "activity.csv"
zip.fn <- "activity.zip"

if (!file.exists(data.fn)) {
  # Extract the data from the zip file
  unzip(zip.fn)
}


data <- read.csv(data.fn, stringsAsFactors = FALSE)

## Convert the data fram into a tbl_df
data <- tbl_df(data)

## Convert the dates to Date objects
data <- mutate(data, date = as.Date(date))



## Create a histogram of the daily steps taken
## group by day and sum the steps
daily.data <- na.omit(data) %>% 
  group_by(date) %>%
  summarize(steps = sum(steps, na.rm = TRUE))

## Generate the plot
hist.plot <- ggplot(daily.data, aes(x=steps)) +
  geom_histogram(binwidth=5000, color="black", fill="red") +
  scale_y_continuous(limits=c(0,30)) +
  scale_x_continuous(limits=c(0,25000)) +
  xlab("Daily Steps") +
  ylab("Number of Days") +
  ggtitle("Histogram of Daily Steps\n") +
  theme(plot.title = element_text(lineheight=.8, face="bold"))

## Display the plot
hist.plot


## Calculate the hours and minutes for each interval
data <- data %>% 
  mutate(hour = interval %/% 100,
         min = interval %% 100,
         timestr = sprintf("%02i:%02i", hour, min),
         time = as.POSIXct(timestr, format="%H:%M"))

## generate the time series data
ts.data <- data %>%
  group_by(time) %>%
  summarize(avg.steps = mean(steps, na.rm = TRUE))

## Generate the time series plot
ts.plot <- ggplot(ts.data, aes(x=time, y=avg.steps)) +
  geom_line() +
  scale_x_datetime(labels = date_format("%H:%M"),
                   breaks = "4 hour", minor_breaks = "1 hour") +
  xlab("Time of Day") +
  ylab("Steps") +
  ggtitle("Average Steps Taken\n(5 minute intervals)\n") +
  theme(plot.title = element_text(lineheight=.8, face="bold"))

# Find the max average number of steps
max(ts.data$avg.steps)

## The following expression gives the time of the max
format(ts.data$time[which.max(ts.data$avg.steps)], format="%H:%M")



## Combine the date and time columns into a date.time column
data <- data %>%
  mutate(date.time =
           as.POSIXct(paste(format(date, format="%Y-%m-%d"),
                            format(time, format="%H:%M"))))

## Create a map of the NA values
na.steps <- is.na(data$steps)
na.plot <- ggplot(data[na.steps, ], aes(x=time, y=date)) +
  geom_point() +
  scale_x_datetime(labels = date_format("%H:%M"),
                   breaks = "4 hour", minor_breaks = "1 hour") +
  ggtitle("Map of NAs\n") +
  xlab("Time of Day") +
  ylab("Date") +
  theme(plot.title = element_text(lineheight=.8, face="bold"))
na.plot

## Get a list of the days with no data
na.days <- data.frame(Date = unique(data$date[na.steps])) %>%
  mutate(na.count = sum(is.na(data$steps[data$date == Date])))
kable(na.days, col.names = c("Days without Data", "NA Count"))
cat("|Total|", sum(na.days$na.count), "|")

## Caluclate the total number of missing values
sum(na.days$na.count)

min(data$date)
max(data$date)

## Impute the data
imputed.data <- data

## First impute the first day's data with a copy of the second day
day <- min(data$date)
imputed.data$steps[imputed.data$date == day] <-
  imputed.data$steps[imputed.data$date == day + 1]

## Next impute the last day's data with a copy of the previous day
day <- max(data$date)
imputed.data$steps[imputed.data$date == day] <-
  imputed.data$steps[imputed.data$date == day - 1]

## Now impute the rest of the missing days with the average of the two
## neighboring days treating NAs as zeros
## First make a temporary copy of the data and replace all NAs with zeros
tmp.data <- data %>%
  mutate(steps = ifelse(is.na(steps), 0, steps))
for (day in na.days$Date[2:(length(na.days$Date)-1)]){
  imputed.data$steps[imputed.data$date == day] <-
    (tmp.data$steps[tmp.data$date == day - 1] +
     tmp.data$steps[tmp.data$date == day + 1]) / 2
}


## The following function determines if a given date falls on a weekend
is.weekend <- function(date) {
  day <- weekdays(date)
  day == "Sunday" | day == "Saturday"
}

## Create a weekday vs weekend factor for the imputed data
imputed.data <- imputed.data %>%
  mutate(day.type = ifelse(is.weekend(date), "Weekend", "Weekday"),
         day.type = factor(day.type, levels = c("Weekend", "Weekday")))

## generate the time series data using the imputed data
imputed.ts.data <- imputed.data %>%
  group_by(day.type, time) %>%
  summarize(avg.steps = mean(steps, na.rm = TRUE))

## Analysis of imputed data time series
start.time <- as.POSIXct("2015-01-13 10:00:00")
end.time   <- as.POSIXct("2015-01-13 22:00:00")
postpeak.avgs <- imputed.ts.data %>%
  group_by(day.type) %>%
  filter(time >= start.time, time <= end.time) %>%
  summarize(avg = mean(avg.steps))

## Calculate the value and location of the peaks
peaks <- imputed.ts.data %>%
  group_by(day.type) %>%
  summarize(max = max(avg.steps),
            max.time = time[which.max(avg.steps)])

## Generate the time series plot
imputed.ts.plot <- ggplot(data = imputed.ts.data, aes(x = time, y = avg.steps)) +
  geom_line() +
  geom_segment(data = postpeak.avgs,
               aes(x = start.time, xend = end.time, y = avg, yend = avg),
               color = "green", lwd = 1) +
  geom_text(data = postpeak.avgs,
            aes(x = end.time, y = avg + 10, label = sprintf("Avg = %0.2f", avg)),
            hjust = 0, vjust = 0) +
  geom_text(data = peaks,
            aes(x = start.time, y = 200, label = sprintf("Max = %0.2f", max)),
            hjust = 0, vjust = 0) +
  facet_grid(day.type ~ .) +
  scale_x_datetime(labels = date_format("%H:%M"),
                   breaks = "4 hour", minor_breaks = "1 hour") +
  xlab("Time of Day") +
  ylab("Steps") +
  ggtitle("Average Steps Taken\n(5 minute intervals)\n") +
  theme(plot.title = element_text(lineheight = 0.8, face = "bold"))

imputed.ts.plot

