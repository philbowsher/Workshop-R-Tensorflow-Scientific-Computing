# ============================================================================
# Consume the deployed Peptide Prediction API
# ============================================================================
#
# This shows how to call the deployed API from R
#
# SETUP: Set environment variables before running this file:
#   Sys.setenv(CONNECT_SERVER = "https://pub.workshop.posit.team")
#   Sys.setenv(CONNECT_API_KEY = "your-api-key")
#   Sys.setenv(CONNECT_CONTENT_URL = "plumber")  # or "content/abc-123-def/plumber" for full path
#
# Then run this file to test calling the API
#
# PUBLIC API (no authentication required):
#   If API is set to "Anyone - no login required" in Connect:
#   https://pub.workshop.posit.team/plumber/__docs__/
#   https://pub.workshop.posit.team/plumber/predict?peptide=LLTDAQRIV
#
# AUTHENTICATED API (requires API key):
#   Use the predict_peptide() function below
#
# ============================================================================

library(httr)
library(purrr)

# Configuration from environment variables
rsc_url <- Sys.getenv("CONNECT_SERVER", "https://pub.workshop.posit.team")
rsc_api_key <- Sys.getenv("CONNECT_API_KEY")
content_url <- Sys.getenv("CONNECT_CONTENT_URL")

# Validate configuration
if (content_url == "") {
  stop("Set CONNECT_CONTENT_URL environment variable first.\n",
       "After deploying the API to Connect, set the content URL:\n",
       "  Sys.setenv(CONNECT_CONTENT_URL = 'plumber')  # For vanity URL\n",
       "  OR\n",
       "  Sys.setenv(CONNECT_CONTENT_URL = 'content/abc-123-def/plumber')  # For full path")
}

if (rsc_api_key == "") {
  stop("Set CONNECT_API_KEY environment variable first:\n",
       "  Sys.setenv(CONNECT_API_KEY = 'your-api-key')")
}

# Function to predict peptide class via API
predict_peptide <- function(peptide,
                            url = file.path(rsc_url, content_url, "predict")) {

  # Handle multiple peptides
  if(length(peptide) > 1) {
    peptide <- paste(peptide, collapse = ",")
  }

  tryCatch({
    url %>%
      httr::GET(
        query = list(peptide = peptide),
        encode = "json",
        httr::content_type_json(),
        add_headers(Authorization = paste0("Key ", rsc_api_key))
      ) %>%
      httr::stop_for_status() %>%
      httr::content() %>%
      map_dfr(tibble::as_tibble)
  }, error = function(e) {
    if (grepl("404", as.character(e))) {
      stop("Content not found (404). Check that:\n",
           "  1. The API is deployed to Connect\n",
           "  2. CONNECT_CONTENT_URL is correct\n",
           "  3. Content URL is set to '/plumber/' in Connect settings")
    }
    stop(e)
  })
}

# ============================================================================
# Test the API
# ============================================================================

cat("Testing API with single peptide...\n")
result1 <- predict_peptide("LLTDAQRIV")
print(result1)

cat("\nTesting API with comma-separated peptides...\n")
result2 <- predict_peptide("LLTDAQRIV, LMAFYLYEV, VMSPITLPT, SLHLTNCFV, RQFTCMIAV")
print(result2)

cat("\nTesting API with vector of peptides...\n")
result3 <- predict_peptide(c("LLTDAQRIV", "LMAFYLYEV", "VMSPITLPT", "SLHLTNCFV", "RQFTCMIAV"))
print(result3)

