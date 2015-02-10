library(XML)
library(plyr)
library(reshape)
library(reshape2)
library(stringr)
library(ncdf4)
library(rworldmap)
library(shiny)
library(ggplot2)
library(gridExtra)
library(dataRetrieval)

catalogURLbase <- "http://nwisnfie-a.cloudapp.net/thredds/catalog/NWIS/"
catalogURLfull <- paste0(catalogURLbase, "catalog.html")

tables <- readHTMLTable(catalogURLfull)

nRows <- unlist(lapply(tables, function(t) dim(t)[1]))
dates <- as.character(tables[[which.max(nRows)]][2:nRows, 1])

buildURL <- function(date){
  date <- as.character(date)
  paste0(catalogURLbase, date, "catalog.html")
}

dates <- data.frame(dates = dates)
dates <- transform(dates, urls = sapply(dates, buildURL))

buildFileLists <- function(element){
  tables <- readHTMLTable(element["urls"])
  nRows2 <- unlist(lapply(tables, function(t) dim(t)[1]))
  files <- as.character(tables[[which.max(nRows2)]][2:nRows2, 1])
  suppressWarnings(data.frame(date = element["dates"], files = files, stringsAsFactors = FALSE))
}

fileList <- apply(dates, 1, buildFileLists)
fileList <- reshape::merge_all(fileList)

extractRegion <- function(element){  
  print(element["files"])
  stringr::str_match(element["files"], "((.*num_)([0-9]{2})(.*))")[,4]
}

fileList <- transform(fileList, region = apply(fileList, 1, extractRegion))
fileList <- fileList[,c(1,3,2)]

