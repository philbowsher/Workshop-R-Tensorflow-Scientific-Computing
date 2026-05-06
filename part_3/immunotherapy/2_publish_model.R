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
#   Sys.setenv(CONNECT_API_KEY = "paste-your-api-key-here")
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
library(httr)

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

cat("✓ Connected to Posit Connect\n")

# Get Connect username from API for authentication
connect_user <- httr::GET(
  paste0(Sys.getenv("CONNECT_SERVER"), "/__api__/v1/user"),
  httr::add_headers(Authorization = paste("Key", Sys.getenv("CONNECT_API_KEY")))
) |> httr::content()

# Generate or retrieve anonymous workshop ID (no private info exposed)
# Stored in environment variable for session persistence
workshop_id <- Sys.getenv("WORKSHOP_USER_ID")
if (workshop_id == "") {
  # Generate random anonymous ID for this workshop session
  # Uses hash of username to ensure same user always gets same ID (deterministic)
  hash_val <- sum(utf8ToInt(connect_user$username)) %% 999999
  workshop_id <- sprintf("user%06d", hash_val)
  Sys.setenv(WORKSHOP_USER_ID = workshop_id)
  cat("✓ Generated workshop ID:", workshop_id, "\n")
  cat("  (Anonymous - no personal info. Add to .Rprofile to persist)\n\n")
} else {
  cat("✓ Using workshop ID:", workshop_id, "\n\n")
}

# Pin the saved model to Connect
# The model was saved as "saved_model.keras" in step 1

# Read the model file as raw binary and pin it
model_path <- "saved_model.keras"
if (!file.exists(model_path)) {
  stop("Model file not found. Make sure you ran 1_train_model.R first and are in the correct directory.")
}

# Pin the model file with anonymous identifier (for multi-user workshop environment)
# Pin stored as: "email@domain.com/peptide_model_user123456"
# Title shows anonymous ID only (no personal info exposed)
pin_name <- paste0(connect_user$username, "/peptide_model_", workshop_id)

pins::pin_upload(
  board = con,
  paths = model_path,
  name = pin_name,
  title = paste0("Peptide Model - ", workshop_id),
  description = paste0("Peptide-MHC binding prediction model (Keras format)")
)

cat("\n✓ Model published to Posit Connect\n")
cat("  Your workshop ID:", workshop_id, "\n")
cat("  Pin name:", pin_name, "\n\n")
cat("Your API will automatically use this pin.\n")
