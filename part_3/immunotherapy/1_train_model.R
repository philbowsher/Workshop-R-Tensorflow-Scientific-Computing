# https://blogs.rstudio.com/tensorflow/posts/2018-01-29-dl-for-cancer-immunotherapy/

# Configure Python for reticulate in Positron
Sys.setenv(RETICULATE_PYTHON = "/opt/python/3.12.3/bin/python3")

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
  encoded <- x %>%
    filter(data_type == {{ type }}) %>%
    pull(peptide) %>%
    PepTools::pep_encode()
  array_reshape(encoded, c(as.integer(nrow(encoded)), 180L))
}

encode_y <- function(x, type) {
  y <- x %>%
    filter(data_type == {{ type }}) %>%
    pull(label_num)
  # Ensure labels are 0-indexed integers (0, 1, 2)
  y <- as.integer(as.numeric(y))
  # If labels are 1-indexed (1, 2, 3), convert to 0-indexed
  if (min(y) == 1) {
    y <- y - 1L
  }
  keras$utils$to_categorical(y, num_classes = 3L)
}

x_train <- pep_dat %>% encode_x("train")
x_test  <- pep_dat %>% encode_x("test")

y_train <- pep_dat %>% encode_y("train")
y_test  <- pep_dat %>% encode_y("test")





# Define the model

model <- keras_model_sequential(
  list(
    layer_input(shape = c(180L)),
    layer_dense(units = 180L, activation = "relu"),
    layer_dropout(rate = 0.4),
    layer_dense(units = 90L, activation = "relu"),
    layer_dropout(rate = 0.3),
    layer_dense(units = 3L, activation = "softmax")
  )
)

model$summary()

model$compile(
  loss = "categorical_crossentropy",
  optimizer = optimizer_rmsprop(learning_rate = 0.001),
  metrics = list("accuracy")
)

# Train the model

history <- model$fit(
  x = x_train,
  y = y_train,
  epochs = as.integer(EPOCHS),
  batch_size = 64L,
  validation_split = 0.2,
  verbose = 1L
)


# Evaluate model performance

# Manual history plotting
history_df <- data.frame(
  epoch = 1:length(history$history$loss),
  loss = unlist(history$history$loss),
  val_loss = unlist(history$history$val_loss),
  accuracy = unlist(history$history$accuracy),
  val_accuracy = unlist(history$history$val_accuracy)
)

library(tidyr)
history_df %>%
  pivot_longer(cols = -epoch, names_to = "metric", values_to = "value") %>%
  mutate(dataset = ifelse(grepl("^val_", metric), "validation", "training"),
         metric = gsub("^val_", "", metric)) %>%
  ggplot(aes(x = epoch, y = value, color = dataset)) +
  geom_line() +
  facet_wrap(~metric, scales = "free_y") +
  theme_bw() +
  labs(title = "Training History", x = "Epoch", y = "Value")

perf <- model$evaluate(x_test, y_test, verbose = 0)
names(perf) <- c('loss', 'accuracy')
perf


predictions <- model$predict(x_test, verbose = 0)
y_pred <- apply(predictions, 1, which.max) - 1  # Get class with highest probability

y_real <- apply(y_test, 1, function(x) {which(x == 1) - 1})

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

# Save as native Keras format (recommended for Keras 3.x)
keras$saving$save_model(model, "saved_model.keras")

# OR export as SavedModel format for TensorFlow Serving/deployment
# model$export("saved_model")

cat("\n✓ Model saved to saved_model.keras\n")
