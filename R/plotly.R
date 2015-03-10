#' Script to illustrate going from ggplot to an svg. Later, bind svg elements to d3 manually
#' 
#' A lot of handywork when binding and importing D3 functionality
#' Of course, this is where plot.ly comes in, and does all the work for you automaticaly

library(ggplot2)
library(data.table)
library(scales)
library(XML)

if (!exists("myplot")) {
  myplot <- readRDS("D:\\ExplorationDay\\ExplorationDayProject\\ggplot_object.Rds")
  myplot <- myplot + scale_x_date(breaks=date_breaks("months")) + ggtitle(label = "Consumptions and forecast (1 day in the future)")
}
if (!exists("data")) {
  data <- readRDS("D:\\ExplorationDay\\ExplorationDayProject\\data.Rds")
  data[,Xregressors:=NULL]
}
df <- as.data.frame(data)

p <- ggplot(df, aes(x=dates.to.pred, y=Amount, group=type, colour=type)) + 
  geom_line(size=1) +
  ggtitle(paste("Consumptions and forecasts for ATM", atm.id, " (1 day in the future)")) +
  scale_x_date(breaks=date_breaks("week")) +
  xlab("Dates") +
  ylab("Consumption") +
  theme(axis.text.x = element_text(angle=90, vjust=0.5), legend.title=element_blank()) +
  scale_y_continuous(labels=comma) 

library(plotly)
py <- plotly()
py$ggplotly(p)
