# ============================================================================
# Train Peptide Binding Prediction Model with Torch (Vetiver Version)
# ============================================================================
# This is identical to part_4_torch/part3/immunotherapy/1_train_model.R
# We train the model here, then use Vetiver for deployment in step 2
# ============================================================================

# Configure Python for reticulate (needed for PepTools)
Sys.setenv(RETICULATE_PYTHON = "/opt/python/3.12.3/bin/python3")

library(torch)
library(tidyverse)
library(PepTools)

cat("=======================================================================\n")
cat("PEPTIDE BINDING PREDICTION - TORCH + VETIVER\n")
cat("=======================================================================\n\n")

# ============================================================================
# 1. Load and prepare data
# ============================================================================

cat("1. Loading peptide data...\n")
cat("---------------------------\n")

# Load training data
data("mhc_igh", package = "PepTools")

cat("Dataset shape:", nrow(mhc_igh), "samples\n")
cat("Peptide classes:\n")
print(table(mhc_igh$label))

# Encode peptides to numeric representation
encoded <- pep_encode(mhc_igh$peptide)
cat("\nEncoded shape:", dim(encoded), "(samples x amino_acids x properties)\n")

# Flatten the encoded peptides for neural network input
x <- array_reshape(encoded, c(nrow(encoded), 180L))
cat("Flattened shape:", dim(x), "(samples x features)\n")

# Add to dataset
mhc_igh$label_num <- as.numeric(factor(mhc_igh$label, levels = c("NB", "WB", "SB"))) - 1L
mhc_igh <- mhc_igh %>% bind_cols(as_tibble(x))

# ============================================================================
# 2. Split into train/test sets
# ============================================================================

cat("\n2. Splitting data...\n")
cat("---------------------\n")

# Encoding functions
encode_x <- function(x, type) {
  x %>%
    filter(data_type == {{ type }}) %>%
    select(-peptide, -label, -label_num, -data_type) %>%
    as.matrix()
}

encode_y <- function(x, type) {
  x %>%
    filter(data_type == {{ type }}) %>%
    pull(label_num) %>%
    as.integer()
}

# Prepare train and test sets
x_train <- encode_x(mhc_igh, "train")
y_train <- encode_y(mhc_igh, "train")
x_test <- encode_x(mhc_igh, "test")
y_test <- encode_y(mhc_igh, "test")

cat("Training set:", nrow(x_train), "samples\n")
cat("Test set:", nrow(x_test), "samples\n")

# Convert to torch tensors
x_train_tensor <- torch_tensor(x_train, dtype = torch_float32())
y_train_tensor <- torch_tensor(y_train, dtype = torch_long())
x_test_tensor <- torch_tensor(x_test, dtype = torch_float32())
y_test_tensor <- torch_tensor(y_test, dtype = torch_long())

# ============================================================================
# 3. Define the neural network
# ============================================================================

cat("\n3. Building neural network...\n")
cat("------------------------------\n")

# Define peptide binding network
peptide_net <- nn_module(
  "PeptideBindingNet",
  initialize = function() {
    self$fc1 <- nn_linear(180, 180)
    self$fc2 <- nn_linear(180, 90)
    self$fc3 <- nn_linear(90, 3)
    self$relu <- nn_relu()
    self$dropout1 <- nn_dropout(0.4)
    self$dropout2 <- nn_dropout(0.3)
  },
  forward = function(x) {
    x %>%
      self$fc1() %>%
      self$relu() %>%
      self$dropout1() %>%
      self$fc2() %>%
      self$relu() %>%
      self$dropout2() %>%
      self$fc3()
  }
)

# Instantiate the model
model <- peptide_net()

cat("Model architecture:\n")
cat("  Input: 180 features (9 amino acids × 20 properties)\n")
cat("  Hidden 1: 180 units + ReLU + Dropout(0.4)\n")
cat("  Hidden 2: 90 units + ReLU + Dropout(0.3)\n")
cat("  Output: 3 classes (NB, WB, SB)\n")

# ============================================================================
# 4. Configure training
# ============================================================================

cat("\n4. Configuring training...\n")
cat("---------------------------\n")

EPOCHS <- 50
LEARNING_RATE <- 0.001

criterion <- nn_cross_entropy_loss()
optimizer <- optim_adam(model$parameters, lr = LEARNING_RATE)

cat("Loss function: Cross Entropy\n")
cat("Optimizer: Adam (lr =", LEARNING_RATE, ")\n")
cat("Epochs:", EPOCHS, "\n")

# ============================================================================
# 5. Training loop with validation
# ============================================================================

cat("\n5. Training model...\n")
cat("---------------------\n")

