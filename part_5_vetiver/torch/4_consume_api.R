# ============================================================================
# Consume Vetiver API - Torch Version
# ============================================================================
# Vetiver APIs use POST requests with JSON body (REST standard)
# This is different from the manual plumber API which used GET with query params
#
# SETUP: Set environment variables before running:
#   Sys.setenv(CONNECT_SERVER = "https://pub.workshop.posit.team")
#   Sys.setenv(CONNECT_API_KEY = "your-api-key")
#   Sys.setenv(VETIVER_ENDPOINT = "content/xyz-789")  # Get from Connect UI
# ============================================================================

# Configure Python for reticulate (needed for PepTools)
Sys.setenv(RETICULATE_PYTHON = "/opt/python/3.12.3/bin/python3")

library(vetiver)
library(httr)
library(PepTools)
library(rsconnect)

cat("=======================================================================\n")
cat("CONSUMING VETIVER API - TORCH VERSION\n")
cat("=======================================================================\n\n")

# ============================================================================
# 1. Configuration
# ============================================================================

cat("1. Checking configuration...\n")
cat("-----------------------------\n")

server_url <- Sys.getenv("CONNECT_SERVER", "https://pub.workshop.posit.team")
api_key <- Sys.getenv("CONNECT_API_KEY")

if (api_key == "") {
  stop("\n*** SET CONNECT_API_KEY FIRST ***\n\n",
       "  Sys.setenv(CONNECT_API_KEY = 'your-api-key')\n")
}

# Auto-detect endpoint from rsconnect deployment records
endpoint <- Sys.getenv("VETIVER_ENDPOINT")
if (endpoint == "") {
  cat("Auto-detecting API endpoint...\n")

  # Check for deployment records in current directory
  if (file.exists("rsconnect")) {
    deployments <- rsconnect::deployments(".")
    if (nrow(deployments) > 0) {
      # Extract content GUID from URL
      guid <- sub(".*/content/([^/]+).*", "\\1", deployments$url[1])
      endpoint <- paste0("content/", guid)
      cat("✓ Auto-detected endpoint:", endpoint, "\n")
    }
  }

  if (endpoint == "") {
    stop("\n*** COULD NOT AUTO-DETECT ENDPOINT ***\n\n",
         "Either:\n",
         "  1. Run from the deployment directory, OR\n",
         "  2. Set manually: Sys.setenv(VETIVER_ENDPOINT = 'content/xyz-789')\n")
  }
}

full_url <- file.path(server_url, endpoint)
cat("API URL:", full_url, "\n")

# ============================================================================
# 2. Create vetiver endpoint object
# ============================================================================

cat("\n2. Creating API endpoint...\n")
cat("---------------------------\n")

# Vetiver provides a helper to create endpoint
api_endpoint <- vetiver_endpoint(full_url)

cat("✓ Endpoint created\n")

# ============================================================================
# 3. Test /ping endpoint (health check)
# ============================================================================

cat("\n3. Testing /ping endpoint...\n")
cat("----------------------------\n")

ping_url <- file.path(full_url, "ping")
response <- httr::GET(
  ping_url,
  httr::add_headers(Authorization = paste0("Key ", api_key))
)

if (response$status_code == 200) {
  cat("✓ API is alive and responding\n")
} else {
  cat("⚠ API responded with status:", response$status_code, "\n")
}

# ============================================================================
# 4. Test /metadata endpoint
# ============================================================================

cat("\n4. Testing /metadata endpoint...\n")
cat("--------------------------------\n")

meta_url <- file.path(full_url, "metadata")
response <- httr::GET(
  meta_url,
  httr::add_headers(Authorization = paste0("Key ", api_key))
)

if (response$status_code == 200) {
  metadata <- httr::content(response)
  cat("✓ Model metadata:\n")
  cat("  Model name:", metadata$model_name, "\n")
  cat("  Description:", metadata$description, "\n")
} else {
  cat("⚠ Could not retrieve metadata\n")
}

# ============================================================================
# 5. Prepare prediction data
# ============================================================================

cat("\n5. Preparing prediction data...\n")
cat("--------------------------------\n")

# Test peptides
test_peptides <- c("LLTDAQRIV", "LMAFYLYEV", "VMSPITLPT", "SLHLTNCFV", "RQFTCMIAV")

cat("Test peptides:\n")
for (i in seq_along(test_peptides)) {
  cat("  ", i, ":", test_peptides[i], "\n")
}

# Encode peptides
encoded <- pep_encode(test_peptides)
x_val <- array_reshape(encoded, c(as.integer(nrow(encoded)), 180L))

# Convert to data frame (Vetiver expects data frames)
input_df <- as.data.frame(x_val)
colnames(input_df) <- paste0("V", 1:180)

cat("\nInput shape:", nrow(input_df), "peptides x", ncol(input_df), "features\n")

# ============================================================================
# 6. Make predictions with Vetiver helper
# ============================================================================

cat("\n6. Making predictions with Vetiver...\n")
cat("--------------------------------------\n")

# Vetiver's predict method handles the POST request
predictions <- predict(
  api_endpoint,
  input_df,
  httr::add_headers(Authorization = paste0("Key ", api_key))
)

cat("✓ Predictions received\n")

# ============================================================================
# 7. Post-process predictions
# ============================================================================

cat("\n7. Processing predictions...\n")
cat("----------------------------\n")

# Vetiver returns raw predictions (logits for torch model)
# Convert to class predictions
peptide_classes <- c("NB", "WB", "SB")

# predictions should be a matrix with 3 columns (one per class)
if (is.matrix(predictions) || is.data.frame(predictions)) {
  pred_classes <- apply(as.matrix(predictions), 1, which.max)
  predicted_labels <- peptide_classes[pred_classes]
} else {
  # Fallback if format is different
  predicted_labels <- rep("Unknown", length(test_peptides))
}

# Create results tibble
results <- tibble::tibble(
  peptide = test_peptides,
  predicted_class = predicted_labels
)

cat("\nPrediction Results:\n")
print(results)

# ============================================================================
# 8. Manual prediction (alternative method)
# ============================================================================

cat("\n8. Alternative: Manual POST request...\n")
cat("---------------------------------------\n")

# You can also call the API manually with httr
predict_url <- file.path(full_url, "predict")

response <- httr::POST(
  predict_url,
  body = input_df,
  encode = "json",
  httr::content_type_json(),
  httr::add_headers(Authorization = paste0("Key ", api_key))
)

if (response$status_code == 200) {
  manual_predictions <- httr::content(response)
  cat("✓ Manual prediction successful\n")
  cat("Response format:", class(manual_predictions), "\n")
} else {
  cat("⚠ Manual prediction failed with status:", response$status_code, "\n")
}

cat("\n=======================================================================\n")
cat("✓ Vetiver API consumption complete!\n")
cat("\nKey Differences from Manual Plumber API:\n")
cat("  • POST request (not GET)\n")
cat("  • JSON body with data frame (not query params)\n")
cat("  • Built-in /ping and /metadata endpoints\n")
cat("  • Vetiver helper functions for predictions\n")
cat("  • Standardized REST API format\n")
cat("=======================================================================\n")
