library(ggplot2)
library(dplyr)
library(scales)
library(ggthemes)
library(withr)

library(keras)

# Load pretrained model from resnet50 and imagenet data
model <- application_resnet50(weights = 'imagenet')


# Given an image file, predict the image categories
predict_image <- function(image_file, model, top = 5){
  # This is the example code from ?keras::application_resnet50
  img <- image_load(image_file, target_size = c(224,224))
  x <- image_to_array(img)
  dim(x) <- c(1, dim(x))
  x <- imagenet_preprocess_input(x)
  preds <- model %>% predict(x)
  imagenet_decode_predictions(preds, top = top)[[1]][, -1]
}


# Plot the prediction probabilities
plot_prediction <- function(x){
  x %>% 
    ggplot(aes(x = reorder(class_description, score), y = score)) +
    geom_bar(stat = "identity", fill = "blue") +
    coord_flip() +
    scale_y_continuous(labels = percent, limits = c(0, 1)) +
    xlab(NULL) +
    ylab(NULL) +
    theme_tufte(20)
}


# Create an empty plot
empty_plot <- function(text = ""){
  with_par(list(mar = rep(0, 4)), {
    plot(c(0, 10), c(0,10), type = "n", axes = FALSE, xlab = NA, ylab = NA)
    if (text != "") text(5, 5, labels = text, adj = c(0.5, 0))
  })
}
