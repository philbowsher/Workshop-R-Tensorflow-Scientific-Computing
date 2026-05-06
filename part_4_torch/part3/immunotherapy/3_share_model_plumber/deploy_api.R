# ============================================================================
# Deploy Plumber API (Torch) to Posit Connect (Programmatic Deployment)
# ============================================================================
#
# SETUP: Before running, set environment variables in R console:
#   Sys.setenv(CONNECT_SERVER = "https://pub.workshop.posit.team")
#   Sys.setenv(CONNECT_API_KEY = "your-api-key")
#
# Then run this script to deploy the API to Connect
# ============================================================================

library(rsconnect)

# Configuration
server_url <- Sys.getenv("CONNECT_SERVER", "https://pub.workshop.posit.team")
api_key <- Sys.getenv("CONNECT_API_KEY")

if (api_key == "") {
  stop("Set CONNECT_API_KEY environment variable first:\n",
       "  Sys.setenv(CONNECT_API_KEY = 'your-api-key')")
}

cat("Deploying Plumber API (Torch) to Posit Connect...\n")
cat("Server:", server_url, "\n\n")

# Use the server name "workshop_connect" that was registered earlier
server_name <- "workshop_connect"

# Check if account is already registered
accounts <- rsconnect::accounts(server = server_name)

if (nrow(accounts) == 0) {
  cat("Registering Connect account with API key...\n")
  # Register the account with API key authentication
  rsconnect::connectApiUser(
    account = "workshop_user",
    server = server_name,
    apiKey = api_key
  )
  # Refresh accounts list
  accounts <- rsconnect::accounts(server = server_name)
}

cat("Using account:", accounts$name[1], "\n")

# Deploy the API
cat("Deploying Plumber API (Torch)...\n")
setwd("~/Workshop-R-Tensorflow-Scientific-Computing/part_4_torch/part3/immunotherapy/3_share_model_plumber")

# Ensure plumber.R exists (Connect standard)
if (!file.exists("plumber.R")) {
  stop("plumber.R not found. Make sure the API file is named plumber.R")
}

# Remove old deployment manifest to force new deployment
if (file.exists("rsconnect")) {
  cat("Removing old deployment records...\n")
  unlink("rsconnect", recursive = TRUE)
}

deployment <- rsconnect::deployApp(
  appDir = ".",
  appTitle = "Peptide Prediction API (Torch)",
  appFiles = c("plumber.R"),
  server = server_name,
  account = accounts$name[1]
)

cat("\n✓ Deployment complete!\n\n")

# Get deployment info
if (is.character(deployment)) {
  # deployment is just a URL string
  api_url <- deployment
} else if (!is.null(deployment$appUrl)) {
  # deployment is an object with appUrl
  api_url <- deployment$appUrl
} else {
  # Fallback - get from rsconnect records
  deployments <- rsconnect::deployments(".")
  if (nrow(deployments) > 0) {
    api_url <- deployments$url[1]
  } else {
    api_url <- "https://pub.workshop.posit.team/plumber_torch/"
  }
}

cat("API URL:", api_url, "\n")
cat("Interactive docs:", file.path(api_url, "__docs__"), "\n")
cat("Test endpoint:", file.path(api_url, "predict?peptide=LLTDAQRIV"), "\n\n")

cat("For file 4 (consume API), set environment variable:\n")
cat("  Sys.setenv(CONNECT_CONTENT_URL = 'plumber_torch')\n")
