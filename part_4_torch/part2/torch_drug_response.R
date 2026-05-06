# ============================================================================
# Torch Drug Response Prediction - Dose-Response Curves
# ============================================================================
# Pharmaceutical example: Predict drug response based on concentration
# This models the classic S-shaped dose-response curve using neural networks
#
# Real-world application:
# - Predict IC50 values (drug concentration for 50% inhibition)
# - Model drug efficacy across concentrations
# - Optimize dosing strategies
# ============================================================================

library(torch)
library(tidyverse)

cat("=======================================================================\n")
cat("DRUG DOSE-RESPONSE PREDICTION WITH TORCH\n")
cat("=======================================================================\n\n")

# ============================================================================
# 1. Generate synthetic dose-response data
# ============================================================================

cat("1. Generating dose-response data...\n")
cat("------------------------------------\n")

# Sigmoid dose-response function: R = R_max / (1 + (IC50/D)^h)
# R = response, D = dose, IC50 = half-maximal concentration, h = Hill coefficient
generate_dose_response <- function(n = 200, IC50 = 5, h = 2, R_max = 100, noise = 5) {
  dose <- runif(n, min = 0.1, max = 20)
  response <- R_max / (1 + (IC50 / dose)^h) + rnorm(n, mean = 0, sd = noise)
  tibble(dose = dose, response = response)
}

# Generate training and test data
set.seed(42)
train_data <- generate_dose_response(n = 200)
test_data <- generate_dose_response(n = 50)

cat("Training samples:", nrow(train_data), "\n")
cat("Test samples:", nrow(test_data), "\n")

# Visualize the data
p1 <- ggplot(train_data, aes(x = dose, y = response)) +
  geom_point(alpha = 0.5, color = "steelblue") +
  labs(
    title = "Drug Dose-Response Data",
    x = "Drug Concentration (μM)",
    y = "Response (%)",
    subtitle = "Classic S-shaped curve with noise"
  ) +
  theme_minimal()

print(p1)

# ============================================================================
# 2. Prepare data for torch
# ============================================================================

cat("\n2. Preparing tensors...\n")
cat("------------------------\n")

# Convert to tensors
x_train <- torch_tensor(matrix(train_data$dose, ncol = 1), dtype = torch_float32())
y_train <- torch_tensor(matrix(train_data$response, ncol = 1), dtype = torch_float32())
x_test <- torch_tensor(matrix(test_data$dose, ncol = 1), dtype = torch_float32())
y_test <- torch_tensor(matrix(test_data$response, ncol = 1), dtype = torch_float32())

cat("Training input shape:", dim(x_train), "\n")
cat("Training output shape:", dim(y_train), "\n")

# ============================================================================
# 3. Define the neural network
# ============================================================================

cat("\n3. Building neural network...\n")
cat("------------------------------\n")

# Define dose-response network
dose_response_net <- nn_module(
  "DoseResponseNet",
  initialize = function() {
    self$fc1 <- nn_linear(1, 20)
    self$fc2 <- nn_linear(20, 20)
    self$fc3 <- nn_linear(20, 1)
    self$relu <- nn_relu()
  },
  forward = function(x) {
    x %>%
      self$fc1() %>%
      self$relu() %>%
      self$fc2() %>%
      self$relu() %>%
      self$fc3()
  }
)

# Instantiate the model
model <- dose_response_net()

cat("Model architecture:\n")
cat("  Input layer: 1 feature (dose)\n")
cat("  Hidden layer 1: 20 units + ReLU\n")
cat("  Hidden layer 2: 20 units + ReLU\n")
cat("  Output layer: 1 prediction (response)\n")

# ============================================================================
# 4. Configure training
# ============================================================================

cat("\n4. Configuring training...\n")
cat("---------------------------\n")

# Loss function and optimizer
criterion <- nn_mse_loss()
optimizer <- optim_adam(model$parameters, lr = 0.01)

# Training parameters
n_epochs <- 500

cat("Loss function: MSE (Mean Squared Error)\n")
cat("Optimizer: Adam (lr = 0.01)\n")
cat("Epochs:", n_epochs, "\n")

# ============================================================================
# 5. Training loop
# ============================================================================

