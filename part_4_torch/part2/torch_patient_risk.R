# ============================================================================
# Torch Patient Risk Prediction - Binary Classification
# ============================================================================
# Healthcare example: Predict patient risk based on clinical features
# This demonstrates binary classification for medical decision support
#
# Real-world applications:
# - Hospital readmission prediction
# - Disease risk assessment
# - Treatment response prediction
# - Clinical trial patient selection
# ============================================================================

library(torch)
library(tidyverse)

cat("=======================================================================\n")
cat("PATIENT RISK PREDICTION WITH TORCH\n")
cat("=======================================================================\n\n")

# ============================================================================
# 1. Generate synthetic patient data
# ============================================================================

cat("1. Generating patient clinical data...\n")
cat("---------------------------------------\n")

generate_patient_data <- function(n = 500) {
  # Simulate patient features
  age <- rnorm(n, mean = 60, sd = 15)
  age <- pmax(18, pmin(95, age)) # Clip to realistic range

  bmi <- rnorm(n, mean = 28, sd = 6)
  bmi <- pmax(15, pmin(50, bmi))

  blood_pressure <- rnorm(n, mean = 130, sd = 20)
  blood_pressure <- pmax(90, pmin(180, blood_pressure))

  glucose <- rnorm(n, mean = 110, sd = 30)
  glucose <- pmax(70, pmin(200, glucose))

  # Risk increases with age, high BMI, high BP, and high glucose
  risk_score <- 0.05 * age + 0.1 * bmi + 0.02 * blood_pressure + 0.01 * glucose

  # Add noise and convert to binary outcome
  risk_score <- risk_score + rnorm(n, mean = 0, sd = 5)
  high_risk <- as.integer(risk_score > median(risk_score))

  tibble(
    age = age,
    bmi = bmi,
    blood_pressure = blood_pressure,
    glucose = glucose,
    high_risk = high_risk
  )
}

# Generate training and test data
set.seed(123)
train_data <- generate_patient_data(n = 400)
test_data <- generate_patient_data(n = 100)

cat("Training samples:", nrow(train_data), "\n")
cat("Test samples:", nrow(test_data), "\n")
cat("\nClass distribution (training):\n")
print(table(train_data$high_risk))

# Visualize relationships
p1 <- train_data %>%
  ggplot(aes(x = age, y = bmi, color = factor(high_risk))) +
  geom_point(alpha = 0.6, size = 2) +
  scale_color_manual(values = c("0" = "green", "1" = "red"),
                     labels = c("Low Risk", "High Risk")) +
  labs(
    title = "Patient Risk by Age and BMI",
    x = "Age (years)",
    y = "BMI (kg/m²)",
    color = "Risk Category"
  ) +
  theme_minimal()

print(p1)

# ============================================================================
# 2. Prepare data for torch
# ============================================================================

cat("\n2. Preparing tensors...\n")
cat("------------------------\n")

# Standardize features (important for neural networks)
feature_names <- c("age", "bmi", "blood_pressure", "glucose")

# Calculate mean and SD from training data
means <- train_data %>% select(all_of(feature_names)) %>% summarise(across(everything(), mean))
sds <- train_data %>% select(all_of(feature_names)) %>% summarise(across(everything(), sd))

# Standardize
standardize <- function(data, means, sds) {
  data %>%
    mutate(
      age = (age - means$age) / sds$age,
      bmi = (bmi - means$bmi) / sds$bmi,
      blood_pressure = (blood_pressure - means$blood_pressure) / sds$blood_pressure,
      glucose = (glucose - means$glucose) / sds$glucose
    )
}

train_std <- standardize(train_data, means, sds)
test_std <- standardize(test_data, means, sds)

# Convert to tensors
x_train <- torch_tensor(
  as.matrix(train_std[, feature_names]),
  dtype = torch_float32()
)
y_train <- torch_tensor(train_std$high_risk, dtype = torch_float32())$unsqueeze(2)

x_test <- torch_tensor(
  as.matrix(test_std[, feature_names]),
  dtype = torch_float32()
)
y_test <- torch_tensor(test_std$high_risk, dtype = torch_float32())$unsqueeze(2)

cat("Training input shape:", dim(x_train), "\n")
cat("Training output shape:", dim(y_train), "\n")

# ============================================================================
# 3. Define the neural network
# ============================================================================

cat("\n3. Building neural network...\n")
cat("------------------------------\n")

# Define patient risk network
risk_net <- nn_module(
  "PatientRiskNet",
  initialize = function() {
    self$fc1 <- nn_linear(4, 16)
    self$fc2 <- nn_linear(16, 8)
    self$fc3 <- nn_linear(8, 1)
    self$relu <- nn_relu()
    self$dropout <- nn_dropout(0.2)
    self$sigmoid <- nn_sigmoid()
  },
  forward = function(x) {
    x %>%
      self$fc1() %>%
      self$relu() %>%
      self$dropout() %>%
      self$fc2() %>%
      self$relu() %>%
      self$dropout() %>%
      self$fc3() %>%
      self$sigmoid()
  }
)

# Instantiate the model
model <- risk_net()

cat("Model architecture:\n")
cat("  Input layer: 4 clinical features\n")
cat("  Hidden layer 1: 16 units + ReLU + Dropout(0.2)\n")
cat("  Hidden layer 2: 8 units + ReLU + Dropout(0.2)\n")
cat("  Output layer: 1 probability (sigmoid)\n")

# ============================================================================
# 4. Configure training
# ============================================================================