# Split train into train/validation (80/20)
n_train <- nrow(x_train)
val_size <- floor(0.2 * n_train)
train_size <- n_train - val_size

indices <- sample(1:n_train)
train_indices <- indices[1:train_size]
val_indices <- indices[(train_size + 1):n_train]

x_train_split <- x_train_tensor[train_indices, ]
y_train_split <- y_train_tensor[train_indices]
x_val <- x_train_tensor[val_indices, ]
y_val <- y_train_tensor[val_indices]

# Store history
history <- list(
  train_loss = numeric(EPOCHS),
  train_acc = numeric(EPOCHS),
  val_loss = numeric(EPOCHS),
  val_acc = numeric(EPOCHS)
)

# Training loop
for (epoch in 1:EPOCHS) {

  # Training phase
  model$train()
  train_predictions <- model(x_train_split)
  train_loss <- criterion(train_predictions, y_train_split + 1L)

  optimizer$zero_grad()
  train_loss$backward()
  optimizer$step()

  # Calculate training accuracy
  pred_classes <- torch_argmax(train_predictions, dim = 2) - 1L
  train_accuracy <- (pred_classes == y_train_split)$to(dtype = torch_float32())$mean()$item()

  # Validation phase
  model$eval()
  with_no_grad({
    val_predictions <- model(x_val)
    val_loss <- criterion(val_predictions, y_val + 1L)

    val_pred_classes <- torch_argmax(val_predictions, dim = 2) - 1L
    val_accuracy <- (val_pred_classes == y_val)$to(dtype = torch_float32())$mean()$item()
  })

  # Store history
  history$train_loss[epoch] <- train_loss$item()
  history$train_acc[epoch] <- train_accuracy
  history$val_loss[epoch] <- val_loss$item()
  history$val_acc[epoch] <- val_accuracy

  # Print progress
  if (epoch %% 10 == 0) {
    cat(sprintf("Epoch %2d/%d - loss: %.4f - accuracy: %.4f - val_loss: %.4f - val_accuracy: %.4f\n",
                epoch, EPOCHS, train_loss$item(), train_accuracy, val_loss$item(), val_accuracy))
  }
}

cat("\n✓ Training complete!\n")

# ============================================================================
# 6. Evaluate on test set
# ============================================================================

cat("\n6. Evaluating on test set...\n")
cat("-----------------------------\n")

model$eval()
with_no_grad({
  test_predictions <- model(x_test_tensor)
  test_loss <- criterion(test_predictions, y_test_tensor + 1L)

  test_pred_classes <- torch_argmax(test_predictions, dim = 2) - 1L
  test_accuracy <- (test_pred_classes == y_test_tensor)$to(dtype = torch_float32())$mean()$item()
})

cat("Test loss:", sprintf("%.4f", test_loss$item()), "\n")
cat("Test accuracy:", sprintf("%.2f%%", test_accuracy * 100), "\n")

# ============================================================================
# 7. Visualize training history
# ============================================================================

cat("\n7. Plotting training history...\n")
cat("--------------------------------\n")

history_df <- tibble(
  epoch = rep(1:EPOCHS, 2),
  loss = c(history$train_loss, history$val_loss),
  accuracy = c(history$train_acc, history$val_acc),
  type = rep(c("Training", "Validation"), each = EPOCHS)
)

p1 <- ggplot(history_df, aes(x = epoch, y = loss, color = type)) +
  geom_line(size = 1) +
  labs(title = "Model Loss", x = "Epoch", y = "Loss", color = "") +
  theme_minimal()

p2 <- ggplot(history_df, aes(x = epoch, y = accuracy, color = type)) +
  geom_line(size = 1) +
  labs(title = "Model Accuracy", x = "Epoch", y = "Accuracy", color = "") +
  theme_minimal()

print(p1)
print(p2)

# ============================================================================
# 8. Confusion matrix
# ============================================================================

cat("\n8. Confusion matrix...\n")
cat("-----------------------\n")

test_pred_r <- as.integer(as_array(test_pred_classes))
peptide_classes <- c("NB", "WB", "SB")

conf_matrix <- table(
  Actual = factor(y_test, levels = 0:2, labels = peptide_classes),
  Predicted = factor(test_pred_r, levels = 0:2, labels = peptide_classes)
)

print(conf_matrix)

# ============================================================================
# 9. Save model
# ============================================================================

cat("\n9. Saving model...\n")
cat("-------------------\n")

torch_save(model, "peptide_model_torch.pt")
cat("✓ Model saved to: peptide_model_torch.pt\n")

cat("\n=======================================================================\n")
cat("✓ Model training complete!\n")
cat("  Next step: Run 2_version_model_vetiver.R to version with Vetiver\n")
cat("=======================================================================\n")
