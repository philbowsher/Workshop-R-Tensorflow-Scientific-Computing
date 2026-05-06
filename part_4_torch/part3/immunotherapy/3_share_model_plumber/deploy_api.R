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
library(httr)

# Configuration
server_url <- Sys.getenv("CONNECT_SERVER", "https://pub.workshop.posit.team")
api_key <- Sys.getenv("CONNECT_API_KEY")

if (api_key == "") {
  stop("Set CONNECT_API_KEY environment variable first:\n",
       "  Sys.setenv(CONNECT_API_KEY = 'your-api-key')")
}

cat("Deploying Plumber API (Torch) to Posit Connect...\n")
cat("Server:", server_url, "\n\n")

# Get Connect username from API
connect_user <- httr::GET(
  paste0(server_url, "/__api__/v1/user"),
  httr::add_headers(Authorization = paste("Key", api_key))
) |> httr::content()

cat("Authenticated as Connect user\n")

# Use the server name "workshop_connect"
server_name <- "workshop_connect"

# Register server if not already registered
servers <- rsconnect::servers()
if (!server_name %in% servers$name) {
  cat("Registering Connect server...\n")
  rsconnect::addServer(url = server_url, name = server_name)
}

# Check if account is already registered
accounts <- rsconnect::accounts(server = server_name)

if (nrow(accounts) == 0) {
  cat("Registering Connect account...\n")
  rsconnect::connectApiUser(
    account = connect_user$username,
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
  account = accounts$name[1],
  forceUpdate = TRUE
)

cat("\n✓ Deployment complete!\n\n")

# Get deployment info from rsconnect records
deployments <- rsconnect::deployments(".")
if (nrow(deployments) > 0) {
  api_url <- deployments$url[1]

  # Extract content GUID from URL for 4_consume_api.R
  guid <- sub(".*/content/([^/]+).*", "\\1", api_url)
  content_url <- paste0("content/", guid)

  cat("API URL:", api_url, "\n")
  cat("Interactive docs:", file.path(api_url, "__docs__"), "\n")
  cat("Test endpoint:", file.path(api_url, "predict?peptide=LLTDAQRIV"), "\n\n")

  cat("For file 4 (consume API), the content URL has been auto-detected.\n")
  cat("If needed, manually set:\n")
  cat("  Sys.setenv(CONNECT_CONTENT_URL = '", content_url, "')\n", sep = "")
} else {
  cat("Could not retrieve deployment URL from records.\n")
  cat("Check Connect UI for the deployed API URL.\n")
}
