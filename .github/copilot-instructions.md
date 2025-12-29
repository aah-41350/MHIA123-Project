# AI Coding Agent Instructions for MHIA123-Project

## Project Overview
This is a **MIMIC-IV hospital mortality prediction** ML pipeline. Adult cardiac surgery patients' clinical data flows from a PostgreSQL MIMIC-IV database → feature engineering → PyTorch neural network → probability calibration → SHAP interpretability. Two workspaces: `mimic-project/` (production) and `playground/` (experimental).

## Architecture & Data Flow

### Database Layer (`src/db.py`)
- **DuckDB** proxies PostgreSQL MIMIC-IV via `attach_duckdb()` using environment variables (`.env`: `PGHOST`, `PGUSER`, `PGPASSWORD`, `PGDATABASE`, `PGPORT`)
- SQL queries in `sql/*.sql` define cohorts (e.g., `rev-cohort.sql`: cardiac surgery patients ≥18yo)
- `load_sql(filename)` reads queries from `./sql/` directory

### Data Pipeline (`main.py` → `src/pipeline.py`)
**Critical pattern: Dual imputation strategy**
- **Continuous features** (vitals, labs): Median imputation + StandardScaler (fit ONLY on train set to prevent leakage)
- **Score/binary features** (Charlson, comorbidities): Fill NA with 0 (assume absence of condition)
- **Stratified train/val/test split** (70/15/15) by `label` to maintain mortality rate balance

### Model Training (`src/model_defs.py`)
- `MortalityPredictor`: 2-hidden-layer PyTorch NN (input_dim → 64 → 32 → 1 logit)
- **Loss function**: `BCEWithLogitsLoss` with `pos_weight` to handle class imbalance
- **Calibration**: IsotonicRegression on validation logits→probabilities fixes over-confidence
- **Artifacts saved**: `models/mortality_model.pth`, `models/scaler.pkl`, `models/calibrator.pkl`

### Model Interpretability (`src/interpret.py`)
- `shap.KernelExplainer` wraps sigmoid-transformed model predictions
- Background data: 100 samples from training set
- SHAP summary plot saved to `models/shap_summary.png`

## Key Conventions & Patterns

### Feature Naming
Features in cohort SQL queries follow pattern: `{metric}_{statistic}` (e.g., `heart_rate_mean`, `sbp_mean`). Boolean/score columns are explicit: `charlson_comorbidity_index`, `prev_mi`, `stroke_history`.

### Model Workflow Checklist
1. Run `main.py` to execute full pipeline or use Jupyter notebooks (`notebooks/ml-notebook.ipynb`, `notebooks/project-torch.ipynb`) for iterative development
2. Modify `continuous_cols` and `score_cols` lists in `pipeline.py` to adjust features
3. Hyperparameters: batch_size=64, epochs=20, lr=0.001, dropout=(0.3, 0.2) — tune in `train_and_calibrate()`
4. **Never fit scaler on full dataset or test set** — data leakage violates train/val/test independence
5. Probability calibration (Isotonic Regression) is non-negotiable for clinical deployment

### File Organization
- `sql/`: Cohort definitions (`*-cohort.sql`) and demographic queries (`*-dem.sql`)
- `notebooks/`: Model-specific explorations (PyTorch, XGBoost, TensorFlow, etc.)
- `models/`: Trained weights and preprocessing artifacts (git-ignored)
- `src/`: Reusable modules (db, model_defs, pipeline, interpret)

## Critical Developer Workflows

### Running the Pipeline
```bash
cd mimic-project
pip install -r requirements.txt
python main.py  # Executes full pipeline: data load → train → calibrate → SHAP
```

### Jupyter Workflows
- Edit `notebooks/ml-notebook.ipynb` or `notebooks/project-torch.ipynb` for experimentation
- SQL exploration: use `sql/rev-cohort.sql` as template, test new cohorts in `playground/sql/cohorts.sql` first
- After finalizing a cohort, update `main.py` to use the validated SQL

### Debugging Model Predictions
- Logits vs. probabilities: model outputs **logits** (unbounded); apply `torch.sigmoid()` before evaluation
- Calibration testing: check Brier Score in `train_and_calibrate()` — expect ~0.15–0.25 for well-calibrated model
- SHAP interpretability: only run on small subsets (50 test samples) to avoid computational overhead

## External Dependencies & Integration

### Database
- **PostgreSQL MIMIC-IV**: Accessed via DuckDB + `postgres_scanner` extension
- **Environment setup** required: `.env` file with DB credentials (see `src/db.py` for expected vars)

### Key Libraries
- `torch`: Model training, GPU acceleration (auto-detects with `torch.cuda.is_available()`)
- `scikit-learn`: Preprocessing (StandardScaler, LabelEncoder, IsotonicRegression)
- `shap`: Model interpretability (KernelExplainer is slow but model-agnostic)
- `duckdb`: SQL query execution and PostgreSQL bridging

## Gotchas & Lessons Learned

1. **Logit vs. Probability**: Model outputs logits; never forget `torch.sigmoid()` when converting to clinical probabilities
2. **Class Imbalance**: `pos_weight` in BCEWithLogitsLoss is critical — compute as ratio of negative to positive samples
3. **Scaler Fitting**: Forgetting to fit scaler ONLY on training data is a common source of inflated validation metrics
4. **SHAP Runtime**: KernelExplainer is slow; use small background sets (~100 samples) and limit explanation samples
5. **SQL Cohort Changes**: Always test new cohorts in `playground/sql/` before modifying production `sql/` queries

## Code Review Checklist
- New features properly classified as continuous vs. score in imputation strategy?
- Stratification maintained in train/val/test splits?
- Scaler, calibrator, and model all saved with correct filenames?
- SHAP plots use appropriate feature names?
- Database connection code uses environment variables (never hardcoded credentials)?
