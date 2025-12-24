import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset
import numpy as np
import joblib
import shap
import matplotlib.pyplot as plt
from sklearn.calibration import calibration_curve
from sklearn.isotonic import IsotonicRegression
from sklearn.metrics import brier_score_loss, roc_auc_score

# 1. Model Definition (Logits output)
class MortalityPredictor(nn.Module):
    def __init__(self, input_dim):
        super(MortalityPredictor, self).__init__()
        self.network = nn.Sequential(
            nn.Linear(input_dim, 64),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(64, 32),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(32, 1) 
        )
    def forward(self, x):
        return self.network(x)

def train_and_calibrate(X_train, y_train, X_val, y_val, feature_names):
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    
    # Prepare Tensors
    train_ds = TensorDataset(torch.FloatTensor(X_train), torch.FloatTensor(y_train).unsqueeze(1))
    train_loader = DataLoader(train_ds, batch_size=64, shuffle=True)
    
    # Address Class Imbalance
    pos_weight = torch.tensor([(y_train == 0).sum() / (y_train == 1).sum()]).to(device)
    
    model = MortalityPredictor(X_train.shape[1]).to(device)
    criterion = nn.BCEWithLogitsLoss(pos_weight=pos_weight)
    optimizer = optim.Adam(model.parameters(), lr=0.001)

    # --- Training Loop ---
    model.train()
    for epoch in range(20):
        for inputs, labels in train_loader:
            inputs, labels = inputs.to(device), labels.to(device)
            optimizer.zero_grad()
            loss = criterion(model(inputs), labels)
            loss.backward()
            optimizer.step()

    # --- Step 1: Calibration (Fixing the Probability "Over-confidence") ---
    model.eval()
    with torch.no_grad():
        val_logits = model(torch.FloatTensor(X_val).to(device))
        val_probs_raw = torch.sigmoid(val_logits).cpu().numpy().flatten()
    
    # Fit Isotonic Regression on 1D arrays
    iso_reg = IsotonicRegression(out_of_bounds='clip')
    iso_reg.fit(val_probs_raw, y_val.flatten())
    
    # Save the calibrated weights
    joblib.dump(iso_reg, 'models/risk_calibrator.pkl')
    torch.save(model.state_dict(), 'models/mortality_model.pth')
    
    print(f"Calibration Complete. Brier Score: {brier_score_loss(y_val, iso_reg.transform(val_probs_raw)):.4f}")

    # --- Step 2: SHAP Interpretability ---
    print("Generating SHAP values...")
    
    # Wrapper for SHAP to handle tensors and sigmoid
    def predict_for_shap(data):
        model.eval()
        with torch.no_grad():
            t = torch.FloatTensor(data).to(device)
            return torch.sigmoid(model(t)).cpu().numpy()

    # KernelExplainer is robust for PyTorch wrappers
    explainer = shap.KernelExplainer(predict_for_shap, X_train[:100])
    shap_values = explainer.shap_values(X_val[:50])
    
    # Plot Global Importance
    plt.figure(figsize=(10, 6))
    shap.summary_plot(shap_values, X_val[:50], feature_names=feature_names, show=False)
    plt.title("Preoperative Risk Factors (SHAP Values)")
    plt.savefig('models/shap_summary.png')
    
    return model, iso_reg

# Example call:
# model, calibrator = train_and_calibrate(X_train, y_train, X_val, y_val, feature_cols)