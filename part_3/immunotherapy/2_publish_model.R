# ============================================================================
# SETUP: Authenticate to Posit Connect
# ============================================================================
# 
# POSITRON USERS (this workshop):
#
# Step 1: Get your API key
#   - Go to: https://pub.workshop.posit.team
#   - Log in with your workshop credentials
#   - Click your name (top right corner) → API Keys → New API Key
#   - Copy the key
#
# Step 2: Set environment variables in R console (run these before this script):
#   Sys.setenv(CONNECT_SERVER = "https://pub.workshop.posit.team")
#   Sys.setenv(CONNECT_API_KEY = "ADDYOURKEY")
#
# Step 3: Run this script
#
# OR: Authenticate directly in this script (uncomment and fill in):
#   library(pins)
#   con <- pins::board_connect(
#     server = "https://pub.workshop.posit.team",
#     key = "your-api-key-here"
#   )
#
# ============================================================================
# RSTUDIO USERS (optional reference):
#   Tools → Global Options → Publishing → Connect
#   Add server: https://pub.workshop.posit.team
# ============================================================================

library(pins)

# ============================================================================
# AUTHENTICATION: Set environment variables before running this script
# ============================================================================
# Run these commands in your R console FIRST (replace with your actual API key):
#
#   Sys.setenv(CONNECT_SERVER = "https://pub.workshop.posit.team")
#   Sys.setenv(CONNECT_API_KEY = "your-actual-api-key-here")
#
# Then run this script.
# ============================================================================

# Connect to Posit Connect using environment variables
con <- pins::board_connect()

cat("✓ Connected to Posit Connect\n\n")

# Pin the saved model to Connect
# The model was saved as "saved_model.keras" in step 1

# Read the model file as raw binary and pin it
model_path <- "saved_model.keras"
if (!file.exists(model_path)) {
  stop("Model file not found. Make sure you ran 1_train_model.R first and are in the correct directory.")
}

# Pin the model file - pins will handle binary files automatically
pins::pin_upload(
  board = con,
  paths = model_path,
  name = "peptide_model",
  title = "Peptide Binding Prediction Model",
  description = "Neural network model for predicting peptide-MHC binding affinity (Keras format)"
)

cat("\n✓ Model published to Posit Connect as 'peptide_model'\n")
cat("  Access it with: pins::pin_download(board_connect(), 'peptide_model')\n")
