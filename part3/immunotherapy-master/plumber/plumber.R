#
# This is a Plumber API. You can run the API by clicking
# the 'Run API' button above.
#
# Find out more about building APIs with Plumber here:
#
#    https://www.rplumber.io/
#

library(plumber)
library(config)
library(reticulate)
library(PepTools)

# Get pinned model from RStudio Connect
pins::board_register_rsconnect(
  server = config::get("rsc_url"),
  key = config::get("rsc_api_key")
)
mod_pinned <- pins::pin_get("peptide_model")
utils::unzip(mod_pinned[1], exdir = fs::path_dir(mod_pinned[1]))
mod <- keras::load_model_tf(file.path(fs::path_dir(mod_pinned[1]), "saved_model"))

#* @apiTitle Immunotherapy

#* Predict peptide class
#* @param peptide Character vector with a single peptide, eg. `LLTDAQRIV` or comma separated, e.g. `LLTDAQRIV, LMAFYLYEV, VMSPITLPT, SLHLTNCFV, RQFTCMIAV`
#* @get /predict
function(peptide){
  # Peptide classes for prediction
  peptide_classes <- c("NB", "WB", "SB")

  # split on commas and remove white space
  peptide <- trimws(strsplit(peptide, ",")[[1]])

  # transform input into flattened array
  x_val <- peptide %>%
    pep_encode() %>%
    array_reshape(dim = c(nrow(.), 9*20))

  # Get predictions from models
  preds <- mod %>%
    keras::predict_classes(x_val)

  # Return original peptides with predictions
  tibble::tibble(
    peptide = peptide,
    peptide_classes = peptide_classes[preds]
  )
}
