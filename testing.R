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
