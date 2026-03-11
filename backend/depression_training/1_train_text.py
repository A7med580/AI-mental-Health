"""
1_train_text.py — Text (Transcript) depression model training.

Model: DistilBERT fine-tuned binary classifier on participant transcript text.
This model typically achieves the highest individual-modality performance.

Usage:
    cd backend/depression_training
    python 1_train_text.py

Note: Downloads DistilBERT (~250MB) to HF_HOME on first run.
      Ensure HF_HOME is set to 1TB drive in your shell (see .zshrc).
"""
import os
import sys
import torch
import numpy as np
from torch.utils.data import Dataset, DataLoader
from sklearn.metrics import f1_score, roc_auc_score, classification_report
from transformers import (
    DistilBertTokenizerFast,
    DistilBertForSequenceClassification,
    get_linear_schedule_with_warmup,
)

sys.path.insert(0, os.path.dirname(__file__))
from config import (
    TEXT_MODEL_NAME, TEXT_MAX_LENGTH, TEXT_BATCH_SIZE,
    TEXT_EPOCHS, TEXT_LR, TEXT_WARMUP_STEPS,
    TEXT_WEIGHT_DECAY, TEXT_OUTPUT_FILE, SEED, TRAINED_MODELS_DIR
)
from data_loader import get_splits, load_text_data

os.makedirs(TRAINED_MODELS_DIR, exist_ok=True)
torch.manual_seed(SEED)
np.random.seed(SEED)

DEVICE = torch.device("mps" if torch.backends.mps.is_available() else
                       "cuda" if torch.cuda.is_available() else "cpu")
print(f"Using device: {DEVICE}")


# ── Dataset ────────────────────────────────────────────────────────────
class TranscriptDataset(Dataset):
    def __init__(self, texts, labels, tokenizer, max_length):
        self.encodings = tokenizer(
            texts,
            truncation=True,
            padding="max_length",
            max_length=max_length,
            return_tensors="pt",
        )
        self.labels = torch.tensor(labels, dtype=torch.long)

    def __len__(self):
        return len(self.labels)

    def __getitem__(self, idx):
        return {
            "input_ids":      self.encodings["input_ids"][idx],
            "attention_mask": self.encodings["attention_mask"][idx],
            "labels":         self.labels[idx],
        }


# ── Training ───────────────────────────────────────────────────────────
def train_text():
    print("=" * 60)
    print("TEXT MODEL — DistilBERT on DAIC-WOZ Transcripts")
    print("=" * 60)

    train_df, dev_df = get_splits()
    tr_texts, tr_labels, dv_texts, dv_labels = load_text_data(train_df, dev_df)

    if len(tr_texts) == 0:
        print("[ERROR] No training text samples. Check dataset path.")
        return

    # ── Tokenizer & model ──────────────────────────────────────────────
    print(f"\nLoading {TEXT_MODEL_NAME} ...")
    tokenizer = DistilBertTokenizerFast.from_pretrained(TEXT_MODEL_NAME)
    model = DistilBertForSequenceClassification.from_pretrained(
        TEXT_MODEL_NAME, num_labels=2
    )
    model.to(DEVICE)

    # ── Class weights ─────────────────────────────────────────────────
    n_pos = sum(tr_labels)
    n_neg = len(tr_labels) - n_pos
    cw    = torch.tensor([1.0, n_neg / max(n_pos, 1)], dtype=torch.float32).to(DEVICE)
    print(f"Class weights: neg=1.0 | pos={cw[1].item():.2f}")

    # ── Datasets & loaders ─────────────────────────────────────────────
    train_ds = TranscriptDataset(tr_texts, tr_labels, tokenizer, TEXT_MAX_LENGTH)
    dev_ds   = TranscriptDataset(dv_texts, dv_labels, tokenizer, TEXT_MAX_LENGTH)
    train_loader = DataLoader(train_ds, batch_size=TEXT_BATCH_SIZE, shuffle=True)
    dev_loader   = DataLoader(dev_ds,   batch_size=TEXT_BATCH_SIZE)

    # ── Optimizer & scheduler ─────────────────────────────────────────
    optimizer = torch.optim.AdamW(
        model.parameters(), lr=TEXT_LR, weight_decay=TEXT_WEIGHT_DECAY
    )
    total_steps = len(train_loader) * TEXT_EPOCHS
    scheduler   = get_linear_schedule_with_warmup(
        optimizer, num_warmup_steps=TEXT_WARMUP_STEPS, num_training_steps=total_steps
    )
    criterion = torch.nn.CrossEntropyLoss(weight=cw)

    best_f1 = 0.0
    patience_counter = 0
    patience_limit   = 3

    print(f"\nTraining for {TEXT_EPOCHS} epochs...")
    for epoch in range(1, TEXT_EPOCHS + 1):
        # ── Train ────────────────────────────────────────────────────
        model.train()
        total_loss = 0.0
        for batch in train_loader:
            optimizer.zero_grad()
            input_ids = batch["input_ids"].to(DEVICE)
            attention_mask = batch["attention_mask"].to(DEVICE)
            labels = batch["labels"].to(DEVICE)

            outputs = model(input_ids=input_ids, attention_mask=attention_mask)
            loss = criterion(outputs.logits, labels)
            loss.backward()
            torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
            optimizer.step()
            scheduler.step()
            total_loss += loss.item()

        # ── Evaluate ─────────────────────────────────────────────────
        model.eval()
        all_preds, all_probs, all_labels = [], [], []
        with torch.no_grad():
            for batch in dev_loader:
                input_ids = batch["input_ids"].to(DEVICE)
                attn_mask = batch["attention_mask"].to(DEVICE)
                outputs   = model(input_ids=input_ids, attention_mask=attn_mask)
                probs     = torch.softmax(outputs.logits, dim=-1)[:, 1].cpu().numpy()
                preds     = outputs.logits.argmax(dim=-1).cpu().numpy()
                all_probs.extend(probs)
                all_preds.extend(preds)
                all_labels.extend(batch["labels"].numpy())

        f1  = f1_score(all_labels, all_preds, average="binary", zero_division=0)
        auc = roc_auc_score(all_labels, all_probs) if len(np.unique(all_labels)) > 1 else 0.0
        avg_loss = total_loss / len(train_loader)
        print(f"Epoch {epoch:3d}/{TEXT_EPOCHS} | Loss: {avg_loss:.4f} | Dev F1: {f1:.4f} | AUC: {auc:.4f}")

        if f1 > best_f1:
            best_f1 = f1
            # Save full model for Transformers-compatible loading
            model.save_pretrained(TEXT_OUTPUT_FILE.replace(".pt", "_dir"))
            tokenizer.save_pretrained(TEXT_OUTPUT_FILE.replace(".pt", "_dir"))
            # Also save state dict for lightweight loading
            torch.save(model.state_dict(), TEXT_OUTPUT_FILE)
            patience_counter = 0
            print(f"  ✓ Best model saved (F1={best_f1:.4f})")
        else:
            patience_counter += 1
            if patience_counter >= patience_limit:
                print(f"\nEarly stopping at epoch {epoch}.")
                break

    # ── Final report ──────────────────────────────────────────────────
    print(f"\n── Final Dev Set Results (best F1={best_f1:.4f}) ───────────────")
    print(classification_report(all_labels, all_preds, target_names=["No Depression", "Depression"]))
    print(f"✓ Text model saved → {TEXT_OUTPUT_FILE}")
    return model, best_f1


if __name__ == "__main__":
    train_text()
