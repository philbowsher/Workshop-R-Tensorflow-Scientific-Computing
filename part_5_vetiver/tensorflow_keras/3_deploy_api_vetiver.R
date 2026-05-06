# ============================================================================
# Deploy Vetiver API to Posit Connect (Automated)
# ============================================================================
# Vetiver automatically:
# 1. Generates the plumber API (no manual plumber.R needed!)
# 2. Creates /predict endpoint
# 3. Adds /ping and /metadata endpoints
# 4. Deploys to Connect
#
# SETUP: Before running, set environment variables in R console:
#   Sys.setenv(CONNECT_SERVER = "https://pub.workshop.posit.team")
#   Sys.setenv(CONNECT_API_KEY = "your-api-key")
# ============================================================================

# Configure Python for reticulate
Sys.setenv(RETICULATE_PYTHON = "/opt/python/3.12.3/bin/python3")

library(vetiver)
library(pins)
library(rsconnect)
library(plumber)
library(httr)

cat("=======================================================================\n")
cat("DEPLOYING VETIVER API TO POSIT CONNECT\n")
cat("=======================================================================\n\n")

# ============================================================================
# 1. Configuration
# ============================================================================

cat("1. Checking configuration...\n")
cat("-----------------------------\n")

server_url <- Sys.getenv("CONNECT_SERVER", "https://pub.workshop.posit.team")
api_key <- Sys.getenv("CONNECT_API_KEY")

if (api_key == "") {
  stop("Set CONNECT_API_KEY environment variable first:\n",
       "  Sys.setenv(CONNECT_API_KEY = 'your-api-key')")
}

cat("Server:", server_url, "\n")

# Get Connect username from API
connect_user <- httr::GET(
  paste0(server_url, "/__api__/v1/user"),
  httr::add_headers(Authorization = paste("Key", api_key))
) |> httr::content()

# Generate or retrieve anonymous workshop ID
workshop_id <- Sys.getenv("WORKSHOP_USER_ID")
if (workshop_id == "") {
  hash_val <- sum(utf8ToInt(connect_user$username)) %% 999999
  workshop_id <- sprintf("user%06d", hash_val)
  Sys.setenv(WORKSHOP_USER_ID = workshop_id)
}

cat("Workshop ID:", workshop_id, "\n")

# ============================================================================
# 2. Connect to board and retrieve model
# ============================================================================

cat("\n2. Loading vetiver model from Connect...\n")
cat("-----------------------------------------\n")

board <- board_connect()

# Construct pin name with anonymous workshop ID
model_name <- paste0(connect_user$username, "/peptide_keras_vetiver_", workshop_id)

v <- vetiver_pin_read(board, model_name)

cat("✓ Model loaded\n")
cat("  Model name:", v$model_name, "\n")
cat("  Description:", v$description, "\n")

# ============================================================================
# 3. Register Connect account if needed
# ============================================================================

cat("\n3. Registering Connect account...\n")
cat("----------------------------------\n")

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
  cat("Registering Connect account with API key...\n")
  rsconnect::connectApiUser(
    account = connect_user$username,
    server = server_name,
    apiKey = api_key
  )
  accounts <- rsconnect::accounts(server = server_name)
}

cat("Using account:", accounts$name[1], "\n")

# ============================================================================
# 4. Deploy Vetiver API
# ============================================================================

cat("\n4. Deploying Vetiver API...\n")
cat("----------------------------\n")

# Vetiver automatically creates the plumber API and deploys it!
vetiver_deploy_rsconnect(
  board = board,
  name = model_name,
  server = server_name,
  account = accounts$name[1],
  appTitle = paste0("Peptide API (Keras + Vetiver) - ", workshop_id)
)

cat("\n✓ Deployment complete!\n")

# ============================================================================
# 5. Get deployment info
# ============================================================================

cat("\n5. Deployment information...\n")
cat("----------------------------\n")

cat("\nVetiver API Endpoints:\n")
cat("  /predict    - Make predictions (POST with JSON body)\n")
cat("  /ping       - Health check\n")
cat("  /metadata   - Model metadata\n")

cat("\n=======================================================================\n")
cat("✓ Vetiver API deployed!\n")
cat("\nWhat Vetiver did for you:\n")
cat("  • Generated plumber API automatically (no plumber.R to write!)\n")
cat("  • Created /predict, /ping, /metadata endpoints\n")
cat("  • Deployed to Connect programmatically\n")
cat("  • Handles model loading and predictions\n")
cat("\nNext steps:\n")
cat("  1. Go to Connect UI and find 'Peptide Prediction API (Keras + Vetiver)'\n")
cat("  2. Set environment variables in Content → Vars:\n")
cat("     - CONNECT_SERVER = https://pub.workshop.posit.team\n")
cat("     - CONNECT_API_KEY = your-api-key\n")
cat("  3. Note the API URL (e.g., /content/abc-123/)\n")
cat("  4. Run 4_consume_api.R to test the API\n")
cat("=======================================================================\n")
