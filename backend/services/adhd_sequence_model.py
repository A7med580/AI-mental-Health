import torch
import torch.nn as nn

class ADHDSequenceLSTM(nn.Module):
    """
    Bidirectional LSTM for binary ADHD classification from facial Action Unit sequences.
    Input: (batch, seq_len, n_aus)
    Output: (batch, 1) — probability of ADHD
    """
    def __init__(self, input_dim: int = 17, hidden_dim: int = 64, num_layers: int = 2, dropout: float = 0.3):
        super().__init__()
        self.lstm = nn.LSTM(
            input_size=input_dim,
            hidden_size=hidden_dim,
            num_layers=num_layers,
            batch_first=True,
            bidirectional=True,
            dropout=dropout if num_layers > 1 else 0.0,
        )
        self.attention = nn.Linear(hidden_dim * 2, 1)
        self.classifier = nn.Sequential(
            nn.Dropout(dropout),
            nn.Linear(hidden_dim * 2, 32),
            nn.ReLU(),
            nn.Linear(32, 1),
        )

    def forward(self, x):
        # x: (batch, seq_len, input_dim)
        out, _ = self.lstm(x)                    # (batch, seq, hidden*2)
        attn_weights = torch.softmax(self.attention(out), dim=1)  # (batch, seq, 1)
        context = (out * attn_weights).sum(dim=1)                 # (batch, hidden*2)
        return self.classifier(context).squeeze(-1)               # (batch,)
