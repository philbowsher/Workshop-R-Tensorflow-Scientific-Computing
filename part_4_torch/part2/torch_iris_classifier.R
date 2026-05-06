# ============================================================================
# Torch Iris Classification - Neural Network in Pure R
# ============================================================================
# This is the torch equivalent of part2/03_hello_keras.Rmd
# Using torch R (no Python backend needed)

# Configure Python for reticulate (if needed for compatibility)
Sys.setenv(RETICULATE_PYTHON = "/opt/python/3.12.3/bin/python3")

library(torch)
library(tidyverse)

cat("=======================================================================\n")
cat("TORCH IRIS CLASSIFICATION\n")
cat("=======================================================================\n\n")

# ============================================================================
# 1. Load and prepare data
# ============================================================================

cat("1. Loading iris dataset...\n")
cat("----------------------------\n")

# Load iris data
data(iris)
iris_data <- iris %>%
  as_tibble() %>%
  mutate(species_num = as.integer(Species) - 1L) # 0, 1, 2

cat("Dataset shape:", nrow(iris_data), "samples,", ncol(iris_data), "columns\n")
cat("Classes:", paste(unique(iris$Species), collapse = ", "), "\n")
cat("Class distribution:\n")
print(table(iris_data$Species))

# Split features and labels
features <- iris_data %>%
  select(Sepal.Length, Sepal.Width, Petal.Length, Petal.Width) %>%
  as.matrix()

labels <- iris_data$species_num

# Train/test split (80/20)
set.seed(42)
n <- nrow(features)
train_idx <- sample(1:n, size = floor(0.8 * n))
test_idx <- setdiff(1:n, train_idx)

x_train <- features[train_idx, ]
y_train <- labels[train_idx]
x_test <- features[test_idx, ]
y_test <- labels[test_idx]

cat("\nTraining set:", length(y_train), "samples\n")
cat("Test set:", length(y_test), "samples\n")

# Convert to torch tensors
x_train_tensor <- torch_tensor(x_train, dtype = torch_float32())
y_train_tensor <- torch_tensor(y_train, dtype = torch_long())
x_test_tensor <- torch_tensor(x_test, dtype = torch_float32())
y_test_tensor <- torch_tensor(y_test, dtype = torch_long())

# ============================================================================
# 2. Define the neural network
# ============================================================================

cat("\n2. Building neural network...\n")
cat("------------------------------\n")

# Define network architecture
iris_net <- nn_module(
  "IrisNet",
  initialize = function() {
    self$fc1 <- nn_linear(4, 16)
    self$fc2 <- nn_linear(16, 16)
    self$fc3 <- nn_linear(16, 3)
    self$relu <- nn_relu()
    self$dropout <- nn_dropout(0.3)
  },
  forward = function(x) {
    x %>%
      self$fc1() %>%
      self$relu() %>%
      self$dropout() %>%
      self$fc2() %>%
      self$relu() %>%
      self$dropout() %>%
      self$fc3()
  }
)

# Instantiate the model
model <- iris_net()

cat("Model architecture:\n")
cat("  Input layer: 4 features\n")
cat("  Hidden layer 1: 16 units + ReLU + Dropout(0.3)\n")
cat("  Hidden layer 2: 16 units + ReLU + Dropout(0.3)\n")
cat("  Output layer: 3 classes\n")

# ============================================================================
# 3. Configure training
# ============================================================================

cat("\n3. Configuring training...\n")
cat("---------------------------\n")

# Loss function and optimizer
criterion <- nn_cross_entropy_loss()
optimizer <- optim_adam(model$parameters, lr = 0.001)

# Training parameters
n_epochs <- 100
batch_size <- 16

cat("Loss function: Cross Entropy\n")
cat("Optimizer: Adam (lr = 0.001)\n")
cat("Epochs:", n_epochs, "\n")
cat("Batch size:", batch_size, "\n")

# ============================================================================
# 4. Training loop
# ============================================================================

