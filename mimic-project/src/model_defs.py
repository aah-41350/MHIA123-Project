import torch
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset
from sklearn.isotonic import IsotonicRegression
from sklearn.metrics import brier_score_loss
from sklearn.calibration import calibration_curve
import torch.nn as nn

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
            nn.Linear(32, 1) # Note: Logits output for BCEWithLogitsLoss
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
    
    print(f"Calibration Complete. Brier Score: {brier_score_loss(y_val, iso_reg.transform(val_probs_raw)):.4f}")
    return model, iso_reg