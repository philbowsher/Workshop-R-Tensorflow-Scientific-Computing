# Define server logic required to draw a histogram ----
server <- function(input, output) {
    
    source("pretrained.R")
    
    # Create an output variable that indicates if a file has been uploaded
    output$file_uploaded <- reactive(
        !is.null(input$filename)
    )
    outputOptions(output, 'file_uploaded', suspendWhenHidden=FALSE)
    
    # extract the filename path
    image_path <- reactive({
        input$filename$datapath
    })
    
    # render the input image
    output$imagePlot <- renderPlot({
        if (req(!is.null(image_path()))) {
            img <- image_path()
            with_par(list(mar = rep(0, 4)), {
                imager::load.image(img) %>% 
                    plot(axes = FALSE)
            })
        } else {
            empty_plot()
        }
    })  
    
    # render the predicted probabilities
    output$categoryPlot <- renderPlot({
        if (req(!is.null(image_path()))) {
            image_path() %>% 
                predict_image(model, top = input$top_n) %>%
                plot_prediction()
        } else {
            empty_plot()
        }
    })
}