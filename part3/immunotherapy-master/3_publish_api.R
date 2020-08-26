# Since the API is defined by `plumber/plumber.R`, i.e. inside a subfolder,
# first copy the `config.yml` to the `plumber` folder
con <- config::get()
if (!all(c("rsc_url", "rsc_api_key") %in% names(con)) &
    !grepl("<", con$rsc_url, fixed = TRUE)) {
  stop("Set rsc_url and rsc_api_key in config.yml before continuing.")
}
fs::file_copy("config.yml", "plumber/config.yml", overwrite = TRUE)

library(rsconnect)
withr::with_dir(
  "plumber",

  rsconnect::deployAPI(
    api = ".",
    # server = "{server}",     # <<- edit this line if necessary
    # account = "{account}",   # <<- edit this line if necessary
    appTitle = "Immunotherapy API",
    forceUpdate = TRUE
  )
)
