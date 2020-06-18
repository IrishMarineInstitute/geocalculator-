#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(rgdal)
library(sf)
library(dplyr)
library(leaflet)
library(readr)

Inshore_Grid <- read_rds("Data/Inshore_Grid.rds")
ICES_rectangles <- read_rds("Data//ICES_rectangles.rds")

# Define UI for application that draws a histogram
ui <- navbarPage("Geographical Coordinate Converter",
                 tabPanel("Single point conversion",
                          fluidPage(
                              fluidRow(
                                  column(3,
                                         h4("Latitude"),
                                          numericInput("Deg1", label = "Degrees", value = 52),
                                          numericInput("Min1", label = "Minutes", value = 7),
                                          numericInput("Sec1", label = "Seconds", value = 11),
                                          radioButtons("NorthSouth", "Hemisphere", choices=c("N","S"), selected = "N"),
                                          tags$hr(),
                                          h4("Longitude"),
                                          numericInput("Deg2", label = "Degrees", value = 6),
                                          numericInput("Min2", label = "Minutes", value = 57),
                                          numericInput("Sec2", label = "Seconds", value = 28),
                                          radioButtons("EastWest", "East or West", choices=c("E (+)","W (-)"), selected = "W (-)")
                                      ),
                                   column(9,
                                          column(6,
                                                 h4("Latitude"),
                                                 verbatimTextOutput("DDlat"),
                                                 h4("Longitude"),
                                                 verbatimTextOutput("DDlon")),
                                          column(6,
                                                 h4("ICES area"),
                                                 verbatimTextOutput("areasOutput"),
                                                 h4("ICES recangle"),
                                                 verbatimTextOutput("rectOutput"),
                                                 h4("Inshore Grid reference"),
                                                 verbatimTextOutput("pntsOutput"),
                                                 ),
                                          leafletOutput("map"),
                                          textOutput("disclaimer")
                                          )
                                  )
                              )
                          )
                 )
   

# Define server logic 
server <- function(input, output) {
    
    Lat <- reactive({ 
        if (input$NorthSouth == "S") { 
            -(sum(input$Deg1,(input$Min1/60),(input$Sec1/3600)))
        }else{
            sum(input$Deg1,(input$Min1/60),(input$Sec1/3600))  
        } 
    })
    Long <- reactive({ 
        if (input$EastWest == "W (-)") { 
        -(sum(input$Deg2,(input$Min2/60),(input$Sec2/3600)))
        }else{
        sum(input$Deg2,(input$Min2/60),(input$Sec2/3600))  
        } 
    })
    output$DDlat <- renderText({
        Lat()
    })
    output$DDlon <- renderText({
        Long()
    })
   pnts <-reactive({
       data.frame(x=Lat(),y=Long())
    })
    pnts_sf <- reactive({
       st_as_sf(pnts(), coords = c('y', 'x'), crs = st_crs(Inshore_Grid))
    })
    pnts_final <- reactive({
        pnts_sf() %>% mutate(
           INintersection = as.integer(st_intersects(geometry, Inshore_Grid)),
           IRintersection = as.integer(st_intersects(geometry, ICES_rectangles)),
            INGrid_SQ = Inshore_Grid$Label[INintersection],
           AREA = ICES_rectangles$Area_27[IRintersection], 
           RECT = ICES_rectangles$ICESNAME[IRintersection])
        
        })
    output$pntsOutput <- renderPrint({
        as.character(pnts_final()$INGrid_SQ)

    })
    output$areasOutput <- renderPrint({
        as.character(pnts_final()$AREA)
    })
    output$rectOutput <- renderPrint({
        as.character(pnts_final()$RECT)
    })
    output$map <- renderLeaflet({
        leaflet() %>%
            addTiles(group = "base") %>%
            setView(lng = Long(), lat = Lat(), zoom = 10)
       })
    observe({
        Long()
        Lat()
        
        leafletProxy("map") %>%
            clearShapes() %>%
            addCircleMarkers(lat = Lat(),lng = Long())
    })
    output$disclaimer <- renderText(
        "This app is intended for the use of the Inshore team of the Marine Institute. The MI takes no responsibility for the information contained therein."
    )
}

# Run the application 
shinyApp(ui = ui, server = server)
