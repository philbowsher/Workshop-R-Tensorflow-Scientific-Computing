# Part 1: Torch R Basics

This folder introduces the fundamentals of torch R for scientific computing.

## Files

### torch_basics.R
**What it does:** Introduction to torch tensors, operations, and core concepts

**Key concepts covered:**

1. **Creating Tensors**
   - From R vectors: `torch_tensor(c(1, 2, 3))`
   - From R matrices: `torch_tensor(matrix(...))`
   - From data frames: `torch_tensor(as.matrix(df))`

2. **Tensor Operations**
   - Element-wise operations: `x + y`, `x * y`
   - Matrix multiplication: `torch_matmul(x, y)`
   - Reshaping, indexing, slicing

3. **Integration with Tidyverse**
   - Convert R data to tensors
   - Use dplyr pipelines before tensor conversion
   - Convert tensors back to R: `as_array(tensor)`

4. **GPU Support**
   - Check availability: `cuda_is_available()`
   - Move to GPU: `tensor$cuda()`
   - Note: CPU is fine for this workshop!

5. **Automatic Differentiation (Autograd)**
   - Create gradient-tracked tensors: `torch_tensor(x, requires_grad = TRUE)`
   - Compute gradients: `y$backward()`
   - Access gradients: `x$grad`

**Run it:**
```r
source("part_4_torch/part1/torch_basics.R")
```

---

## Key Differences from NumPy/TensorFlow

### Tensor Creation

**NumPy (Python):**
```python
import numpy as np
x = np.array([1, 2, 3])
```

**TensorFlow (Python via reticulate):**
```python
import tensorflow as tf
x = tf.constant([1, 2, 3])
```

**Torch (R):**
```r
library(torch)
x <- torch_tensor(c(1, 2, 3))
```

### Automatic Differentiation

Torch's autograd is similar to TensorFlow's GradientTape:

**Torch:**
```r
x <- torch_tensor(3.0, requires_grad = TRUE)
y <- x^2 + 2*x + 1
y$backward()
print(x$grad) # dy/dx = 2x + 2 = 8
```

**TensorFlow:**
```python
x = tf.Variable(3.0)
with tf.GradientTape() as tape:
    y = x**2 + 2*x + 1
dy_dx = tape.gradient(y, x)
```

## Why Torch for R?

1. **Native R**: No Python backend (unlike Keras/TensorFlow)
2. **Fast**: Optimized C++ backend
3. **GPU support**: CUDA acceleration if available
4. **PyTorch compatibility**: Similar API to PyTorch (Python)
5. **Growing ecosystem**: luz, tabnet, and other packages

## Common Operations

```r
library(torch)

# Create tensor
x <- torch_tensor(matrix(1:12, nrow = 3, ncol = 4))

# Shape
x$shape  # [3, 4]

# Device
x$device  # cpu

# Data type
x$dtype  # torch_Long

# Change type
x <- x$to(dtype = torch_float32())

# Reshape
x_flat <- x$view(c(-1))  # Flatten

# Operations
y <- torch_randn(3, 4)
z <- x + y  # Element-wise
w <- torch_matmul(x, y$t())  # Matrix multiplication

# Convert to R
x_r <- as_array(x)
```

## GPU Usage (Optional)

If CUDA is available on your system:

```r
# Check if GPU available
cuda_is_available()  # TRUE or FALSE

# Move to GPU
x_gpu <- x$cuda()

# Do operations on GPU
y_gpu <- x_gpu * 2

# Move back to CPU
y_cpu <- y_gpu$cpu()
```

For this workshop, CPU is sufficient!

## Next Steps

After mastering the basics, move to **Part 2** for practical models:

```r
# Continue to Part 2
source("part_4_torch/part2/torch_iris_classifier.R")
source("part_4_torch/part2/torch_drug_response.R")
source("part_4_torch/part2/torch_patient_risk.R")
```

## Resources

- [Torch R documentation](https://torch.mlverse.org/)
- [PyTorch tutorials](https://pytorch.org/tutorials/) (concepts transfer to R)
- [Deep Learning with R (2nd edition)](https://www.manning.com/books/deep-learning-with-r-second-edition) (torch chapters)
