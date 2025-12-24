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