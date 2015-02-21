var dataToBind =  d3.entries(ourdata.map(function(d,i) {
  return d[0];
}));
var scatterPoints = d3.select(".points").selectAll("use");
 scatterPoints.data(dataToBind);
 scatterPoints
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
          .attr("height",50)
          .attr("width",100)
          .attr("rx",5)
          .attr("x",2)
          .attr("y",5);
      tooltip.append("text")
        .attr("transform","scale(1,-1)")
        .attr("x",5)
        .attr("y",-45)
        .attr("text-anchor","start")
        .attr("stroke","gray")
        .attr("fill","gray")
        .attr("fill-opacity",1)
        .attr("opacity",1)
        .text("x:" + Math.round(d.value.x));
      tooltip.append("text")
        .attr("transform","scale(1,-1)")
        .attr("x",5)
        .attr("y",-25)
        .attr("text-anchor","start")
        .attr("stroke","gray")
        .attr("fill","gray")
        .attr("fill-opacity",1)
        .attr("opacity",1)
        .text("y:" + Math.round(d.value.Amount));
      tooltip.append("text")
        .attr("transform","scale(1,-1)")
        .attr("x",5)
        .attr("y",-5)
        .attr("text-anchor","start")
        .attr("stroke","gray")
        .attr("fill","gray")
        .attr("fill-opacity",1)
        .attr("opacity",1)
        .text("interpolated")
    })
    .on("mouseout", function(d) {
        d3.select("#tooltip").remove();
    });