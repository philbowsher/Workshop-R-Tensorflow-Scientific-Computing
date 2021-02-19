library(pins)
library(keras)
# Pin it on RStudio Connect
pins::board_register_rsconnect()
local_zipfile <- zip::zip("model.zip", "saved_model")
pins::pin(
  local_zipfile,
  "peptide_model",
  "Peptide Prediction Model",
  "rsconnect"
)
