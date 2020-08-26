library(pins)
library(keras)

# Pin it on RStudio Connect
pins::board_register_rsconnect()
pins::pin(
  "saved_model",
  "peptide_model",
  "Peptide Prediction Model",
  "rsconnect",
  zip = TRUE
)
