import torch
import joblib
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.impute import SimpleImputer
from src.model_defs import MortalityPredictor
from src.interpret import generate_shap_plots
from src.db import attach_duckdb, duckdb_to_df, load_sql

def run_pipeline():
    # 1. DATA ACQUISITION & PREPROCESSING
    attach_duckdb("remote_mimic")
    query = load_sql("rev-cohort.sql")
    df = duckdb_to_df(query)
    print(f"Initial Data Shape: {df.shape}")

    # --- Step A: Define Feature Groups ---
    # Continuous features need scaling + median imputation
    continuous_cols = ['anchor_age', 'heart_rate_mean', 'sbp_mean', 'dbp_mean', 'mbp_mean',
                       'resp_rate_mean', 'spo2_mean', 'hematocrit', 'hemoglobin', 'wbc',
                       'platelet', 'creatinine', 'bun', 'ck_mb']
    # Score/Binary features need 0 imputation
    score_cols = ['charlson_comorbidity_index', 'prev_mi', 'stroke_history']

    # --- Step B: Handle Missing Values (The "Dual Strategy") ---
    # 1. Impute Continuous with MEDIAN
    imputer = SimpleImputer(strategy='median')
    df[continuous_cols] = imputer.fit_transform(df[continuous_cols])

    # 2. Impute Scores with ZERO (Assume NULL = Absence of condition)
    df[score_cols] = df[score_cols].fillna(0)

    # --- Step C: Encoding ---
    le = LabelEncoder()
    df['gender'] = le.fit_transform(df['gender'])

    # Combine all features
    feature_cols = continuous_cols + score_cols + ['gender']
    X = df[feature_cols].values
    y = df['label'].values

    # --- Step D: Stratified Splitting ---
    # Stratify=y ensures we have the same % of mortality in Train, Val, and Test
    X_train, X_temp, y_train, y_temp = train_test_split(X, y, test_size=0.3, stratify=y, random_state=42)
    X_val, X_test, y_val, y_test = train_test_split(X_temp, y_temp, test_size=0.5, stratify=y_temp, random_state=42)

    # --- Step E: Scaling (Standardization) ---
    # CRITICAL: Fit scaler ONLY on X_train to prevent info leakage from Test set
    scaler = StandardScaler()
    X_train = scaler.fit_transform(X_train)
    X_val = scaler.transform(X_val)
    X_test = scaler.transform(X_test)
    
    # ==========================================
    # 3. Addressing Class Imbalance
    # ==========================================
    # Calculate positive weight for BCEWithLogitsLoss
    # Formula: number_of_negatives / number_of_positives
    num_neg = (y_train == 0).sum()
    num_pos = (y_train == 1).sum()
    pos_weight_value = num_neg / num_pos

    print("-" * 30)
    print(f"Train Shape: {X_train.shape}")
    print(f"Class Balance (Train): {num_neg} Survivors vs {num_pos} Deaths")
    print(f"Calculated pos_weight: {pos_weight_value:.4f}")
    print("-" * 30)

    # ==========================================
    # 4. Prepare for PyTorch
    # ==========================================
    # Convert to Tensors
    X_train_tensor = torch.FloatTensor(X_train)
    y_train_tensor = torch.FloatTensor(y_train).unsqueeze(1)
    pos_weight_tensor = torch.FloatTensor([pos_weight_value])

    print("Ready for Model Training.")
    
    # 2. MODEL INITIALIZATION
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = MortalityPredictor(input_dim=len(feature_cols)).to(device)
    
    # 3. TRAINING & CALIBRATION
    # ... (Train your model and run IsotonicRegression) ...
    
    # 4. SAVE ARTIFACTS
    print("Saving artifacts...")
    torch.save(model.state_dict(), 'models/mortality_model.pth')
    joblib.dump(scaler, 'models/scaler.pkl')
    joblib.dump(iso_reg, 'models/calibrator.pkl')
    
    # 5. INTERPRETABILITY
    print("Generating SHAP explanations...")
    generate_shap_plots(model, X_train, X_test, feature_cols, device)
    
    print("Pipeline Complete! Check the 'models/' folder for results.")

if __name__ == "__main__":
    run_pipeline()