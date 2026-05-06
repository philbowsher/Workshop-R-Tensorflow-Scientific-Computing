# Part 2: Torch Models and Applications

This folder contains practical torch neural network examples relevant to pharma and healthcare settings.

## Files

### 1. torch_iris_classifier.R
**What it does:** Multi-class classification using the classic iris dataset

**Key concepts:**
- Neural network for 3-class classification
- Manual training loop with validation
- Confusion matrix analysis
- Model saving and loading

**Run it:**
```r
source("part_4_torch/part2/torch_iris_classifier.R")
```

**Output:**
- Training and validation accuracy plots
- Confusion matrix visualization
- Saved model: `iris_model.pt`

---

### 2. torch_drug_response.R
**What it does:** Predict drug response based on concentration (dose-response curves)

**Pharmaceutical relevance:**
- IC50 determination
- Dose optimization
- Drug efficacy prediction
- Combination therapy modeling

**Key concepts:**
- Regression with neural networks
- S-shaped dose-response curves
- MSE loss function
- R-squared evaluation

**Run it:**
```r
source("part_4_torch/part2/torch_drug_response.R")
```

**Output:**
- Dose-response curve visualization
- Model predictions vs actual data
- Training loss plot
- Saved model: `drug_response_model.pt`

---

### 3. torch_patient_risk.R
**What it does:** Binary classification for patient risk prediction

**Healthcare relevance:**
- Hospital readmission prediction
- Disease risk assessment
- Treatment response prediction
- Clinical trial patient selection

**Key concepts:**
- Binary classification
- Feature standardization
- Clinical performance metrics (sensitivity, specificity, PPV, NPV)
- Feature importance estimation

**Run it:**
```r
source("part_4_torch/part2/torch_patient_risk.R")
```

**Output:**
- Risk stratification visualization
- Confusion matrix
- Clinical performance metrics
- Feature importance plot
- Saved model: `patient_risk_model.pt`

---

## Comparison with Keras Examples

| **Torch (Part 4)** | **Keras (Part 2)** |
|--------------------|-------------------|
| Manual training loops | `model$fit()` handles training |
| Explicit forward/backward pass | Automatic in Keras |
| Native R computation | Python backend via reticulate |
| `nn_module` class definition | `keras_model_sequential()` |
| More verbose but more control | Less code but less control |

## Why Use Torch for Pharma/Healthcare?

1. **Transparency**: Manual loops make the training process explicit
2. **Flexibility**: Easy to customize loss functions and training logic
3. **Native R**: No Python dependency issues (except for PepTools)
4. **Research alignment**: PyTorch (Python version) is widely used in research
5. **Custom architectures**: Easier to implement novel architectures

## Model Formats

All models are saved as `.pt` files (PyTorch format):

```r
# Save
torch_save(model, "my_model.pt")

# Load
model <- torch_load("my_model.pt")
model$eval() # Set to evaluation mode
```

## Next Steps

After completing Part 2, move to **Part 3** for the full ML deployment pipeline:
- Train peptide binding model
- Pin model to Posit Connect
- Deploy as Plumber API
- Consume API from R

```r
# Continue to Part 3
setwd("part_4_torch/part3/immunotherapy")
source("1_train_model.R")
```
