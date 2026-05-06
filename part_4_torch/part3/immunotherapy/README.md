# Part 3: Immunotherapy - Peptide Binding Prediction (Torch)

Complete ML deployment pipeline using torch R for predicting peptide-MHC binding affinity.

## Overview

This demonstrates a full production ML workflow:

1. **Train** a neural network model
2. **Pin** the model to Posit Connect
3. **Deploy** as a Plumber API
4. **Consume** the API from R clients

All using **torch R** instead of Keras/TensorFlow.

---

## Files

### 1_train_model.R

**Purpose:** Train the peptide binding prediction model using torch

**What it does:**
- Loads peptide data from PepTools package
- Encodes peptides as numeric arrays (9 amino acids × 20 properties = 180 features)
- Trains a 3-class neural network (NB, WB, SB)
- Evaluates performance with confusion matrix
- Saves trained model as `peptide_model_torch.pt`

**Architecture:**
```
Input (180) → Dense(180) + ReLU + Dropout(0.4)
           → Dense(90) + ReLU + Dropout(0.3)
           → Dense(3) + Softmax
```

**Run it:**
```r
setwd("part_4_torch/part3/immunotherapy")
source("1_train_model.R")
```

**Expected output:**
- Training accuracy: ~95%
- Test accuracy: ~95%
- Saved model: `peptide_model_torch.pt`

---

### 2_publish_model.R

**Purpose:** Upload the trained model to Posit Connect via pins

**Prerequisites:**
```r
Sys.setenv(CONNECT_SERVER = "https://pub.workshop.posit.team")
Sys.setenv(CONNECT_API_KEY = "your-api-key")
```

Get your API key from: https://pub.workshop.posit.team → Your name → API Keys → New

**Run it:**
```r
source("2_publish_model.R")
```

**What happens:**
- Connects to Posit Connect
- Uploads `peptide_model_torch.pt` as a pin named `"peptide_model_torch"`
- Makes model available to other content on Connect

---

### 3_share_model_plumber/

API directory with Plumber files for serving predictions.

#### plumber.R

**Purpose:** Plumber API that loads the pinned model and serves predictions

**API Endpoint:**
```
GET /predict?peptide=LLTDAQRIV
```

**How it works:**
1. Downloads pinned model from Connect
2. Loads torch model with `torch_load()`
3. Encodes input peptide with PepTools
4. Returns prediction (NB, WB, or SB)

**Test locally:**
```r
setwd("part_4_torch/part3/immunotherapy/3_share_model_plumber")

# Set environment variables
Sys.setenv(CONNECT_SERVER = "https://pub.workshop.posit.team")
Sys.setenv(CONNECT_API_KEY = "your-api-key")

# Run API
plumber::pr_run(plumber::pr("plumber.R"), port = 8000)
```

Then open: http://127.0.0.1:8000/__docs__/

#### deploy_api.R

**Purpose:** Programmatically deploy the API to Posit Connect

**Prerequisites:**
```r
Sys.setenv(CONNECT_SERVER = "https://pub.workshop.posit.team")
Sys.setenv(CONNECT_API_KEY = "your-api-key")
```

**Run it:**
```r
setwd("part_4_torch/part3/immunotherapy/3_share_model_plumber")
source("deploy_api.R")
```

**What happens:**
- Registers Connect account if needed
- Removes old deployment records
- Deploys `plumber.R` to Connect
- Returns API URL

**After deployment:**
1. Go to Connect UI → Your Content → Peptide Prediction API (Torch)
2. Set environment variables:
   - `CONNECT_SERVER` = https://pub.workshop.posit.team
   - `CONNECT_API_KEY` = your-api-key
3. Set content URL to `/plumber_torch/`

---

### 4_consume_api.R

**Purpose:** Call the deployed API from R

**Prerequisites:**
```r
Sys.setenv(CONNECT_SERVER = "https://pub.workshop.posit.team")
Sys.setenv(CONNECT_API_KEY = "your-api-key")
Sys.setenv(CONNECT_CONTENT_URL = "plumber_torch")
```

**Run it:**
```r
source("4_consume_api.R")
```