cat("\n4. Configuring training...\n")
cat("---------------------------\n")

# Loss function and optimizer
criterion <- nn_bce_loss() # Binary Cross Entropy
optimizer <- optim_adam(model$parameters, lr = 0.001)

# Training parameters
n_epochs <- 100

cat("Loss function: Binary Cross Entropy\n")
cat("Optimizer: Adam (lr = 0.001)\n")
cat("Epochs:", n_epochs, "\n")

# ============================================================================
# 5. Training loop
# ============================================================================

cat("\n5. Training model...\n")
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
  predictions <- model(x_train)
  loss <- criterion(predictions, y_train)

  # Backward pass
  optimizer$zero_grad()
  loss$backward()
  optimizer$step()

  # Calculate accuracy
  pred_binary <- (predictions > 0.5)$to(dtype = torch_float32())
  accuracy <- (pred_binary == y_train)$to(dtype = torch_float32())$mean()$item()

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
# 6. Evaluate on test set
# ============================================================================

cat("\n6. Evaluating on test set...\n")
cat("-----------------------------\n")

model$eval()
with_no_grad({
  test_predictions <- model(x_test)
  test_loss <- criterion(test_predictions, y_test)

  test_pred_binary <- (test_predictions > 0.5)$to(dtype = torch_float32())
  test_accuracy <- (test_pred_binary == y_test)$to(dtype = torch_float32())$mean()$item()
})

cat("Test loss:", sprintf("%.4f", test_loss$item()), "\n")
cat("Test accuracy:", sprintf("%.2f%%", test_accuracy * 100), "\n")

# ============================================================================
# 7. Calculate additional metrics
# ============================================================================

cat("\n7. Calculating clinical metrics...\n")
cat("-----------------------------------\n")

# Convert to R vectors
test_pred_r <- as.numeric(as_array(test_pred_binary))
test_actual_r <- as.numeric(as_array(y_test))

# Confusion matrix
conf_matrix <- table(
  Actual = factor(test_actual_r, levels = c(0, 1), labels = c("Low Risk", "High Risk")),
  Predicted = factor(test_pred_r, levels = c(0, 1), labels = c("Low Risk", "High Risk"))
)

print(conf_matrix)

# Calculate sensitivity, specificity, PPV, NPV
tp <- conf_matrix[2, 2] # True positives
tn <- conf_matrix[1, 1] # True negatives
fp <- conf_matrix[1, 2] # False positives
fn <- conf_matrix[2, 1] # False negatives

sensitivity <- tp / (tp + fn)
specificity <- tn / (tn + fp)
ppv <- tp / (tp + fp)
npv <- tn / (tn + fn)

cat("\nClinical Performance Metrics:\n")
cat(sprintf("  Sensitivity (recall): %.2f%%\n", sensitivity * 100))
cat(sprintf("  Specificity: %.2f%%\n", specificity * 100))
cat(sprintf("  PPV (precision): %.2f%%\n", ppv * 100))
cat(sprintf("  NPV: %.2f%%\n", npv * 100))

# ============================================================================
# 8. Visualize results
# ============================================================================

cat("\n8. Visualizing predictions...\n")
cat("------------------------------\n")

# Plot training history
history_df <- tibble(
  epoch = rep(1:n_epochs, 2),
  value = c(history$train_loss, history$train_acc),
  metric = rep(c("Loss", "Accuracy"), each = n_epochs)
)

p2 <- ggplot(history_df, aes(x = epoch, y = value, color = metric)) +
  geom_line(size = 1) +
  facet_wrap(~metric, scales = "free_y", ncol = 1) +
  labs(title = "Training History", x = "Epoch", y = "") +
  theme_minimal() +
  theme(legend.position = "none")

print(p2)

# Confusion matrix visualization
conf_df <- as.data.frame(conf_matrix)

p3 <- ggplot(conf_df, aes(x = Predicted, y = Actual, fill = Freq)) +
  geom_tile() +
  geom_text(aes(label = Freq), color = "white", size = 6) +
  scale_fill_gradient(low = "lightblue", high = "darkblue") +
  labs(title = "Confusion Matrix - Patient Risk Prediction") +
  theme_minimal()

print(p3)

# ============================================================================
# 9. Feature importance (simple approach)
# ============================================================================

cat("\n9. Estimating feature importance...\n")
cat("------------------------------------\n")

# Get first layer weights (rough approximation of importance)
weights <- as_array(model$fc1$weight)
importance <- colMeans(abs(weights))
names(importance) <- feature_names

importance_df <- tibble(
  feature = names(importance),
  importance = importance
) %>%
  arrange(desc(importance))

print(importance_df)

p4 <- ggplot(importance_df, aes(x = reorder(feature, importance), y = importance)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(
    title = "Feature Importance (First Layer Weights)",
    x = "Clinical Feature",
    y = "Importance Score"
  ) +
  theme_minimal()

print(p4)

# ============================================================================
# 10. Save model
# ============================================================================

cat("\n10. Saving model...\n")
cat("--------------------\n")

torch_save(model, "patient_risk_model.pt")
cat("✓ Model saved to: patient_risk_model.pt\n")

cat("\n=======================================================================\n")
cat("✓ Patient risk prediction complete!\n")
cat("\nHealthcare Applications:\n")
cat("  • Hospital readmission prediction\n")
cat("  • Disease progression forecasting\n")
cat("  • Treatment response prediction\n")
cat("  • Clinical decision support\n")
cat("=======================================================================\n")