cat("\n5. Training model...\n")
cat("---------------------\n")

# Store history
history <- list(
  train_loss = numeric(n_epochs)
)

# Training loop
model$train()
for (epoch in 1:n_epochs) {

  # Forward pass
  predictions <- model(x_train)
  loss <- criterion(predictions, y_train)

  # Backward pass
  optimizer$zero_grad()
  loss$backward()
  optimizer$step()

  # Store history
  history$train_loss[epoch] <- loss$item()

  # Print progress every 50 epochs
  if (epoch %% 50 == 0) {
    cat(sprintf("Epoch %3d/%d - loss: %.4f\n", epoch, n_epochs, loss$item()))
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
  test_predictions <- model(x_test)
  test_loss <- criterion(test_predictions, y_test)
})

cat("Test loss (MSE):", sprintf("%.4f", test_loss$item()), "\n")

# Calculate R-squared
test_pred_r <- as.numeric(as_array(test_predictions))
test_actual_r <- as.numeric(as_array(y_test))
ss_res <- sum((test_actual_r - test_pred_r)^2)
ss_tot <- sum((test_actual_r - mean(test_actual_r))^2)
r_squared <- 1 - (ss_res / ss_tot)

cat("R-squared:", sprintf("%.4f", r_squared), "\n")

# ============================================================================
# 7. Visualize results
# ============================================================================

cat("\n7. Visualizing predictions...\n")
cat("------------------------------\n")

# Generate smooth curve for visualization
dose_seq <- seq(0.1, 20, length.out = 200)
dose_tensor <- torch_tensor(matrix(dose_seq, ncol = 1), dtype = torch_float32())

model$eval()
with_no_grad({
  response_pred <- model(dose_tensor)
})

response_seq <- as.numeric(as_array(response_pred))

# Create prediction dataframe
pred_df <- tibble(
  dose = dose_seq,
  response = response_seq
)

# Plot predictions vs actual
p2 <- ggplot() +
  geom_point(data = train_data, aes(x = dose, y = response),
             alpha = 0.5, color = "steelblue", size = 2) +
  geom_line(data = pred_df, aes(x = dose, y = response),
            color = "red", size = 1) +
  labs(
    title = "Drug Dose-Response: Predictions vs Actual",
    x = "Drug Concentration (μM)",
    y = "Response (%)",
    subtitle = "Red line = Neural network prediction, Blue points = Training data"
  ) +
  theme_minimal()

print(p2)

# Plot with test data
p3 <- ggplot() +
  geom_line(data = pred_df, aes(x = dose, y = response),
            color = "red", size = 1) +
  geom_point(data = train_data, aes(x = dose, y = response),
             alpha = 0.3, color = "steelblue", size = 2) +
  geom_point(data = test_data, aes(x = dose, y = response),
             alpha = 0.7, color = "darkgreen", size = 3) +
  labs(
    title = "Model Generalization",
    x = "Drug Concentration (μM)",
    y = "Response (%)",
    subtitle = "Red = Prediction, Blue = Training, Green = Test"
  ) +
  theme_minimal()

print(p3)

# ============================================================================
# 8. Training history
# ============================================================================

cat("\n8. Plotting training history...\n")
cat("--------------------------------\n")

history_df <- tibble(
  epoch = 1:n_epochs,
  loss = history$train_loss
)

p4 <- ggplot(history_df, aes(x = epoch, y = loss)) +
  geom_line(color = "blue", size = 1) +
  labs(title = "Training Loss Over Time", x = "Epoch", y = "MSE Loss") +
  theme_minimal()

print(p4)

# ============================================================================
# 9. Save model
# ============================================================================

cat("\n9. Saving model...\n")
cat("-------------------\n")

torch_save(model, "drug_response_model.pt")
cat("✓ Model saved to: drug_response_model.pt\n")

cat("\n=======================================================================\n")
cat("✓ Drug dose-response prediction complete!\n")
cat("\nPharmaceutical Applications:\n")
cat("  • IC50 determination\n")
cat("  • Dose optimization\n")
cat("  • Drug efficacy prediction\n")
cat("  • Combination therapy modeling\n")
cat("=======================================================================\n")
