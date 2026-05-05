# https://github.com/snowde/interpretable-ml-book9/blob/f687173ddb765de2c38a656360c5d9e1e8ecfa95/temp_scripts/imagenet_classifier.R
# https://github.com/jasdumas/image-clf-keras-shiny/blob/50ef07e63d9833727efd177ff35fc6e858f84a35/resnet50_example.R
# https://cran.rstudio.com/web/packages/keras/vignettes/applications.html
# ============================================================================
# Image Classification with Pre-trained ResNet50
# ============================================================================
# This script uses a pre-trained ResNet50 model to classify images
#
# BEFORE RUNNING:
# 1. Find any image (jpg or png) - e.g., download from web, screenshot, etc.
# 2. Save it in this directory (part2/) as "butterfly2.jpg"
# 3. Or change img_path below to point to your image file
#
# The model will predict what objects are in the image!
# ============================================================================

# Configure Python for reticulate (if needed)
Sys.setenv(RETICULATE_PYTHON = "/opt/python/3.12.3/bin/python3")

library(keras)
library(tensorflow)

cat("Loading pre-trained ResNet50 model...\n")
cat("(This will download ~100MB on first run)\n\n")

model <- application_resnet50(weights = 'imagenet')

cat("✓ Model loaded\n\n")

# ============================================================================
# Load and prepare your image
# ============================================================================

# Change this to your image filename
img_path <- "butterfly2.jpg"

# Check if image exists
if (!file.exists(img_path)) {
  stop(paste0(
    "\n❌ Image file not found: ", img_path, "\n\n",
    "Please:\n",
    "1. Add an image file (jpg/png) to this directory\n",
    "2. Name it 'butterfly2.jpg'\n",
    "   OR change img_path in the script to your filename\n"
  ))
}

cat("Loading image:", img_path, "\n")

# Load and preprocess image using TensorFlow
# (workaround for keras image_load API changes)
img_raw <- tf$io$read_file(img_path)
img <- tf$image$decode_image(img_raw, channels = 3L)
img <- tf$image$resize(img, size = c(224L, 224L))
x <- as.array(img)

# Prepare image for ResNet50
# - Reshape to 4D tensor (batch_size, height, width, channels)
# - Preprocess for ImageNet model
cat("Preparing image for prediction...\n")
x <- array_reshape(x, c(1, dim(x)))
x <- imagenet_preprocess_input(x)

# Make predictions
cat("Running prediction...\n\n")
# Use Python method directly (workaround for R predict() incompatibility)
preds <- model$predict(x)

# Decode and display top 3 predictions
cat("========================================\n")
cat("TOP 3 PREDICTIONS:\n")
cat("========================================\n")
results <- imagenet_decode_predictions(preds, top = 3)[[1]]
print(results)

cat("\n✓ Done! Try with different images to see what the model predicts.\n")




