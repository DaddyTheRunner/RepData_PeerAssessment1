## This file is used to test and debug coding chunks
require(dplyr)
require(ggplot2)

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
