#
# This is a Plumber API for predicting peptide binding affinity
#
# NOTE: This file (plumber.R) is the CURRENT version.
#       The old file 3_share_model_plumber.R is deprecated and can be deleted.
#       Posit Connect requires the API file to be named "plumber.R"
#
# TO RUN LOCALLY IN POSITRON:
#   setwd("part_3/immunotherapy/3_share_model_plumber")
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

# Configure Python for reticulate
# On Connect, use the managed Python environment (don't set RETICULATE_PYTHON)
# On Workbench/local, use system Python
if (Sys.getenv("RSTUDIO_PRODUCT") != "CONNECT") {
  # Running on Workbench or locally - use system Python
  Sys.setenv(RETICULATE_PYTHON = "/opt/python/3.12.3/bin/python3")
}

library(plumber)
library(reticulate)
library(keras)
library(PepTools)
library(pins)

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
#   3. Set content URL to /plumber/
# ============================================================================

# Connect to Posit Connect and download pinned model
con <- pins::board_connect()

# Download the pinned model file
mod_path <- pins::pin_download(con, "peptide_model")

# Expand path (removes ~ and makes it absolute)
mod_path <- normalizePath(mod_path, mustWork = TRUE)

# Load the Keras model
mod <- keras$saving$load_model(mod_path)

#* @apiTitle Immunotherapy

#* Predict peptide class
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

  # Get predictions from model (use Python method)
  predictions <- mod$predict(x_val, verbose = 0L)
  preds <- apply(predictions, 1, which.max) - 1  # Get class with highest probability (0-indexed)

  # Return original peptides with predictions
  tibble::tibble(
    peptide = peptide,
    predicted_class = peptide_classes[preds + 1]  # Convert 0-indexed to 1-indexed for R
  )
}

# ============================================================================
# Run the API (for Positron) - RUN THESE COMMANDS IN CONSOLE:
# ============================================================================
#   setwd("part_3/immunotherapy/3_share_model_plumber")
#   source("plumber.R")
#   plumber::pr_run(plumber::pr("plumber.R"), port = 8000)
#
# Then open: http://127.0.0.1:8000/__docs__/
# ============================================================================
