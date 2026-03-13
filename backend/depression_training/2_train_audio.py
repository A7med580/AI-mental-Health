"""
2_train_audio.py — Audio (COVAREP) depression model training.

Model: LightGBM classifier on session-level aggregated COVAREP features.
Trains in ~2-5 minutes on CPU.

Usage:
    cd backend/depression_training
    python 2_train_audio.py
"""
import os
import sys
import joblib
import numpy as np
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import (
    classification_report, confusion_matrix,
    roc_auc_score, f1_score
)
import lightgbm as lgb

sys.path.insert(0, os.path.dirname(__file__))
from config import (
    AUDIO_N_ESTIMATORS, AUDIO_MAX_DEPTH, AUDIO_LR, AUDIO_SUBSAMPLE,
    AUDIO_OUTPUT_FILE, AUDIO_SCALER_FILE, SEED, TRAINED_MODELS_DIR
)
from data_loader import get_splits, load_audio_data

os.makedirs(TRAINED_MODELS_DIR, exist_ok=True)


def train_audio():
    print("=" * 60)
    print("AUDIO MODEL — LightGBM on COVAREP features")
    print("=" * 60)

    train_df, dev_df = get_splits()
    X_train, y_train, X_dev, y_dev = load_audio_data(train_df, dev_df)

    if len(X_train) == 0:
        print("[ERROR] No training samples found. Check dataset path.")
        return

    # ── Normalize ───────────────────────────────────────────────
    scaler = StandardScaler()
    X_train = scaler.fit_transform(X_train)
    X_dev   = scaler.transform(X_dev)
    print(f"Feature dims after scaling: {X_train.shape[1]}")

    # ── Compute class weight for imbalanced DAIC-WOZ ──────────
    n_pos = y_train.sum()
    n_neg = len(y_train) - n_pos
    scale_pos_weight = n_neg / max(n_pos, 1)
    print(f"Class imbalance — neg:{n_neg} pos:{n_pos}  scale_pos_weight={scale_pos_weight:.2f}")

    # ── Train LightGBM ────────────────────────────────────────
    model = lgb.LGBMClassifier(
        n_estimators=AUDIO_N_ESTIMATORS,
        max_depth=AUDIO_MAX_DEPTH,
        learning_rate=AUDIO_LR,
        subsample=AUDIO_SUBSAMPLE,
        colsample_bytree=0.8,
        scale_pos_weight=scale_pos_weight,
        class_weight="balanced",
        random_state=SEED,
        n_jobs=-1,
        verbose=-1,
    )

    model.fit(
        X_train, y_train,
        eval_set=[(X_dev, y_dev)],
        callbacks=[lgb.early_stopping(50, verbose=False), lgb.log_evaluation(100)],
    )

    # ── Evaluate ──────────────────────────────────────────────
    y_pred      = model.predict(X_dev)
    y_pred_prob = model.predict_proba(X_dev)[:, 1]

    f1 = f1_score(y_dev, y_pred, average="binary")
    auc = roc_auc_score(y_dev, y_pred_prob) if len(np.unique(y_dev)) > 1 else 0.0

    print("\n── Dev Set Results ─────────────────────────")
    print(classification_report(y_dev, y_pred, target_names=["No Depression", "Depression"]))
    print(f"Confusion Matrix:\n{confusion_matrix(y_dev, y_pred)}")
    print(f"F1 (binary): {f1:.4f}  |  AUC-ROC: {auc:.4f}")

    # ── Save ──────────────────────────────────────────────────
    joblib.dump(model,  AUDIO_OUTPUT_FILE)
    joblib.dump(scaler, AUDIO_SCALER_FILE)
    print(f"\n✓ Model saved  → {AUDIO_OUTPUT_FILE}")
    print(f"✓ Scaler saved → {AUDIO_SCALER_FILE}")
    print(f"\nTop 10 important features:")
    fi = model.feature_importances_
    top_idx = np.argsort(fi)[::-1][:10]
    for rank, idx in enumerate(top_idx, 1):
        print(f"  {rank}. Feature index {idx}: {fi[idx]:.1f}")

    return model, scaler, f1, auc


if __name__ == "__main__":
    train_audio()
