"""
4_train_fusion.py — Late-fusion meta-learner for multimodal depression detection.

Assumes all 3 individual models have been trained and their outputs are available.
Trains a Logistic Regression (or MLP) on the combined probability scores.

Usage:
    cd backend/depression_training
    # Run AFTER training all 3 individual models:
    python 1_train_text.py
    python 2_train_audio.py
    python 3_train_visual.py
    # Then:
    python 4_train_fusion.py
"""
import os
import sys
import importlib.util
import joblib
import numpy as np
import torch


def _import_from(module_path: str, attr: str):
    """Import a named attribute from a file path (works for digit-prefixed module names)."""
    spec   = importlib.util.spec_from_file_location("_mod", module_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return getattr(module, attr)
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    f1_score, roc_auc_score, classification_report, confusion_matrix
)

sys.path.insert(0, os.path.dirname(__file__))
from config import (
    AUDIO_OUTPUT_FILE, AUDIO_SCALER_FILE,
    VISUAL_OUTPUT_FILE, TEXT_OUTPUT_FILE,
    FUSION_OUTPUT_FILE, SEED, TRAINED_MODELS_DIR,
    VISUAL_HIDDEN_DIM, VISUAL_NUM_LAYERS, VISUAL_DROPOUT
)
from data_loader import get_splits, load_audio_data, load_text_data, load_visual_data

os.makedirs(TRAINED_MODELS_DIR, exist_ok=True)
np.random.seed(SEED)

DEVICE = torch.device("mps" if torch.backends.mps.is_available() else
                       "cuda" if torch.cuda.is_available() else "cpu")


# ── Audio probability extraction ───────────────────────────────────────
def get_audio_probs(X, scaler, model):
    X_scaled = scaler.transform(X)
    return model.predict_proba(X_scaled)[:, 1]


# ── Visual probability extraction ─────────────────────────────────────
_VISUAL_SCRIPT = os.path.join(os.path.dirname(__file__), "3_train_visual.py")
_TEXT_SCRIPT   = os.path.join(os.path.dirname(__file__), "1_train_text.py")


def get_visual_probs(X, model):
    model.eval()
    probs_all = []
    with torch.no_grad():
        for i in range(0, len(X), 16):
            batch = torch.tensor(X[i:i+16], dtype=torch.float32).to(DEVICE)
            logits = model(batch)
            probs  = torch.sigmoid(logits).cpu().numpy()
            probs_all.extend(probs)
    return np.array(probs_all)


# ── Text probability extraction ──────────────────────────────────────
def get_text_probs(texts, model, tokenizer):
    from config import TEXT_MAX_LENGTH
    from torch.utils.data import DataLoader
    TranscriptDataset = _import_from(_TEXT_SCRIPT, "TranscriptDataset")
    ds     = TranscriptDataset(texts, [0] * len(texts), tokenizer, TEXT_MAX_LENGTH)
    loader = DataLoader(ds, batch_size=8)
    model.eval()
    probs_all = []
    with torch.no_grad():
        for batch in loader:
            inp  = batch["input_ids"].to(DEVICE)
            mask = batch["attention_mask"].to(DEVICE)
            out  = model(input_ids=inp, attention_mask=mask)
            p    = torch.softmax(out.logits, dim=-1)[:, 1].cpu().numpy()
            probs_all.extend(p)
    return np.array(probs_all)


