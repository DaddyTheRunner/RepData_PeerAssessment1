---
output: 
  html_document:
    keep_md: true
---

# Reproducible Research: Peer Assessment 1
_**Author:  Daddy the Runner**_  
_**Date:  Sunday, January 11, 2015**_

<!-- Processing Instructions --------------------------------------- -->
<!--                                                                 -->
<!-- This file is best processed using the following set of commands -->
<!-- knit("PA1_template.Rmd")                                        -->
<!-- render("PA1_template.md")                                       -->
<!--                                                                 -->
<!-- --------------------------------------------------------------- -->


<!-- Create some style elements for the HTML file -->
<style>
h2 {
  color: green;
  margin-top: 5ex;
}

p {
  font-size: 12pt;
}

.fig-caption {
  font-size: 10pt;
}
</style>


## Loading and preprocessing the data

First, we load all required libraries.


```r
require(dplyr)
require(ggplot2)
```

The following code chunk will extract the data file from the
zip file if it doesn't exist in the local directory.


```r
data.fn <- "activity.csv"
zip.fn <- "activity.zip"
if (!file.exists(data.fn)) {
  # Extract the data from the zip file
  unzip(zip.fn)
}
```

Once we have the data file extracted, we read it in using the
following code.


```r
data <- read.csv(data.fn, stringsAsFactors = FALSE)
```

Now we are ready to preprocess the data.


```r
## Convert the dates to Date objects
data <- mutate(data, date = as.Date(date))
```



## What is mean total number of steps taken per day?

The following code generates a histogram of the daily steps taken.
First the data is processed to remove all of the missin (NA) values.
Then it is grouped by date and summarized using the `sum()` function.
Finally `ggplot()` is invoked to generate the histogram graphic.


```r
## Create a histogram of the daily steps taken
## group by day and sum the steps
daily.data <- na.omit(data) %>% 
  group_by(date) %>%
  summarize(steps = sum(steps, na.rm = TRUE))

## Create a figure counter
fig.num <- 1L

## Generate the plot
hist.plot <- ggplot(daily.data, aes(x=steps)) +
  geom_histogram(binwidth=5000, color="black", fill="green") +
  scale_y_continuous(limits=c(0,30)) +
  scale_x_continuous(limits=c(0,25000)) +
  xlab("Daily Steps") +
  ylab("Number of Days") +
  ggtitle("Histogram of Daily Steps\n") +
  theme(plot.title = element_text(lineheight=.8, face="bold"))

## Display the plot
hist.plot
```

![plot of chunk make-daily-steps-histogram](figure/make-daily-steps-histogram-1.png) 

<span class="fig-caption">
**Fig. 1 Histogram of the daily steps.**  The histogram
shows the total number of days where the daily step count falls
within each of the bins across the x axis.
</span>

The mean number of daily steps taken, when steps were recorded, was 
10766.19 and
the median number of daily steps was 10765.

> **Note:** The following in-line code was used to generate the mean
> and median values in the previous paragraph:
>
> `sprintf("%0.2f", mean(daily.data$steps))`
>
> `median(daily.data$steps)`



## What is the average daily activity pattern?

In this section, we will be looking at how the activity pattern varies
throughout the course of a day.  This will be done by averaging each of the
five minute intervals across all days with available data.  (i.e. we will be
ignoring intervals with NAs.)  Then a time series line plot will be generated
and analyzed.

First we have to process the interval data from the raw dataset.  An
inspection of the values in the interval variable indicate that the five
minute intervals have been coded with the hours in the 1000's and 100's
places and the minutes in the 10's and 1's places.  Therefore, we cannot
simply use the interval variable as-is for the horizontal x-axis.

The following code chunk creates a new variable called time that uses the
POSIXct date-time format.  POSIXct requires a date component.  However,
since we are only interested in the hours and minutes part, we can safely
use any date for the date part as long as all of the values use the same
date.  Some helper columns are generated in the process of creating the
time column.  Since the dataset is small, these helper columns were kept.


```r
## Calculate the hours and minutes for each interval
data <- data %>% 
  mutate(hour = interval %/% 100,
         min = interval %% 100,
         timestr = sprintf("%02i:%02i", hour, min),
         time = as.POSIXct(timestr, format="%H:%M"))
```

The following code chunk generates a new data frame that contains the
five minute intervals in the time variable and the average (mean) of each
interval in the avg.steps variable.


```r
## generate the time series data
ts.data <- data %>%
  group_by(time) %>%
  summarize(avg.steps = mean(steps, na.rm = TRUE))
```

Now use the data frame generated in the previous code chunk to generate
a line plot of the averge number of steps for each interval.


```r
## Increment the figure number
fig.num <- fig.num + 1L

## Generate the time series plot
ts.plot <- ggplot(ts.data, aes(x=time, y=avg.steps)) +
  geom_line() +
  scale_x_datetime(labels = date_format("%H:%M"),
                   breaks = "4 hour", minor_breaks = "1 hour") +
  xlab("Time of Day") +
  ylab("Steps") +
  ggtitle("Average Steps Taken\n(5 minute intervals)\n") +
  theme(plot.title = element_text(lineheight=.8, face="bold"))

## Display the plot
ts.plot
```

![plot of chunk generate-time-series-plot](figure/generate-time-series-plot-1.png) 

<span class="fig-caption">
**Fig. 2 Average Daily Activity Pattern.**  The 
time series plot shows the average (mean) number of steps taken
in each five minute interval throughout the course of a day.
The averages were calculated from data collected over a two
month period in 2012.
</span>

Fig. 2 shows that the volunteer typically became active
around 6:00 AM and that activity levels gradually wound down between
7:00 PM and 10:00 PM.
The maximum average (mean) number of steps across all five minute
intervals was 206.1698113.  This maximum average
occured in the
08:35
five minute interval.

> **Note:** The following in-line code was used to calculate the
> maximum average value and determine which five minute interval
> contains the maximum value.
>
> `max(ts.data$avg.steps)`  
> `format(ts.data$time[which.max(ts.data$avg.steps)], format="%H:%M")`




## Imputing missing values



## Are there differences in activity patterns between weekdays and weekends?