**What it does:**
- Tests single peptide: `LLTDAQRIV`
- Tests multiple peptides (comma-separated)
- Tests vector of peptides
- Returns predictions as tibble

**Example output:**
```
# A tibble: 1 × 2
  peptide   predicted_class
  <chr>     <chr>          
1 LLTDAQRIV WB             
```

---

## Complete Workflow

### Step-by-step execution:

```r
# Step 1: Train model
setwd("part_4_torch/part3/immunotherapy")
source("1_train_model.R")

# Step 2: Pin to Connect
Sys.setenv(CONNECT_SERVER = "https://pub.workshop.posit.team")
Sys.setenv(CONNECT_API_KEY = "your-api-key")
source("2_publish_model.R")

# Step 3: Deploy API
setwd("3_share_model_plumber")
source("deploy_api.R")

# Step 4: Configure API on Connect (via web UI)
# - Add environment variables
# - Set content URL to /plumber_torch/

# Step 5: Consume API
Sys.setenv(CONNECT_CONTENT_URL = "plumber_torch")
source("4_consume_api.R")
```

---

## Peptide Classes

- **NB (Non-Binder)**: Peptide does not bind to MHC molecule
- **WB (Weak Binder)**: Peptide binds weakly to MHC molecule
- **SB (Strong Binder)**: Peptide binds strongly to MHC molecule

**Clinical significance:**
Strong binders are good candidates for immunotherapy (e.g., cancer vaccines, T-cell therapies).

---

## Key Differences from Keras Version

### Model Architecture
**Keras (part_3):**
```r
model <- keras_model_sequential(
  list(
    layer_input(shape = 180),
    layer_dense(units = 180, activation = "relu"),
    layer_dropout(rate = 0.4),
    layer_dense(units = 90, activation = "relu"),
    layer_dropout(rate = 0.3),
    layer_dense(units = 3, activation = "softmax")
  )
)
```

**Torch (part_4_torch):**
```r
peptide_net <- nn_module(
  "PeptideBindingNet",
  initialize = function() {
    self$fc1 <- nn_linear(180, 180)
    self$fc2 <- nn_linear(180, 90)
    self$fc3 <- nn_linear(90, 3)
    self$relu <- nn_relu()
    self$dropout1 <- nn_dropout(0.4)
    self$dropout2 <- nn_dropout(0.3)
  },
  forward = function(x) {
    x %>%
      self$fc1() %>%
      self$relu() %>%
      self$dropout1() %>%
      self$fc2() %>%
      self$relu() %>%
      self$dropout2() %>%
      self$fc3()
  }
)
```

### Model Saving
- **Keras**: `keras$saving$save_model(model, "saved_model.keras")`
- **Torch**: `torch_save(model, "peptide_model_torch.pt")`

### Model Loading
- **Keras**: `keras$saving$load_model(mod_path)`
- **Torch**: `torch_load(mod_path)`

### Pin Names
- **Keras**: `"peptide_model"`
- **Torch**: `"peptide_model_torch"`

---

## Troubleshooting

### Model won't load in API
**Error:** `Error in torch_load: ...`

**Solution:** Ensure the pin name matches:
```r
mod_path <- pins::pin_download(con, "peptide_model_torch")  # Note: _torch suffix
```

### API deployment fails
**Error:** `Cannot change type of content`

**Solution:** Remove old deployment records:
```r
unlink("rsconnect", recursive = TRUE)
```

### 404 Not Found when calling API
**Error:** `Content not found (404)`

**Solution:** Check that:
1. API is deployed to Connect
2. `CONNECT_CONTENT_URL` is correct (e.g., `"plumber_torch"`)
3. Content URL in Connect settings is `/plumber_torch/`

---

## Production Considerations

1. **Model versioning**: Use pins versions to track model updates
2. **API authentication**: Set access controls in Connect
3. **Rate limiting**: Configure in Connect settings
4. **Monitoring**: Use Connect metrics to track API usage
5. **Error handling**: Add try-catch blocks for production
6. **Input validation**: Validate peptide sequences (length, valid amino acids)

---

## Next Steps

- Compare predictions between Keras and Torch versions
- Experiment with different architectures
- Add more endpoints (batch predictions, model info, health checks)
- Deploy to production Connect server
- Integrate with downstream applications
