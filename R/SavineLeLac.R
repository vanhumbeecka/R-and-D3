#' Script to illustrate going from ggplot to an svg. Later, bind svg elements to d3 manually
#' 
#' A lot of handywork when binding and importing D3 functionality
#' Of course, this is where plot.ly comes in, and does all the work for you automaticaly

library(ggplot2)
library(scales)
library(gridSVG)
library(XML)

if (!exists("myplot")) {
  myplot <- readRDS("D:\\ExplorationDay\\ExplorationDayProject\\ggplot_object.Rds")
  myplot <- myplot + scale_x_date(breaks=date_breaks("months")) + ggtitle(label = "Consumptions and forecast (1 day in the future)")
  myplot
  myplot.svg <- grid.export("plot1.svg", addClasses=TRUE)
}

cat(
  'var ourdata=',
  rjson::toJSON(apply(myplot$data,MARGIN=1,FUN=function(x)return(list(x)))),
  file = "./../js/data.js",
  append = F
)

cat(
  'var dataToBind = ',
  'd3.entries(ourdata.map(function(d,i) {return d[0]}))',
  file = "./../js/d3.custom.js",
  append = F
)

cat(
  'scatterPoints = d3.select(".points").selectAll("use");\n',
  'scatterPoints.data(dataToBind)',
  file = "./../js/d3.custom.js",
  append = T
)

cat('scatterPoints  
    .on("mouseover", function(d) {      
      //Create the tooltip label
      var tooltip = d3.select(this.parentNode).append("g");
      tooltip
        .attr("id","tooltip")
        .attr("transform","translate("+(d3.select(this).attr("x")+10)+","+d3.select(this).attr("y")+")")
        .append("rect")
          .attr("stroke","white")
          .attr("stroke-opacity",.5)
          .attr("fill","white")
          .attr("fill-opacity",.5)
          .attr("height",30)
          .attr("width",50)
          .attr("rx",5)
          .attr("x",2)
          .attr("y",5);
      tooltip.append("text")
        .attr("transform","scale(1,-1)")
        .attr("x",5)
        .attr("y",-22)
        .attr("text-anchor","start")
        .attr("stroke","gray")
        .attr("fill","gray")
        .attr("fill-opacity",1)
        .attr("opacity",1)
        .text("x:" + Math.round(d.value.xvar*100)/100);
      tooltip.append("text")
        .attr("transform","scale(1,-1)")
        .attr("x",5)
        .attr("y",-10)
        .attr("text-anchor","start")
        .attr("stroke","gray")
        .attr("fill","gray")      
        .attr("fill-opacity",1)
        .attr("opacity",1)
        .text("y:" + Math.round(d.value.yvar*100)/100);
    })              
    .on("mouseout", function(d) {       
        d3.select("#tooltip").remove();  
    });',
    file = "./../js/d3.custom.js",
    append = T
)