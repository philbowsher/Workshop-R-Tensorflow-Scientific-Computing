library(plumber)
library(reticulate)

source_python("server.py")

#* @apiTitle Reticulated Plumber API

#* @get /details
function() {
  list(
    mean = py$mean,
    sd = py$sd,
    obs = py$n
  )
}

#' @get /data
function() {
  py$data
}

#* Plot a histogram
#* @serializer png
#* @get /plot
function() {
    hist(py$data)
}
