# Part 4: Torch R Version

This folder contains a complete torch R implementation of the workshop, providing an alternative to the TensorFlow/Keras approach used in parts 1-3.

## Why Torch?

- **Native R**: Torch R is a native R package, not a wrapper around Python (unlike Keras/TensorFlow)
- **No Python backend**: All computations happen in R (though reticulate is still used for PepTools)
- **Modern architecture**: Torch uses a more explicit, PyTorch-like API
- **Manual training loops**: More control over the training process
- **Growing ecosystem**: Increasingly popular in the R community

## Structure

```
part_4_torch/
├── part1/                          # Torch basics
│   └── torch_basics.R             # Tensors, operations, autograd
├── part2/                          # Torch models
│   └── torch_iris_classifier.R    # Neural network for iris classification
└── part3/                          # Full ML deployment pipeline
    └── immunotherapy/
        ├── 1_train_model.R                      # Train peptide binding model
        ├── 2_publish_model.R                    # Pin model to Connect
        ├── 3_share_model_plumber/
        │   ├── plumber.R                        # API serving predictions
        │   └── deploy_api.R                     # Deploy to Connect
        └── 4_consume_api.R                      # Call the deployed API
```

## Key Differences from TensorFlow/Keras

### Model Definition

**Keras (parts 1-3):**
```r
model <- keras_model_sequential(
  list(
    layer_input(shape = 180),
    layer_dense(units = 180, activation = "relu"),
    layer_dense(units = 3, activation = "softmax")
  )
)
```

**Torch (part 4):**
```r
my_net <- nn_module(
  "MyNet",
  initialize = function() {
    self$fc1 <- nn_linear(180, 180)
    self$fc2 <- nn_linear(180, 3)
    self$relu <- nn_relu()
  },
  forward = function(x) {
    x %>%
      self$fc1() %>%
      self$relu() %>%
      self$fc2()
  }
)

model <- my_net()
```

### Training

**Keras:**
```r
model$compile(loss = "categorical_crossentropy", optimizer = "adam")
history <- model$fit(x_train, y_train, epochs = 50)
```

**Torch:**
```r
criterion <- nn_cross_entropy_loss()
optimizer <- optim_adam(model$parameters, lr = 0.001)

for (epoch in 1:50) {
  predictions <- model(x_train)
  loss <- criterion(predictions, y_train)
  
  optimizer$zero_grad()
  loss$backward()
  optimizer$step()
}
```

### Predictions

**Keras:**
```r
predictions <- model$predict(x_test)
```

**Torch:**
```r
model$eval()
with_no_grad({
  predictions <- model(x_test)
})
```

## Running the Torch Workshop

### Part 1: Basics

```r
source("part_4_torch/part1/torch_basics.R")
```

Learn about:
- Creating tensors
- Tensor operations
- Integration with tidyverse
- GPU availability
- Automatic differentiation (autograd)

### Part 2: Iris Classification

```r
source("part_4_torch/part2/torch_iris_classifier.R")
```

Build a neural network to classify iris species:
- Manual training loop
- Validation tracking
- Confusion matrix
- Model saving

### Part 3: Full ML Deployment Pipeline

#### Step 1: Train the model

```r
setwd("part_4_torch/part3/immunotherapy")
source("1_train_model.R")
```

#### Step 2: Pin to Connect

```r
# Set environment variables first
Sys.setenv(CONNECT_SERVER = "https://pub.workshop.posit.team")
Sys.setenv(CONNECT_API_KEY = "your-api-key")

source("2_publish_model.R")
```

#### Step 3: Deploy API

```r
setwd("3_share_model_plumber")
source("deploy_api.R")
```

#### Step 4: Consume API

```r
# Set environment variables
Sys.setenv(CONNECT_SERVER = "https://pub.workshop.posit.team")
Sys.setenv(CONNECT_API_KEY = "your-api-key")
Sys.setenv(CONNECT_CONTENT_URL = "plumber_torch")

source("4_consume_api.R")
```

## Model Format

- **Keras models**: Saved as `.keras` files (HDF5 format)
- **Torch models**: Saved as `.pt` files (PyTorch format)

Both can be pinned to Posit Connect and served via Plumber APIs.

## Dependencies

Torch R is installed via the setup script:

```r
source("workshop_setup.R")
```

This installs:
- `torch` package
- `luz` (high-level torch API, optional)
- All other workshop dependencies

## Benefits for Pharma/Healthcare

- **Reproducibility**: Native R reduces dependency issues
- **Transparency**: Explicit training loops make the process clear
- **Flexibility**: More control for custom loss functions and metrics
- **Industry acceptance**: PyTorch (torch's Python counterpart) is widely used in research

## Questions?

See the main workshop README or ask your instructor!
