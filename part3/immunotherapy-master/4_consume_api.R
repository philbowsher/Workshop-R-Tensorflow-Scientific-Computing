library(httr)
library(purrr)
library(config)

con <- config::get()

predict_peptide <- function(peptide,
                            url = file.path(con$rsc_url, con$content_url, "predict")) {

  if(length(peptide) > 1) {
    peptide <- paste(peptide, collapse = ",")
  }

  tryCatch({
    url %>%
      httr::GET(
        query = list(peptide = peptide),
        encode = "json",
        httr::content_type_json(),
        add_headers(Authorization = paste0("Key ", con$rsc_api_key))
      ) %>%
      httr::stop_for_status() %>%
      httr::content() %>%
      map_dfr(tibble::as_tibble)
  }, error = function(e) {
    if (grepl("404", as.character(e))) {
      stop("Content not found, did you set the content URL to match your config (immuno_api)?")
    }
    e
  })
}

# Test it

predict_peptide("LLTDAQRIV")
predict_peptide("LLTDAQRIV, LMAFYLYEV, VMSPITLPT, SLHLTNCFV, RQFTCMIAV")
predict_peptide(c("LLTDAQRIV", "LMAFYLYEV", "VMSPITLPT", "SLHLTNCFV", "RQFTCMIAV"))

