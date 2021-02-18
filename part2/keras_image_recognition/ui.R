#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
# https://github.com/Frank5547/Dog-Breed-Classifier-with-Shiny-App-Deployment

library(shiny)
library(shinycssloaders)
library(shinythemes)

options(shiny.maxRequestSize = 30*1024^2)

# Define UI for application that draws a histogram ----
ui <- fluidPage(
    theme = shinytheme("cerulean"),
    # Application title
    titlePanel("Image prediction"),
    
    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            fileInput("filename", 
                      "Select an image file to upload"
            ),
            imageOutput("imagePlot", height = "200px"),
            conditionalPanel(
                condition = "output.file_uploaded == true",
                sliderInput("top_n",
                            "Number of categories:",
                            min = 1,
                            max = 10,
                            value = 3)
            )
        ),
        # - end of sidebar panel
        
        # Show a plot of the generated distribution
        mainPanel(
            conditionalPanel(
                condition = "output.file_uploaded == true",
                withSpinner({
                    plotOutput("categoryPlot", height = "300px")
                })
            )
        )
    )
)