# ============================================================================
# Publish Torch Model to Posit Connect via Pins
# ============================================================================
# This pins the trained torch model so the Plumber API can download it
#
# SETUP: Before running, set environment variables in R console:
#   Sys.setenv(CONNECT_SERVER = "https://pub.workshop.posit.team")
#   Sys.setenv(CONNECT_API_KEY = "your-api-key")
#
# Then run this script to pin the model to Connect
# ============================================================================

library(pins)

cat("=======================================================================\n")
cat("PUBLISHING TORCH MODEL TO POSIT CONNECT\n")
cat("=======================================================================\n\n")

# ============================================================================
# 1. Configuration
# ============================================================================

cat("1. Checking configuration...\n")
cat("-----------------------------\n")

# Get environment variables
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

# ============================================================================
# 2. Connect to Posit Connect
# ============================================================================

cat("\n2. Connecting to Posit Connect...\n")
cat("----------------------------------\n")

con <- pins::board_connect()
cat("✓ Connected to board\n")

# ============================================================================
# 3. Pin the model
# ============================================================================

cat("\n3. Uploading torch model...\n")
cat("----------------------------\n")

model_path <- "peptide_model_torch.pt"

if (!file.exists(model_path)) {
  stop("Model file not found: ", model_path, "\n",
       "Run 1_train_model.R first to train and save the model.")
}

cat("Model file:", model_path, "\n")
cat("File size:", file.size(model_path), "bytes\n")

# Upload the model to Connect
pins::pin_upload(
  board = con,
  paths = model_path,
  name = "peptide_model_torch",
  title = "Peptide Binding Prediction Model (Torch)",
  description = "Neural network model for predicting peptide-MHC binding affinity (Torch format)",
  type = "rds"
)

cat("\n✓ Model pinned successfully!\n")

# ============================================================================
# 4. Verify the pin
# ============================================================================

cat("\n4. Verifying pin...\n")
cat("--------------------\n")

# List pins to verify
pins_list <- pins::pin_list(con)
if ("peptide_model_torch" %in% pins_list) {
  cat("✓ Pin 'peptide_model_torch' is available\n")

  # Get pin metadata
  meta <- pins::pin_meta(con, "peptide_model_torch")
  cat("Pin title:", meta$title, "\n")
  cat("Pin created:", meta$created, "\n")
} else {
  cat("⚠ Pin 'peptide_model_torch' not found in list\n")
}

cat("\n=======================================================================\n")
cat("✓ Model published to Connect!\n")
cat("  Next step: Run deploy_api.R to deploy the Plumber API\n")
cat("=======================================================================\n")
