# ============================================================================
# Torch R Basics - Introduction to Torch Tensors and Operations
# ============================================================================
# This is the torch equivalent of reticulate/Python examples from Part 1
# Torch R is native R (no Python backend needed for basic operations)

# Configure Python for reticulate (if needed for compatibility)
Sys.setenv(RETICULATE_PYTHON = "/opt/python/3.12.3/bin/python3")

library(torch)
library(tidyverse)

cat("=======================================================================\n")
cat("TORCH R BASICS\n")
cat("=======================================================================\n\n")

# ============================================================================
# 1. Tensors - The fundamental data structure in torch
# ============================================================================

cat("1. Creating tensors...\n")
cat("----------------------\n")

# Create a simple vector as tensor
vec <- torch_tensor(c(1, 2, 3, 4, 5))
cat("Vector tensor:\n")
print(vec)

# Create a matrix as tensor
mat <- torch_tensor(matrix(1:12, nrow = 3, ncol = 4))
cat("\nMatrix tensor:\n")
print(mat)

# Create from R data frame
df <- data.frame(
  a = c(1.5, 2.5, 3.5),
  b = c(4.0, 5.0, 6.0)
)
df_tensor <- torch_tensor(as.matrix(df))
cat("\nDataFrame as tensor:\n")
print(df_tensor)

# ============================================================================
# 2. Tensor operations
# ============================================================================

cat("\n2. Tensor operations...\n")
cat("------------------------\n")

# Element-wise operations
x <- torch_tensor(c(1, 2, 3, 4))
y <- torch_tensor(c(5, 6, 7, 8))

cat("x:\n")
print(x)
cat("\ny:\n")
print(y)

cat("\nx + y:\n")
print(x + y)

cat("\nx * y (element-wise):\n")
print(x * y)

cat("\ntorch_matmul(x, y) (dot product):\n")
print(torch_matmul(x, y))

# ============================================================================
# 3. Integration with tidyverse
# ============================================================================

cat("\n3. Torch + tidyverse integration...\n")
cat("------------------------------------\n")

# Create data in R, process with tidyverse, convert to tensor
iris_data <- iris %>%
  as_tibble() %>%
  filter(Species == "setosa") %>%
  select(Sepal.Length, Sepal.Width, Petal.Length, Petal.Width) %>%
  head(5)

cat("Original data (tibble):\n")
print(iris_data)

# Convert to tensor
iris_tensor <- torch_tensor(as.matrix(iris_data))
cat("\nAs torch tensor:\n")
print(iris_tensor)

# Convert back to R
iris_back <- as_array(iris_tensor)
cat("\nBack to R matrix:\n")
print(iris_back)

# ============================================================================
# 4. GPU availability check
# ============================================================================

cat("\n4. GPU availability...\n")
cat("-----------------------\n")

if (cuda_is_available()) {
  cat("✓ CUDA GPU available!\n")
  cat("Device count:", cuda_device_count(), "\n")

  # Move tensor to GPU
  gpu_tensor <- vec$cuda()
  cat("Tensor on GPU:\n")
  print(gpu_tensor)
} else {
  cat("✗ No GPU available (using CPU)\n")
  cat("This is fine for this workshop!\n")
}

# ============================================================================
# 5. Autograd - Automatic differentiation
# ============================================================================

cat("\n5. Automatic differentiation...\n")
cat("--------------------------------\n")

# Create tensor that requires gradient
x <- torch_tensor(3.0, requires_grad = TRUE)
cat("x (requires_grad=TRUE):\n")
print(x)

# Compute a function
y <- x^2 + 2*x + 1
cat("\ny = x^2 + 2*x + 1:\n")
print(y)

# Compute gradient dy/dx
y$backward()
cat("\ndy/dx (gradient):\n")
print(x$grad)

# Verify: d(x^2 + 2x + 1)/dx = 2x + 2 = 2(3) + 2 = 8
cat("Expected gradient at x=3: 2(3) + 2 = 8 ✓\n")

cat("\n=======================================================================\n")
cat("✓ Torch basics complete! Ready for modeling in Part 2.\n")
cat("=======================================================================\n")
