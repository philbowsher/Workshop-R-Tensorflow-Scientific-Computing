# debugonce(tensorflow::install_tensorflow)


# install CRAN packages if necessary --------------------------------------


pkgs <- c(
  "keras",
  "tfdeploy",
  "tidyverse",
  "ggplot2",
  "glue",
  "config",
  "withr",
  "stringr"
)

to_install <- setdiff(pkgs, installed.packages()[, "Package"])

if (length(to_install)) install.packages(to_install)


# install github packages if necessary ------------------------------------

if (!"ggseqlogo" %in% installed.packages()[, "Package"]) {
  if (!"devtools" %in% installed.packages()[, "Package"]) {
    install.packages("devtools")
  }
  devtools::install_github("omarwagih/ggseqlogo")
}

if (!"PepTools" %in% installed.packages()[, "Package"]) {
  devtools::install_github("leonjessen/PepTools")
}


# install keras if necessary ----------------------------------------------

if (!keras::is_keras_available()) {
  keras::install_keras(tensorflow = "2.0.0")
}

