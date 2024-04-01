# for this to work, be sure to go to Tools - Global Options - Publishing - Connect, and follow the instructions
# And then establish connection to Posit Connect Server
# https://pins.rstudio.com/reference/board_connect.html

# This will take the tensorflow model and pin it to PC and the model will only available
# to people or process with access

library(pins)
# Pin it on Posit Connect
con <- pins::board_connect()
#make sure this was saved to wd for part 3
local_zipfile <- zip::zip("model.zip", "saved_model")
pins::pin(
  local_zipfile,
  "peptide_model",
  "Peptide Prediction Model",
  con
)