cat("\n4. Training model...\n")
cat("---------------------\n")

# Store history
history <- list(
  train_loss = numeric(n_epochs),
  train_acc = numeric(n_epochs)
)

# Training loop
model$train()
for (epoch in 1:n_epochs) {

  # Forward pass
  predictions <- model(x_train_tensor)
  loss <- criterion(predictions, y_train_tensor + 1L) # torch uses 1-indexed for cross_entropy

  # Backward pass
  optimizer$zero_grad()
  loss$backward()
  optimizer$step()

  # Calculate accuracy
  pred_classes <- torch_argmax(predictions, dim = 2) - 1L # Back to 0-indexed
  accuracy <- (pred_classes == y_train_tensor)$to(dtype = torch_float32())$mean()$item()

  # Store history
  history$train_loss[epoch] <- loss$item()
  history$train_acc[epoch] <- accuracy

  # Print progress every 10 epochs
  if (epoch %% 10 == 0) {
    cat(sprintf("Epoch %3d/%d - loss: %.4f - accuracy: %.4f\n",
                epoch, n_epochs, loss$item(), accuracy))
  }
}

cat("\n✓ Training complete!\n")

# ============================================================================
# 5. Evaluate on test set
# ============================================================================

cat("\n5. Evaluating on test set...\n")
cat("-----------------------------\n")

model$eval()
with_no_grad({
  test_predictions <- model(x_test_tensor)
  test_loss <- criterion(test_predictions, y_test_tensor + 1L)

  pred_classes <- torch_argmax(test_predictions, dim = 2) - 1L
  test_accuracy <- (pred_classes == y_test_tensor)$to(dtype = torch_float32())$mean()$item()
})

cat("Test loss:", sprintf("%.4f", test_loss$item()), "\n")
cat("Test accuracy:", sprintf("%.4f", test_accuracy), "\n")

# ============================================================================
# 6. Visualize training history
# ============================================================================

cat("\n6. Plotting training history...\n")
cat("--------------------------------\n")

history_df <- tibble(
  epoch = 1:n_epochs,
  loss = history$train_loss,
  accuracy = history$train_acc
)

p1 <- ggplot(history_df, aes(x = epoch, y = loss)) +
  geom_line(color = "blue", size = 1) +
  labs(title = "Training Loss", x = "Epoch", y = "Loss") +
  theme_minimal()

p2 <- ggplot(history_df, aes(x = epoch, y = accuracy)) +
  geom_line(color = "green", size = 1) +
  labs(title = "Training Accuracy", x = "Epoch", y = "Accuracy") +
  theme_minimal()

print(p1)
print(p2)

# ============================================================================
# 7. Confusion matrix
# ============================================================================

cat("\n7. Confusion matrix...\n")
cat("-----------------------\n")

# Get predictions as R vector
pred_classes_r <- as.integer(as_array(pred_classes))

# Create confusion matrix
conf_matrix <- table(
  Actual = factor(y_test, levels = 0:2, labels = levels(iris$Species)),
  Predicted = factor(pred_classes_r, levels = 0:2, labels = levels(iris$Species))
)

print(conf_matrix)

# Visualize confusion matrix
conf_df <- as.data.frame(conf_matrix) %>%
  rename(count = Freq)

p3 <- ggplot(conf_df, aes(x = Predicted, y = Actual, fill = count)) +
  geom_tile() +
  geom_text(aes(label = count), color = "white", size = 6) +
  scale_fill_gradient(low = "lightblue", high = "darkblue") +
  labs(title = "Confusion Matrix - Iris Classification") +
  theme_minimal()

print(p3)

# ============================================================================
# 8. Save model
# ============================================================================

cat("\n8. Saving model...\n")
cat("-------------------\n")

torch_save(model, "iris_model.pt")
cat("✓ Model saved to: iris_model.pt\n")

cat("\n=======================================================================\n")
cat("✓ Torch iris classification complete!\n")
cat("=======================================================================\n")
