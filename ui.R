
shinyUI(
  fluidPage(
    titlePanel("NWIS-NFIE File Checker"),
    h4("Connected to THREDDS server at:"),
    HTML("<h4><a href=\"http://nwisnfie-a.cloudapp.net/thredds/catalog/NWIS/catalog.html\"> nwisnfie-a.cloudapp.net/thredds/NWIS/ </a></h4>"),
    HTML("<hr>"),
    h2("Overview:"),
    HTML("<ul>"),
    HTML("<li> This is a demonstration tool for interacting with a THREDDS server and reading from NetCDF files that have been built with the <strong><a href=\"https://github.com/Kevin-M-Smith/nwisnfie\">nwisnfie</a></strong> R package. </li>"),
    HTML("<li> This tool is an experiment with the <a href=\"http://shiny.rstudio.com\"><strong>Shiny</strong></a> web application framework, which remotely executes <strong> R </strong> programs, and shows the results as a webpage. </li>"),
    HTML("<li> The source code for this application is available <a href=\"https://github.com/Kevin-M-Smith/nwisnfie-viewer\"><strong>here.</strong></a> </li>"),
    HTML("</ul>"),
    h2("Usage Notes:"),
    HTML("<ul>"),
    HTML("<li> Select a date and NFIE-Hydro Region from the drop down lists. </li>"),
    HTML("<li> The corresponding NetCDF file will be read from the THREDDS server. </li>"),
    HTML("<li> The following analysis will be done:"),
    HTML("<ul>"),
    HTML("<li> <strong>Graphical Extent:</strong> All sites in the file will be plotted on a map of the contiguous United States. </li>"),
    HTML("<li> <strong>Sanity Check:</strong> One layer will be selected at random for each geophysical variable in the file. The corresponding data will be downloaded live from NWIS. Both data series are plotted, but ideally only one series is visible (i.e. they are the same)."),
    HTML("<li> <strong>File Summary:</strong> A text summary of the dimensions, variables, and attributes the file will be printed. </li>"),
    HTML("</ul></li>"),
    HTML("<li> There are also the options to download the selected data set via OPeNDAP or HTTP. </li>"),
    HTML("</ul>"),
    HTML("<hr>"),
    fluidRow(
      uiOutput("thredds")
    ),
    h3("File Selection: "),
    fluidRow(
      column(4, 
             selectInput("date", 
                         "Date:", 
                         c("All", 
                           unique(as.character(fileList$date))))
      ),
      column(2, 
             selectInput("region", 
                         "Region:", 
                         c("All", 
                           unique(as.character(fileList$region))))
      )   
    ),
    HTML("<hr>"),
#     fluidRow(
#       dataTableOutput(outputId="table")
#     ),
    fluidRow(
      h2("Status:"),
      verbatimTextOutput("msg"),
      uiOutput("download.link"),
      h2("Graphical Extent (contiguous USA): "),
      plotOutput("map", width = 1200, height = 800),
      h2("Sanity Check:"),
      plotOutput("sanity", width = 1200, height = 800),
      h2("File Summary:"),
      verbatimTextOutput("summary")
    )
    
  )  
)