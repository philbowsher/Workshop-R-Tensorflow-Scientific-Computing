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

# Get pinned model from Posit Connect
# Make sure config.yml is updated
# The config is replacing the typical usethis::edit_r_environ()
# After deployment, be sure to name the API in Posit Connect plumber
# make sure WD is 3 location
# Click Run API, then test peptide prediction is generated...
# Then deploy using push button
# after deplot, set content url to /plumber/

con <- config::get(file = "./config.yml")
if (!all(c("rsc_url", "rsc_api_key") %in% names(con)) &
    !grepl("<", con$rsc_url, fixed = TRUE)) {
  stop("Set rsc_url and rsc_api_key in config.yml before continuing.")
}
con <- pins::board_connect(
  server = config::get("rsc_url"),
  key = config::get("rsc_api_key")
)
mod_pinned <- pins::pin_get("peptide_model",board = con)
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
    predict(x_val) %>% keras::k_argmax()
  
 #  browser()

  # Return original peptides with predictions
  tibble::tibble(
    peptide = peptide,
    peptide_classes = peptide_classes[as.integer(preds)]
  )
}
