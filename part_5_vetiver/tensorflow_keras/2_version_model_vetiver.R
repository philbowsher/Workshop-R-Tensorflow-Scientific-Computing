# ============================================================================
# Version and Pin Keras Model with Vetiver
# ============================================================================
# This uses Vetiver to:
# 1. Create a vetiver model object (with metadata)
# 2. Version and pin to Posit Connect
# 3. Automatically handle model serialization
#
# SETUP: Before running, set environment variables in R console:
#   Sys.setenv(CONNECT_SERVER = "https://pub.workshop.posit.team")
#   Sys.setenv(CONNECT_API_KEY = "your-api-key")
# ============================================================================

# Configure Python for reticulate
Sys.setenv(RETICULATE_PYTHON = "/opt/python/3.12.3/bin/python3")

library(vetiver)
library(pins)
library(keras)
library(httr)

cat("=======================================================================\n")
cat("VERSIONING MODEL WITH VETIVER\n")
cat("=======================================================================\n\n")

# ============================================================================
# 1. Configuration
# ============================================================================

cat("1. Checking configuration...\n")
cat("-----------------------------\n")

server_url <- Sys.getenv("CONNECT_SERVER")
api_key <- Sys.getenv("CONNECT_API_KEY")

if (server_url == "" || api_key == "") {
  stop("\n*** SET ENVIRONMENT VARIABLES FIRST ***\n\n",
       "Run these commands before running this file:\n\n",
       "  Sys.setenv(CONNECT_SERVER = 'https://pub.workshop.posit.team')\n",
       "  Sys.setenv(CONNECT_API_KEY = 'your-api-key')\n\n",
       "Get your API key from: https://pub.workshop.posit.team → Your name → API Keys → New")
}

cat("Server:", server_url, "\n")
cat("API key: ***", substr(api_key, nchar(api_key) - 3, nchar(api_key)), "\n")

# Get Connect username from API for authentication
connect_user <- httr::GET(
  paste0(server_url, "/__api__/v1/user"),
  httr::add_headers(Authorization = paste("Key", api_key))
) |> httr::content()

# Generate or retrieve anonymous workshop ID (no private info exposed)
workshop_id <- Sys.getenv("WORKSHOP_USER_ID")
if (workshop_id == "") {
  hash_val <- sum(utf8ToInt(connect_user$username)) %% 999999
  workshop_id <- sprintf("user%06d", hash_val)
  Sys.setenv(WORKSHOP_USER_ID = workshop_id)
  cat("✓ Generated workshop ID:", workshop_id, "\n")
  cat("  (Anonymous - no personal info)\n")
} else {
  cat("✓ Using workshop ID:", workshop_id, "\n")
}

# ============================================================================
# 2. Load trained model
# ============================================================================

cat("\n2. Loading trained model...\n")
cat("----------------------------\n")

model_path <- "peptide_model_keras.keras"

if (!file.exists(model_path)) {
  stop("Model file not found: ", model_path, "\n",
       "Run 1_train_model.R first to train and save the model.")
}

model <- keras$saving$load_model(model_path)
cat("✓ Model loaded from:", model_path, "\n")

# ============================================================================
# 3. Create Vetiver model object
# ============================================================================

cat("\n3. Creating Vetiver model...\n")
cat("-----------------------------\n")

# Create vetiver model with metadata
# Model name includes anonymous workshop ID for multi-user environment
model_name <- paste0(connect_user$username, "/peptide_keras_vetiver_", workshop_id)

v <- vetiver_model(
  model = model,
  model_name = model_name,
  description = paste0("Peptide-MHC binding prediction model (Keras + Vetiver) - ", workshop_id),
  metadata = list(
    framework = "keras",
    classes = c("NB", "WB", "SB"),
    input_features = 180,
    accuracy = "~95%",
    workshop_id = workshop_id
  )
)

cat("✓ Vetiver model created\n")
cat("  Model name:", v$model_name, "\n")
cat("  Workshop ID:", workshop_id, "\n")
cat("  Description:", v$description, "\n")

# ============================================================================
# 4. Connect to Posit Connect board
# ============================================================================

cat("\n4. Connecting to Posit Connect...\n")
cat("----------------------------------\n")

board <- board_connect()
cat("✓ Connected to board\n")

# ============================================================================
# 5. Pin the vetiver model
# ============================================================================

cat("\n5. Pinning model to Connect...\n")
cat("-------------------------------\n")

# Vetiver automatically handles versioning
vetiver_pin_write(
  board = board,
  vetiver_model = v
)

cat("\n✓ Model pinned successfully!\n")

# ============================================================================
# 6. Verify the pin
# ============================================================================

cat("\n6. Verifying pin...\n")
cat("--------------------\n")

# List pins to verify
pins_list <- pin_list(board)
if (model_name %in% pins_list) {
  cat("✓ Pin available:", model_name, "\n")

  # Get pin metadata
  meta <- pin_meta(board, model_name)
  cat("Pin created:", meta$created, "\n")

  # Read back the vetiver model
  v_retrieved <- vetiver_pin_read(board, model_name)
  cat("✓ Model can be read back successfully\n")
  cat("  Retrieved model name:", v_retrieved$model_name, "\n")
} else {
  cat("⚠ Pin not found in list\n")
}

cat("\n=======================================================================\n")
cat("✓ Model versioned with Vetiver!\n")
cat("\nWhat Vetiver did for you:\n")
cat("  • Created model card with metadata\n")
cat("  • Handled serialization automatically\n")
cat("  • Enabled versioning (pin versions tracked)\n")
cat("  • Prepared for automated API deployment\n")
cat("\n  Next step: Run 3_deploy_api_vetiver.R to deploy API\n")
cat("=======================================================================\n")
