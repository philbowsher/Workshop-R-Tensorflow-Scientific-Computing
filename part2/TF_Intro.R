# https://github.com/snowde/interpretable-ml-book9/blob/f687173ddb765de2c38a656360c5d9e1e8ecfa95/temp_scripts/imagenet_classifier.R
# https://github.com/jasdumas/image-clf-keras-shiny/blob/50ef07e63d9833727efd177ff35fc6e858f84a35/resnet50_example.R
# https://cran.rstudio.com/web/packages/keras/vignettes/applications.html



# Sys.setenv(TENSORFLOW_PYTHON="~/.virtualenvs/r-tensorflow/bin/python")

library(keras)

# use_implementation("keras")

model <- application_resnet50(weights = 'imagenet')

# load the image (copy an image from Photos)
img_path <- "butterfly2.jpg"
img <- image_load(img_path, target_size = c(224,224))
x <- image_to_array(img)

# ensure we have a 4d tensor with single element in the batch dimension,
# the preprocess the input for prediction using resnet50
x <- array_reshape(x, c(1, dim(x)))
x <- imagenet_preprocess_input(x)

# make predictions then decode and print them
preds <- model %>% predict(x)
imagenet_decode_predictions(preds, top = 3)[[1]]



