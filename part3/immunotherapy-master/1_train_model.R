# https://blogs.rstudio.com/tensorflow/posts/2018-01-29-dl-for-cancer-immunotherapy/

suppressPackageStartupMessages({
  library(tidyverse)
  library(keras)
  library(ggplot2)
  library(PepTools)
})

# use_implementation("keras")

EPOCHS <- 10

# Download and cache the data locally

pep_file <- get_file(
  "ran_peps_netMHCpan40_predicted_A0201_reduced_cleaned_balanced.tsv",
  origin = "https://git.io/vb3Xa",
  cache_subdir = "~/datasets"
)



# Import the data

pep_dat <- readr::read_tsv(file = pep_file, col_types = "ccdc")


# Set up train and test samples

encode_x <- function(x, type) {
  x %>%
    filter(data_type == {{ type }}) %>%
    pull(peptide) %>%
    PepTools::pep_encode() %>%
    array_reshape(c(nrow(.), 9 * 20))
}

encode_y <- function(x, type) {
  x %>%
    filter(data_type == {{ type }}) %>%
    pull(label_num) %>%
    array() %>%
    to_categorical(num_classes = 3)
}

x_train <- pep_dat %>% encode_x("train")
x_test  <- pep_dat %>% encode_x("test")

y_train <- pep_dat %>% encode_y("train")
y_test  <- pep_dat %>% encode_y("test")





# Define the model

model <-
  keras_model_sequential() %>%
  layer_dense(units = 180, activation = "relu", input_shape = 180) %>%
  layer_dropout(rate = 0.4) %>%
  layer_dense(units = 90, activation = "relu") %>%
  layer_dropout(rate = 0.3) %>%
  layer_dense(units = 3, activation = "softmax")

summary(model)

model %>%
  compile(
    loss = "categorical_crossentropy",
    optimizer = optimizer_rmsprop(epsilon = 1e-7),
    metrics = c("accuracy")
  )

# Train the model

history <-
  model %>%
  fit(
    x_train, y_train,
    epochs = EPOCHS,
    batch_size = 64,
    validation_split = 0.2
  )


# Evaluate model performance

plot(history)

perf <- model %>%
  evaluate(x_test, y_test)
perf


y_pred <- model %>%
  predict_classes(x_test)

y_real <- y_test %>%
  apply(1, function(x) {which(x == 1) - 1 })

peptide_classes <- c("NB", "WB", "SB")
results <- tibble(
  measured  = y_real %>% factor(levels = 0:2, labels = peptide_classes),
  predicted = y_pred %>% factor(levels = 0:2, labels = peptide_classes),
  Correct = if_else(y_real == y_pred, "yes", "no") %>% factor()
)


results %>%
  ggplot(aes(colour = Correct)) +
  geom_jitter(aes(x = 0, y = 0), alpha = 0.5) +
  ggtitle(
    label = "Performance on 10% unseen data",
    subtitle = glue::glue("Accuracy = {round(perf['accuracy'], 3) * 100}%")
  ) +
  xlab(
    "Measured\n(Real class, as predicted by netMHCpan-4.0)"
  ) +
  ylab(
    "Predicted\n(Class assigned by Keras / TensorFlow model)"
  ) +
  scale_colour_manual(
    labels = c("No", "Yes"),
    values = c("red", "blue")
  ) +
  theme_bw() +
  facet_grid(predicted ~ measured, labeller = label_both) +
  ggplot2::theme(
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank()
  )


# save model for deployment -----------------------------------------------

## This is the old way.
# model %>%
#   export_savedmodel("saved_models")

# And this is the recommended way
model %>%
  save_model_tf("saved_model")
