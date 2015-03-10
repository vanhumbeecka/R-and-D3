library(XML)
library(data.table)
library(lubridate)
library(ggplot2)
library(scales)
library(RJSONIO)

## 0. HELPER FUNCTIONS

extractCategories <- function(vec) {
    categories <- sapply(as.character(vec),"strsplit",split=",")
    categories <- sapply(categories, function(x){str_trim(x)})
    return(categories)
}

as.numeric.factor <- function(f) {
    return(as.numeric(levels(f))[f])
}

## 1. GET THE DATA

#' The blog website is a php page: http://blog.ae.be/wp-admin/edit.php
#' Therefore, we save it as a static html page, so R can extract data from a static page

url <- "WordPress.html"
raw <- readHTMLTable(url) # read all table-elements you find on this page, ours is the first table (of 2 in total)
df <- raw[[1]]
dt <- data.table(df)

## 2. CLEAN THE DATA

# renaming some columns
setnames(dt, "Select All", "SelectAll")
setnames(dt, "SEO Title", "SEOTitle")
setnames(dt, "Meta Desc.", "MetaDesc")
setnames(dt, "Focus KW", "FocusKW")

# remove unwanted columns, edit type of wanted columns
dt[,SelectAll:=NULL]
dt[,SEO:=NULL]
dt[,Title:=as.character(Title)]
dt[,SEOTitle:=NULL]
dt[,MetaDesc:=NULL]
dt[,FocusKW:=as.character(FocusKW)]

# clean some text, that can't be handled in the front-end
dt[,Title:=str_replace(Title, "–","-")]
dt[,Title:=gsub("<U+200B>","",Title)]
dt[,Title:=gsub("[.]","",Title)]
dt[,Title:=gsub("[’]","'",Title)]
dt[,Title:=gsub("[‘]","'",Title)]
dt[,Title:=gsub("é","e",Title)]
dt[,Title:=gsub("é","e",Title)]

# further cleaning of titles
titles <- sapply(dt$Title,function(x){strsplit(x,split = "\n")})
titles <- unname(sapply(titles, function(x) {x[1]}))
dt[,Title:=titles]

# cleaning of categories
dt[,Categories:=as.character(Categories)]
dt[,Categories:=extractCategories(Categories)]
dt[,Categories:=sapply(Categories,"as.factor")]

# cleaning of tags
dt[,Tags:=as.character(Tags)]
dt[,Tags:=extractCategories(Tags)]
dt[,Tags:=sapply(Tags,"as.factor")]

# cleaning of comments
setnames(dt, "V6", "comments")
dt[,comments:=as.numeric.factor(comments)]

# cleaning of dates
dt[,Date:=as.character(Date)]
dt[,Published:=unname(sapply(dt$Date, function(x) {grepl('Published',x)}))]
anw <- sapply(dt$Date, function(x) {'Published' %in% x})

dates.temp1 <- unname(sapply(dt$Date, function(x) {strsplit(x, split='Published')[[1]]}))
dates.temp2 <- unname(sapply(dates.temp1, function(x) {strsplit(x, split='Last Modified')[[1]]}))
dates.temp2[1] <- "2014/12/19" # hardcoded change ("18 hours ago" changed to a date format, could have been done more neatly)
dt[,Date:=as.Date(dates.temp2)]

# list all tags & categories
all.tags <- unique(unlist(lapply(dt$Tags,levels)))
all.categories <- unique(unlist(lapply(dt$Categories,levels)))

# start a new data.table for processing
new.dt <- data.table(Title=as.character(),Author=as.character(), Categorie=as.character(),Tag=as.character(),Tags=as.character(),comments=as.numeric(),Date=as.numeric(),Published=as.logical())
new.dt2 <- copy(new.dt)

# run through all the rows of multiple categories,
# make an entry in the data.table for each single categorie
for (row.ind in 1:nrow(dt)) {
  row <- dt[row.ind,]
  cats <- row$Categories[[1]]
  for (cat in cats) {
    new.dt <- rbind(new.dt, data.table(Title=row$Title[[1]],
                                       Author=row$Author[[1]],
                                       Categorie=cat,
                                       Tag=NA,
                                       Tags=row$Tags,
                                       comments=row$comments,
                                       Date=row$Date,
                                       Published=row$Published))
  }  
} 

# run through all the rows of multiple tags,
# make an entry in the data.table for each single tag
for (row.ind in 1:nrow(new.dt)) {
  row <- new.dt[row.ind,]
  tags <- row$Tags[[1]]
  for (tag in tags) {
    new.dt2 <- rbind(new.dt2, data.table(Title=row$Title[[1]],
                                       Author=row$Author[[1]],
                                       Categorie=row$Categorie,
                                       Tag=tag,
                                       Tags=row$Tags,
                                       comments=row$comments,
                                       Date=row$Date,
                                       Published=row$Published))
  }  
}  

# further small cleaning steps
new.dt2[,Tags:=NULL]
dt <- copy(new.dt2)
dt[,Date:=as.Date(Date,origin="1970-01-01")]

## further cleaning
dt[,Date:=format(Date,"%Y-%m")]
dt[,Published:=NULL]
dt[,Tag:=str_replace(Tag, "—","-")]

#' CHANGE THE DATA.TABLE TO A LIST
#'
#' STRUCTURE:
#' ---------
#' name (char)
#' size (num)
#' imports (list(char))
#' 
#' EXAMPLE:
#' -------
#' [name: 'Title.But do you love it?', size:2, imports['Author.Roman Verraest', 'Categories.BC', 'Categories.EA']]

#' change the resulting data.table to a list,
#' so that it can be serialized to JSON
dtToList <- function(x) {
  mylist <- list()
  colns <- names(x)
  colns2 <- names(x)
  
  for (coln in colns) {
    if (coln != "comments") {
      uniqueEls <- unique(x[[coln]])
      
      for (uniqueEl in uniqueEls) {
        # find all rows with this uniqueEl
        inds <- which(dt[[coln]] == uniqueEl)
        myInnerListE <- list()
        for (ind in inds) {
          for (coln2 in colns2) {
            if (coln2 != coln & coln2 != "comments") {
              myInnerListE <- c(myInnerListE, paste0(coln2,".",dt[ind,coln2,with=F][[coln2]]))
            }
          }
        }
        myInnerListE <- unique(myInnerListE)
        mylistE <- list(name=paste0(coln,".",uniqueEl),size=dt[ind,"comments",with=F][["comments"]],imports=myInnerListE)
        mylist.length <- length(mylist)
        mylist[[mylist.length+1]] <-  mylistE
      }
    }
  }
  return(mylist)
}
  
final <- dtToList(dt)
jsonOut <- toJSON(final)
# write the json to a local file. (here: development environement)
# You could also FTP it, or upload it to a database if you wished.
cat(jsonOut, file="C:\\xampp\\htdocs\\R\\blogdata.json")












  
  
  
  
  
  