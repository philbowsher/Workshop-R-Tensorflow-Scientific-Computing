#
# This is a Plumber API for predicting peptide binding affinity using Torch
#
# NOTE: This file (plumber.R) is the CURRENT version.
#       Posit Connect requires the API file to be named "plumber.R"
#
# TO RUN LOCALLY IN POSITRON:
#   setwd("part_4_torch/part3/immunotherapy/3_share_model_plumber")
#   plumber::pr_run(plumber::pr("plumber.R"), port = 8000)
#
# Then test at: http://127.0.0.1:8000/__docs__/
# Or: http://127.0.0.1:8000/predict?peptide=LLTDAQRIV
#
# TO DEPLOY TO POSIT CONNECT FROM POSITRON:
#   source("deploy_api.R")
#
# TO RUN IN RSTUDIO:
#   Click the 'Run API' button above
#
# Find out more about building APIs with Plumber here:
#    https://www.rplumber.io/
#

# Configure Python for reticulate (needed for PepTools)
# On Connect, use the managed Python environment (don't set RETICULATE_PYTHON)
# On Workbench/local, use system Python
if (Sys.getenv("RSTUDIO_PRODUCT") != "CONNECT") {
  # Running on Workbench or locally - use system Python
  Sys.setenv(RETICULATE_PYTHON = "/opt/python/3.12.3/bin/python3")
}

library(plumber)
library(torch)
library(PepTools)
library(pins)
library(httr)

# ============================================================================
# SETUP: Before running locally, set environment variables in R console:
#   Sys.setenv(CONNECT_SERVER = "https://pub.workshop.posit.team")
#   Sys.setenv(CONNECT_API_KEY = "your-api-key")
#
# When deployed to Posit Connect:
#   1. Deploy this API
#   2. In Connect UI → Content → Vars → Add environment variables:
#      - CONNECT_SERVER = https://pub.workshop.posit.team
#      - CONNECT_API_KEY = your-api-key
#   3. Set content URL to /plumber_torch/
# ============================================================================

# Connect to Posit Connect and download pinned model
con <- pins::board_connect()

# Get Connect username for authentication
connect_user <- httr::GET(
  paste0(Sys.getenv("CONNECT_SERVER"), "/__api__/v1/user"),
  httr::add_headers(Authorization = paste("Key", Sys.getenv("CONNECT_API_KEY")))
) |> httr::content()

# Get workshop ID (anonymous identifier)
workshop_id <- Sys.getenv("WORKSHOP_USER_ID")
if (workshop_id == "") {
  hash_val <- sum(utf8ToInt(connect_user$username)) %% 999999
  workshop_id <- sprintf("user%06d", hash_val)
}

# Construct pin name
pin_name <- paste0(connect_user$username, "/peptide_model_torch_", workshop_id)

# Download the pinned torch model file
mod_path <- pins::pin_download(con, pin_name)

# Expand path (removes ~ and makes it absolute)
mod_path <- normalizePath(mod_path, mustWork = TRUE)

# Load the Torch model
mod <- torch_load(mod_path)
mod$eval() # Set to evaluation mode

#* @apiTitle Immunotherapy (Torch)

#* Predict peptide class using Torch model
#* @param peptide Character vector with a single peptide, eg. `LLTDAQRIV` or comma separated, e.g. `LLTDAQRIV, LMAFYLYEV, VMSPITLPT, SLHLTNCFV, RQFTCMIAV`
#* @get /predict
function(peptide){
  # Peptide classes for prediction
  peptide_classes <- c("NB", "WB", "SB")

  # Split on commas and remove white space
  peptide <- trimws(strsplit(peptide, ",")[[1]])

  # Transform input into flattened array
  encoded <- peptide %>% pep_encode()
  x_val <- array_reshape(encoded, c(as.integer(nrow(encoded)), 180L))

  # Convert to torch tensor
  x_tensor <- torch_tensor(x_val, dtype = torch_float32())

  # Get predictions from model
  with_no_grad({
    predictions <- mod(x_tensor)
    pred_classes <- torch_argmax(predictions, dim = 2) - 1L # 0-indexed
  })

  # Convert to R vector
  preds <- as.integer(as_array(pred_classes))

  # Return original peptides with predictions
  tibble::tibble(
    peptide = peptide,
    predicted_class = peptide_classes[preds + 1]  # Convert 0-indexed to 1-indexed for R
  )
}

# ============================================================================
# Run the API (for Positron) - RUN THESE COMMANDS IN CONSOLE:
# ============================================================================
#   setwd("part_4_torch/part3/immunotherapy/3_share_model_plumber")
#   source("plumber.R")
#   plumber::pr_run(plumber::pr("plumber.R"), port = 8000)
#
# Then open: http://127.0.0.1:8000/__docs__/
# ============================================================================
