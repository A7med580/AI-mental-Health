"""
3_train_visual.py — Visual (CLNF Action Units) depression model training.

Model: Bidirectional LSTM on 17 facial Action Unit time-series.
Captures temporal dynamics of facial expressivity as a depression biomarker.

Usage:
    cd backend/depression_training
    python 3_train_visual.py
"""
import os
import sys
import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, TensorDataset
from sklearn.metrics import f1_score, roc_auc_score, classification_report

sys.path.insert(0, os.path.dirname(__file__))
from config import (
    VISUAL_SEQ_LEN, VISUAL_HIDDEN_DIM, VISUAL_NUM_LAYERS,
    VISUAL_DROPOUT, VISUAL_BATCH_SIZE, VISUAL_EPOCHS,
    VISUAL_LR, VISUAL_OUTPUT_FILE, SEED, TRAINED_MODELS_DIR
)
from data_loader import get_splits, load_visual_data

os.makedirs(TRAINED_MODELS_DIR, exist_ok=True)
torch.manual_seed(SEED)
np.random.seed(SEED)

DEVICE = torch.device("mps" if torch.backends.mps.is_available() else
                       "cuda" if torch.cuda.is_available() else "cpu")
print(f"Using device: {DEVICE}")


# ── Model ──────────────────────────────────────────────────────────────
class DepressionBiLSTM(nn.Module):
    """
    Bidirectional LSTM for binary depression classification from AU sequences.
    Input: (batch, seq_len, n_aus)
    Output: (batch, 1) — probability of depression
    """
    def __init__(self, input_dim: int, hidden_dim: int, num_layers: int, dropout: float):
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


# ── Training loop ──────────────────────────────────────────────────────
def train_visual():
    print("=" * 60)
    print("VISUAL MODEL — BiLSTM on CLNF Action Units")
    print("=" * 60)

    train_df, dev_df = get_splits()
    X_train, y_train, X_dev, y_dev = load_visual_data(train_df, dev_df)

    if len(X_train) == 0:
        print("[ERROR] No training samples found. Check dataset path.")
        return

    n_aus = X_train.shape[2]
    print(f"Sequence shape: {X_train.shape} | AU features: {n_aus}")

    # ── Class weights for imbalanced data ─────────────────────────────
    n_pos = y_train.sum()
    n_neg = len(y_train) - n_pos
    pos_weight = torch.tensor([n_neg / max(n_pos, 1)], dtype=torch.float32).to(DEVICE)

    # ── DataLoaders ───────────────────────────────────────────────────
    X_tr_t = torch.tensor(X_train, dtype=torch.float32)
    y_tr_t = torch.tensor(y_train, dtype=torch.float32)
    X_dv_t = torch.tensor(X_dev,   dtype=torch.float32)
    y_dv_t = torch.tensor(y_dev,   dtype=torch.float32)

    train_ds  = TensorDataset(X_tr_t, y_tr_t)
    dev_ds    = TensorDataset(X_dv_t, y_dv_t)
    train_loader = DataLoader(train_ds, batch_size=VISUAL_BATCH_SIZE, shuffle=True)
    dev_loader   = DataLoader(dev_ds,   batch_size=VISUAL_BATCH_SIZE)

    # ── Model, loss, optimizer ────────────────────────────────────────
    model     = DepressionBiLSTM(n_aus, VISUAL_HIDDEN_DIM, VISUAL_NUM_LAYERS, VISUAL_DROPOUT).to(DEVICE)
    criterion = nn.BCEWithLogitsLoss(pos_weight=pos_weight)
    optimizer = torch.optim.Adam(model.parameters(), lr=VISUAL_LR)
    scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(optimizer, patience=3, factor=0.5)

    best_f1   = 0.0
    patience_counter = 0
    patience_limit   = 7

    print(f"\nTraining for {VISUAL_EPOCHS} epochs (early stop patience={patience_limit})...")
    for epoch in range(1, VISUAL_EPOCHS + 1):
        # ── Train phase ──────────────────────────────────────────────
        model.train()
        total_loss = 0.0
        for xb, yb in train_loader:
            xb, yb = xb.to(DEVICE), yb.to(DEVICE)
            optimizer.zero_grad()
            logits = model(xb)
            loss   = criterion(logits, yb)
            loss.backward()
            nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
            optimizer.step()
            total_loss += loss.item()

        # ── Dev phase ────────────────────────────────────────────────
        model.eval()
        all_logits, all_labels = [], []
        with torch.no_grad():
            for xb, yb in dev_loader:
                xb = xb.to(DEVICE)
                all_logits.append(model(xb).cpu().numpy())
                all_labels.append(yb.numpy())

        logits_np = np.concatenate(all_logits)
        labels_np = np.concatenate(all_labels).astype(int)
        probs     = 1 / (1 + np.exp(-logits_np))
        preds     = (probs >= 0.5).astype(int)
        f1        = f1_score(labels_np, preds, average="binary", zero_division=0)
        auc       = roc_auc_score(labels_np, probs) if len(np.unique(labels_np)) > 1 else 0.0

        avg_loss = total_loss / len(train_loader)
        print(f"Epoch {epoch:3d}/{VISUAL_EPOCHS} | Loss: {avg_loss:.4f} | Dev F1: {f1:.4f} | AUC: {auc:.4f}")
        scheduler.step(1 - f1)  # minimize (1 - F1)

        if f1 > best_f1:
            best_f1 = f1
            torch.save(model.state_dict(), VISUAL_OUTPUT_FILE)
            patience_counter = 0
            print(f"  ✓ Best model saved (F1={best_f1:.4f})")
        else:
            patience_counter += 1
            if patience_counter >= patience_limit:
                print(f"\nEarly stopping at epoch {epoch} (no improvement for {patience_limit} epochs).")
                break

    # ── Final evaluation ──────────────────────────────────────────────
    print(f"\n── Final Dev Set Results (best F1={best_f1:.4f}) ───────────────")
    model.load_state_dict(torch.load(VISUAL_OUTPUT_FILE, map_location=DEVICE))
    model.eval()
    all_logits, all_labels = [], []
    with torch.no_grad():
        for xb, yb in dev_loader:
            xb = xb.to(DEVICE)
            all_logits.append(model(xb).cpu().numpy())
            all_labels.append(yb.numpy())
    logits_np = np.concatenate(all_logits)
    labels_np = np.concatenate(all_labels).astype(int)
    probs     = 1 / (1 + np.exp(-logits_np))
    preds     = (probs >= 0.5).astype(int)
    print(classification_report(labels_np, preds, target_names=["No Depression", "Depression"]))
    print(f"✓ Visual model saved → {VISUAL_OUTPUT_FILE}")

    # Save model metadata for the API loader
    meta_path = VISUAL_OUTPUT_FILE.replace(".pt", "_meta.pt")
    torch.save({"n_aus": n_aus, "hidden_dim": VISUAL_HIDDEN_DIM, "num_layers": VISUAL_NUM_LAYERS,
                "dropout": VISUAL_DROPOUT, "seq_len": VISUAL_SEQ_LEN}, meta_path)
    print(f"✓ Model metadata  → {meta_path}")

    return model, best_f1


if __name__ == "__main__":
    train_visual()
