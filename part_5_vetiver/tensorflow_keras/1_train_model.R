# ============================================================================
# Train Peptide Binding Prediction Model with Keras (Vetiver Version)
# ============================================================================
# This is identical to part_3/immunotherapy/1_train_model.R
# We train the model here, then use Vetiver for deployment in step 2
# ============================================================================

# Configure Python for reticulate
Sys.setenv(RETICULATE_PYTHON = "/opt/python/3.12.3/bin/python3")

library(keras)
library(tidyverse)
library(PepTools)

cat("=======================================================================\n")
cat("PEPTIDE BINDING PREDICTION - KERAS + VETIVER\n")
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
  y <- x %>%
    filter(data_type == {{ type }}) %>%
    pull(label_num)
  y <- as.integer(as.numeric(y))
  if (min(y) == 1) {
    y <- y - 1L
  }
  keras$utils$to_categorical(y, num_classes = 3L)
}

# Prepare train and test sets
x_train <- encode_x(mhc_igh, "train")
y_train <- encode_y(mhc_igh, "train")
x_test <- encode_x(mhc_igh, "test")
y_test <- encode_y(mhc_igh, "test")

cat("Training set:", nrow(x_train), "samples\n")
cat("Test set:", nrow(x_test), "samples\n")

# ============================================================================
# 3. Build the neural network
# ============================================================================

cat("\n3. Building neural network...\n")
cat("------------------------------\n")

EPOCHS <- 50

model <- keras_model_sequential(
  list(
    layer_input(shape = c(180L)),
    layer_dense(units = 180L, activation = "relu"),
    layer_dropout(rate = 0.4),
    layer_dense(units = 90L, activation = "relu"),
    layer_dropout(rate = 0.3),
    layer_dense(units = 3L, activation = "softmax")
  )
)

cat("Model architecture:\n")
cat("  Input: 180 features (9 amino acids × 20 properties)\n")
cat("  Hidden 1: 180 units + ReLU + Dropout(0.4)\n")
cat("  Hidden 2: 90 units + ReLU + Dropout(0.3)\n")
cat("  Output: 3 classes (NB, WB, SB)\n")

# ============================================================================
# 4. Compile and train
# ============================================================================

cat("\n4. Compiling and training...\n")
cat("-----------------------------\n")

model$compile(
  loss = "categorical_crossentropy",
  optimizer = optimizer_rmsprop(learning_rate = 0.001),
  metrics = list("accuracy")
)

history <- model$fit(
  x = x_train,
  y = y_train,
  epochs = as.integer(EPOCHS),
  batch_size = 64L,
  validation_split = 0.2,
  verbose = 1L
)

cat("\n✓ Training complete!\n")

# ============================================================================
# 5. Evaluate on test set
# ============================================================================

cat("\n5. Evaluating on test set...\n")
cat("-----------------------------\n")

test_metrics <- model$evaluate(x_test, y_test, verbose = 0L)
cat("Test loss:", sprintf("%.4f", test_metrics[[1]]), "\n")
cat("Test accuracy:", sprintf("%.2f%%", test_metrics[[2]] * 100), "\n")

# ============================================================================
# 6. Visualize training history
# ============================================================================

cat("\n6. Plotting training history...\n")
cat("--------------------------------\n")

history_df <- data.frame(
  epoch = rep(1:length(history$history$loss), 4),
  value = c(
    unlist(history$history$loss),
    unlist(history$history$val_loss),
    unlist(history$history$accuracy),
    unlist(history$history$val_accuracy)
  ),
  metric = rep(c("loss", "loss", "accuracy", "accuracy"), each = length(history$history$loss)),
  type = rep(c("Training", "Validation", "Training", "Validation"), each = length(history$history$loss))
)

p <- ggplot(history_df, aes(x = epoch, y = value, color = type)) +
  geom_line(size = 1) +
  facet_wrap(~metric, scales = "free_y", ncol = 1) +
  labs(title = "Model Training History", x = "Epoch", y = "", color = "") +
  theme_minimal()

print(p)

# ============================================================================
# 7. Predictions and confusion matrix
# ============================================================================

cat("\n7. Confusion matrix...\n")
cat("-----------------------\n")

predictions <- model$predict(x_test, verbose = 0)
y_pred <- apply(predictions, 1, which.max) - 1
y_actual <- apply(y_test, 1, which.max) - 1

peptide_classes <- c("NB", "WB", "SB")
conf_matrix <- table(
  Actual = factor(y_actual, levels = 0:2, labels = peptide_classes),
  Predicted = factor(y_pred, levels = 0:2, labels = peptide_classes)
)

print(conf_matrix)

# ============================================================================
# 8. Save model
# ============================================================================

cat("\n8. Saving model...\n")
cat("-------------------\n")

keras$saving$save_model(model, "peptide_model_keras.keras")
cat("✓ Model saved to: peptide_model_keras.keras\n")

cat("\n=======================================================================\n")
cat("✓ Model training complete!\n")
cat("  Next step: Run 2_version_model_vetiver.R to version with Vetiver\n")
cat("=======================================================================\n")
