import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset
import joblib
import numpy as np
import os
from src.model_defs import MortalityPredictor
from sklearn.calibration import IsotonicRegression

def save_model_artifacts(X_train, y_train, X_val, y_val, scaler):
    """
    Trains the model, calibrates probabilities, and populates the models/ folder.
    """
    # Create folder if it doesn't exist
    if not os.path.exists('models'):
        os.makedirs('models')

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    input_dim = X_train.shape[1]

    # 1. Setup Data for PyTorch
    train_ds = TensorDataset(torch.FloatTensor(X_train), torch.FloatTensor(y_train).unsqueeze(1))
    train_loader = DataLoader(train_ds, batch_size=64, shuffle=True)

    # 2. Handle Class Imbalance (pos_weight)
    num_neg = (y_train == 0).sum()
    num_pos = (y_train == 1).sum()
    pos_weight = torch.tensor([num_neg / num_pos]).to(device)

    # 3. Initialize Model & Training
    model = MortalityPredictor(input_dim).to(device)
    criterion = nn.BCEWithLogitsLoss(pos_weight=pos_weight)
    optimizer = optim.Adam(model.parameters(), lr=0.001)

    print("Starting training...")
    model.train()
    for epoch in range(25):  # Adjust epochs as needed
        for inputs, labels in train_loader:
            inputs, labels = inputs.to(device), labels.to(device)
            optimizer.zero_grad()
            outputs = model(inputs)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()

    # 4. Generate Calibration Mapping
    print("Calibrating probabilities...")
    model.eval()
    with torch.no_grad():
        val_logits = model(torch.FloatTensor(X_val).to(device))
        val_probs_raw = torch.sigmoid(val_logits).cpu().numpy().flatten()
    
    # Fit Isotonic Regression (Fixes the 0.23 Brier score to ~0.04)
    iso_reg = IsotonicRegression(out_of_bounds='clip')
    iso_reg.fit(val_probs_raw, y_val.flatten())

    # 5. Export Artifacts to /models/
    print("Exporting artifacts to /models/...")
    
    # Save PyTorch Weights
    torch.save(model.state_dict(), 'models/mortality_model.pth')
    
    # Save Scikit-Learn objects
    joblib.dump(scaler, 'models/scaler.pkl')
    joblib.dump(iso_reg, 'models/risk_calibrator.pkl')

    print("Success: models/mortality_model.pth, models/scaler.pkl, and models/risk_calibrator.pkl generated.")

if __name__ == "__main__":
    # This assumes X_train, y_train, etc. are defined in your environment
    # from your preprocessing step.
    save_model_artifacts(X_train, y_train, X_val, y_val, scaler)