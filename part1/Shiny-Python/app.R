
library(shiny)
library(reticulate)

# source python function(s)
source_python("python_function.py")

# source python pandas dataframe(s)
source_python("pandas_df.py")

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Old Faithful Geyser Data"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            sliderInput("bins",
                        "Number of bins:",
                        min = 1,
                        max = 50,
                        value = 30)
        ),

        # Show a plot of the generated distribution, matplotlib, and test output
        mainPanel(
           column(
               width = 6,
               fluidRow(plotOutput("distPlot")),
               fluidRow(imageOutput("matplotlib"), width = 6)
           ),
           column(
               width = 6,
               fluidRow(textOutput("pythonText")),
               fluidRow(tableOutput("dataframe"))
           )
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

    # R histogram
    output$distPlot <- renderPlot({
        # generate bins based on input$bins from ui.R
        x    <- faithful[, 2]
        bins <- seq(min(x), max(x), length.out = input$bins + 1)

        # draw the histogram with the specified number of bins
        hist(x, breaks = bins, col = 'darkgray', border = 'white')
    })
    
    # Matplotlib
    output$matplotlib <- renderImage({
        #reticulate::source_python("~/CS Python Demo/Shiny-Python/matplotlib.py")
        list(src = "test.png")
    })
    
    # Python function
    output$pythonText <- renderText({
        testMethod(input$bins)
    })
    
    # Pandas dataframe
    output$dataframe <- renderTable({
        df
    })
   
}

# Run the application 
shinyApp(ui = ui, server = server)
