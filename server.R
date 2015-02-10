
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

shinyServer(function(input, output) {
  
  ncdf <- NULL
  
  currentFileList <- reactive({
    if (input$date != "All"){
      fileList <- fileList[fileList$date == input$date,]
    }
    if (input$region != "All"){
      fileList <- fileList[fileList$region == input$region,]
    }
    fileList
  })
  
  currentNetCDF <- reactive({
    fileSelect <- currentFileList()
    nFiles <- nrow(fileSelect)
    if(nFiles == 1){
      if(!is.null(ncdf)){
        ncdf4::nc_close(ncdf)
      }
      
      ncdfURL <- paste0("http://nwisnfie-a.cloudapp.net/thredds/dodsC/NWIS/",
                        fileSelect["date"],
                        fileSelect["files"])
      
      ncdf <<- ncdf4::nc_open(ncdfURL)
    }
  })
  
  output$table <- renderDataTable({
    currentFileList()
  }, options = list(pageLength = 25)
  )
  
  output$msg <- renderText({
    fileSelect <- currentFileList()
    nFiles <- nrow(fileSelect)
    
    if(nFiles > 1){
      "Please select one file."
    } else {
      paste("Report generated for", fileSelect["files"])
    }
    
  })
  
  output$map <- renderPlot({
    fileSelect <- currentFileList()
    nFiles <- nrow(fileSelect)
    
    if(nFiles > 1){
      NULL
    } else {
      
      if(is.null(ncdf)){
        currentNetCDF()
      }
      #     ncdfURL <- paste0("http://nwisnfie-a.cloudapp.net/thredds/dodsC/NWIS/",
      #                       fileSelect["date"],
      #                       fileSelect["files"])
      #     
      #     ncdf <- ncdf4::nc_open(ncdfURL)
      
      # Get Lat and Lon from netCDF.
      lat <- ncvar_get(ncdf, "dec_lat_va")
      lon <- ncvar_get(ncdf, "dec_long_va")
      
      # Get region name and Number
      name <- ncdf4::ncvar_get(ncdf, "nfie_hydro_region_name")[1]
      number <- ncdf4::ncvar_get(ncdf, "nfie_hydro_region_num")[1]
      title <- paste0(name, " (#", number, ")")
      
      map <- rworldmap::getMap(resolution="low")
      plot(map, main = title, xlim = c(-125, -67), ylim = c(25, 49))
      points(lon, lat, col = "red", pch = 19, cex = 0.35)
    }
  })
  
  
  output$sanity <- renderPlot({
    fileSelect <- currentFileList()
    nFiles <- nrow(fileSelect)
    
    if(nFiles > 1){
      NULL
    } else {
      
      if(is.null(ncdf)){
        currentNetCDF()
      }
      
      # Get Lat and Lon from netCDF.
      lat <- ncvar_get(ncdf, "dec_lat_va")
      lon <- ncvar_get(ncdf, "dec_long_va")
      
      # Get region name and Number
      name <- ncdf4::ncvar_get(ncdf, "nfie_hydro_region_name")[1]
      number <- ncdf4::ncvar_get(ncdf, "nfie_hydro_region_num")[1]
      title <- paste0(name, " (#", number, ")")
      
      
      times <- ncdf4::ncvar_get(ncdf, "time")
      times <- as.POSIXct(times, origin = "1970-01-01")
      
      familyids <- ncdf4::ncvar_get(ncdf, "familyid")
      siteNumbers <- ncdf4::ncvar_get(ncdf, "site_no")
      methodIDs <- ncdf4::ncvar_get(ncdf, "dd_nu")
      times.format <- strftime(times, format = "%Y-%m-%dT%H:%M:%S%z")
      
      extractParams <- function(index) {
        line <- capture.output(print(ncdf))[index]
        stringr::str_match(line, ".*v([0-9]{5})_value.*")[2]
      }
      
      params <- sapply(grep("value", capture.output(print(ncdf))), extractParams)
      
      names <- paste0("v", params,"_value")
      params <- cbind(params, names)
      
      plots <- list()
      
      checkParam <- function(row) {
        
        vals <- ncdf4::ncvar_get(ncdf, row[2])
        vals[vals == -999999.00] <- NA
        
        withData <- which(rowSums(is.na(vals)) != ncol(vals))
        
        siteNumbers <- siteNumbers[withData]
        vals <- vals[withData, ]
        methodIDs <- methodIDs[withData]
        
        numberToCheck <- min(length(withData), 1)
        
        layersToCheck <- sample(1:length(siteNumbers), 
                                size = numberToCheck, 
                                replace = FALSE)
        
        for(i in 1:numberToCheck){
          layerSelect <- layersToCheck[i]
          
          siteNumber <- siteNumbers[layerSelect]
          valsSubset <- vals[layerSelect, ]
          methodID   <- methodIDs[layerSelect]
          
          data <- data.frame(times = times, ncdf.value = valsSubset)
          data <- data[complete.cases(data),]
          
          url <- dataRetrieval::constructNWISURL(siteNumber = siteNumber, 
                                                 parameterCd = row[1], 
                                                 startDate = min(times.format), 
                                                 endDate = max(times.format), 
                                                 service = "uv")
          
          url <- paste0(url, "&methodId=", methodID)
          
          nwis <- dataRetrieval::importWaterML1(url, asDateTime = TRUE, tz = "")
          
          if(nrow(nwis) == 0){
            print(paste0(row[1], " is empty."))
          } else {
            nwis <- nwis[,c(3,6)]
            colnames(nwis) <- c("times", "nwis.value")
            data <- plyr::join(x = data, y = nwis, by = "times")
            data <- reshape2::melt(data, id.vars = "times")
            
            colnames(data) <- c("times", "data.source", "value")
            
            p <- ggplot(data)   # base layer
            p <- p + geom_point(aes(x = times, y = value, color = data.source), 
                                alpha = 0.7, size = 2.5) # points layer
            p <- p + ggtitle(paste0("Site: ", siteNumber, " | Variable: ", row[1]))
            return(p)
            
          } 
        }
      }
      
      plots <- apply(params, 1, checkParam)
      
      do.call(grid.arrange,  plots)
      
    }
    
    
    
  })
  
  output$summary <- renderPrint({
    fileSelect <- currentFileList()
    nFiles <- nrow(fileSelect)
    
    if(nFiles > 1){
      
    } else {
      if(is.null(ncdf)){
        currentNetCDF()
      }
      output <- capture.output(print(ncdf))
      print(paste(output, sep = "\n"))
    }
    
  })
  
  output$thredds <- renderUI({
    totalFiles <- nrow(fileList)
    HTML(paste0("There are currently <strong>", 
                nrow(fileList), 
                " </strong> files spanning <strong>",
                length(dates),
                "</strong> days."))
  })
  
  
  output$download.link <- renderUI({
    fileSelect <- currentFileList()
    nFiles <- nrow(fileSelect)
    
    if(nFiles > 1){
      
    } else {
      
      OPeNDAPURL <- paste0("http://nwisnfie-a.cloudapp.net/thredds/dodsC/NWIS/",
                           fileSelect["date"],
                           fileSelect["files"],
                           ".html")
      
      HTTPSERURL <- paste0("http://nwisnfie-a.cloudapp.net/thredds/fileServer/NWIS/",
                           fileSelect["date"],
                           fileSelect["files"])
      
      HTML(paste0("<h3> <a href=\"", OPeNDAPURL, "\"> Access via OPeNDAP </a> &nbsp; &nbsp; &nbsp;",
                  "<a href=\"", HTTPSERURL, "\"> Download via HTTP </a> <h3>"))
    }
    
  })
  
  
  
})