# ── Main fusion training ───────────────────────────────────────────────
def train_fusion():
    print("=" * 60)
    print("FUSION MODEL — Logistic Regression meta-learner")
    print("=" * 60)

    train_df, dev_df = get_splits()

    # ── Load audio model ──────────────────────────────────────────────
    print("\nLoading audio model...")
    audio_model  = joblib.load(AUDIO_OUTPUT_FILE)
    audio_scaler = joblib.load(AUDIO_SCALER_FILE)
    X_tr_a, y_tr, X_dv_a, y_dv = load_audio_data(train_df, dev_df)
    tr_audio_probs = get_audio_probs(X_tr_a, audio_scaler, audio_model)
    dv_audio_probs = get_audio_probs(X_dv_a, audio_scaler, audio_model)

    # ── Load visual model ─────────────────────────────────────────────
    print("Loading visual model...")
    DepressionBiLSTM = _import_from(_VISUAL_SCRIPT, "DepressionBiLSTM")
    meta  = torch.load(VISUAL_OUTPUT_FILE.replace(".pt", "_meta.pt"), map_location="cpu")
    vis_m = DepressionBiLSTM(meta["n_aus"], meta["hidden_dim"], meta["num_layers"], meta["dropout"]).to(DEVICE)
    vis_m.load_state_dict(torch.load(VISUAL_OUTPUT_FILE, map_location=DEVICE))
    X_tr_v, _, X_dv_v, _ = load_visual_data(train_df, dev_df)
    tr_visual_probs = get_visual_probs(X_tr_v, vis_m)
    dv_visual_probs = get_visual_probs(X_dv_v, vis_m)

    # ── Load text model ───────────────────────────────────────────────
    print("Loading text model...")
    from transformers import DistilBertForSequenceClassification, DistilBertTokenizerFast
    text_dir = TEXT_OUTPUT_FILE.replace(".pt", "_dir")
    text_tokenizer = DistilBertTokenizerFast.from_pretrained(text_dir)
    text_model     = DistilBertForSequenceClassification.from_pretrained(text_dir).to(DEVICE)
    tr_texts, _, dv_texts, _ = load_text_data(train_df, dev_df)
    tr_text_probs = get_text_probs(tr_texts, text_model, text_tokenizer)
    dv_text_probs = get_text_probs(dv_texts, text_model, text_tokenizer)

    # ── Stack probabilities (fallback to 0.5 if participant not in all modalities)
    # Note: Each modality subset may differ in size. We use audio labels as reference.
    # For a robust fusion, we align on participant_id. Here we use a simplified
    # stacking that assumes all 3 outputs cover the same N participants.
    min_tr = min(len(tr_audio_probs), len(tr_visual_probs), len(tr_text_probs))
    min_dv = min(len(dv_audio_probs), len(dv_visual_probs), len(dv_text_probs))

    X_tr_fused = np.column_stack([
        tr_audio_probs[:min_tr],
        tr_visual_probs[:min_tr],
        tr_text_probs[:min_tr],
    ])
    X_dv_fused = np.column_stack([
        dv_audio_probs[:min_dv],
        dv_visual_probs[:min_dv],
        dv_text_probs[:min_dv],
    ])
    y_tr_fused = y_tr[:min_tr]
    y_dv_fused = y_dv[:min_dv]

    print(f"\nFusion feature matrix — Train: {X_tr_fused.shape}, Dev: {X_dv_fused.shape}")
    print(f"Probability ranges:")
    mnames = ["Audio", "Visual", "Text"]
    for i, name in enumerate(mnames):
        print(f"  {name}: train [{X_tr_fused[:, i].min():.3f}, {X_tr_fused[:, i].max():.3f}]")

    # ── Logistic Regression meta-learner ──────────────────────────────
    fusion = LogisticRegression(
        C=1.0, class_weight="balanced", max_iter=500, random_state=SEED
    )
    fusion.fit(X_tr_fused, y_tr_fused)

    y_pred = fusion.predict(X_dv_fused)
    y_prob = fusion.predict_proba(X_dv_fused)[:, 1]
    f1  = f1_score(y_dv_fused, y_pred, average="binary", zero_division=0)
    auc = roc_auc_score(y_dv_fused, y_prob) if len(np.unique(y_dv_fused)) > 1 else 0.0

    print("\n── Fusion Model Dev Set Results ─────────────────────────────")
    print(classification_report(y_dv_fused, y_pred, target_names=["No Depression", "Depression"]))
    print(f"Confusion Matrix:\n{confusion_matrix(y_dv_fused, y_pred)}")
    print(f"F1: {f1:.4f} | AUC-ROC: {auc:.4f}")
    print(f"\nLearned modality weights (logit coef):")
    for name, coef in zip(mnames, fusion.coef_[0]):
        print(f"  {name}: {coef:+.4f}")

    joblib.dump(fusion, FUSION_OUTPUT_FILE)
    print(f"\n✓ Fusion model saved → {FUSION_OUTPUT_FILE}")
    return fusion, f1


if __name__ == "__main__":
    train_fusion()
