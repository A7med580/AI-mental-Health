"""
data_loader.py — Loads and preprocesses DAIC-WOZ data for all 3 modalities.

Usage:
    from data_loader import load_audio_data, load_text_data, load_visual_data
"""
import os
import warnings
import numpy as np
import pandas as pd
from scipy.stats import skew
from tqdm import tqdm
from config import (
    DATASET_DIR, TRAIN_SPLIT, DEV_SPLIT,
    AUDIO_AGG_STATS, AU_COLS, LABEL_BINARY, LABEL_SCORE,
    COVAREP_SKIP_COLS, AU_SKIP_COLS, VISUAL_SEQ_LEN, SEED
)

warnings.filterwarnings("ignore")
np.random.seed(SEED)


def _load_labels(split_csv: str) -> pd.DataFrame:
    """Load a split CSV and return a DataFrame with participant IDs and labels."""
    df = pd.read_csv(split_csv)
    df["Participant_ID"] = df["Participant_ID"].astype(int)
    return df[["Participant_ID", LABEL_BINARY, LABEL_SCORE]]


# ─────────────────────────────────────────
# AUDIO: COVAREP feature aggregation
# ─────────────────────────────────────────

def _aggregate_covarep(pid: int) -> np.ndarray | None:
    """
    Load *_COVAREP.csv for a participant and aggregate to a fixed-length
    feature vector: [mean, std, min, max, skew, median] per column.
    Returns None if file is missing or has <10 valid rows.
    """
    path = os.path.join(DATASET_DIR, f"{pid}_COVAREP.csv")
    if not os.path.exists(path):
        return None
    try:
        df = pd.read_csv(path, header=None)
        df = df.iloc[:, COVAREP_SKIP_COLS:]       # drop frame-index col
        df = df.replace([np.inf, -np.inf], np.nan)
        df = df.dropna(how="any")
        if len(df) < 10:
            return None
        vals = df.values.astype(np.float32)
        feats = []
        feats.append(np.mean(vals, axis=0))
        feats.append(np.std(vals, axis=0))
        feats.append(np.min(vals, axis=0))
        feats.append(np.max(vals, axis=0))
        feats.append(skew(vals, axis=0))
        feats.append(np.median(vals, axis=0))
        return np.concatenate(feats)
    except Exception as e:
        print(f"  [WARN] COVAREP {pid}: {e}")
        return None


def load_audio_data(train_df: pd.DataFrame, dev_df: pd.DataFrame):
    """
    Returns (X_train, y_train, X_dev, y_dev) as numpy arrays.
    """
    def _build(df):
        X, y = [], []
        for _, row in tqdm(df.iterrows(), total=len(df), desc="Loading COVAREP"):
            pid = int(row["Participant_ID"])
            feat = _aggregate_covarep(pid)
            if feat is not None:
                X.append(feat)
                y.append(int(row[LABEL_BINARY]))
        return np.array(X, dtype=np.float32), np.array(y, dtype=np.int32)

    X_tr, y_tr = _build(train_df)
    X_dev, y_dev = _build(dev_df)
    print(f"Audio → Train: {X_tr.shape}, Dev: {X_dev.shape}")
    return X_tr, y_tr, X_dev, y_dev


# ─────────────────────────────────────────
# TEXT: Transcript concatenation
# ─────────────────────────────────────────

def _load_transcript(pid: int) -> str | None:
    """
    Load *_TRANSCRIPT.csv and concatenate all Participant utterances
    into one document string.
    """
    path = os.path.join(DATASET_DIR, f"{pid}_TRANSCRIPT.csv")
    if not os.path.exists(path):
        return None
    try:
        df = pd.read_csv(path, sep="\t", header=None,
                         names=["start", "stop", "speaker", "value"],
                         on_bad_lines="skip")
        # Keep only participant (non-interviewer) rows
        participant_rows = df[df["speaker"].str.strip().str.upper() == "PARTICIPANT"]
        utts = participant_rows["value"].dropna().astype(str).tolist()
        return " ".join(utts).strip() if utts else None
    except Exception as e:
        print(f"  [WARN] Transcript {pid}: {e}")
        return None


def load_text_data(train_df: pd.DataFrame, dev_df: pd.DataFrame):
    """
    Returns (train_texts, train_labels, dev_texts, dev_labels).
    Where texts are lists of strings, labels are lists of ints.
    """
    def _build(df):
        texts, labels = [], []
        for _, row in tqdm(df.iterrows(), total=len(df), desc="Loading transcripts"):
            pid = int(row["Participant_ID"])
            text = _load_transcript(pid)
            if text and len(text.split()) > 5:  # skip near-empty sessions
                texts.append(text)
                labels.append(int(row[LABEL_BINARY]))
        return texts, labels

    tr_texts, tr_labels = _build(train_df)
    dev_texts, dev_labels = _build(dev_df)
    print(f"Text → Train: {len(tr_texts)}, Dev: {len(dev_texts)}")
    return tr_texts, tr_labels, dev_texts, dev_labels


# ─────────────────────────────────────────
# VISUAL: CLNF Action Units (time-series)
# ─────────────────────────────────────────

def _load_aus(pid: int, seq_len: int = VISUAL_SEQ_LEN) -> np.ndarray | None:
    """
    Load *_CLNF_AUs.txt for a participant.
    Returns a (seq_len, n_aus) array, uniformly sampled or padded.
    """
    path = os.path.join(DATASET_DIR, f"{pid}_CLNF_AUs.txt")
    if not os.path.exists(path):
        return None
    try:
        df = pd.read_csv(path, sep=",", skipinitialspace=True)
        df.columns = df.columns.str.strip()
        # Select the AU columns that exist in the file
        available_au = [c for c in AU_COLS if c in df.columns]
        if len(available_au) == 0:
            return None
        vals = df[available_au].values.astype(np.float32)
        vals = np.nan_to_num(vals, nan=0.0)
        n_frames = len(vals)
        # Uniform sampling to fixed seq_len
        if n_frames >= seq_len:
            indices = np.linspace(0, n_frames - 1, seq_len, dtype=int)
            vals = vals[indices]
        else:
            # Pad with zeros
            pad = np.zeros((seq_len - n_frames, vals.shape[1]), dtype=np.float32)
            vals = np.vstack([vals, pad])
        return vals  # (seq_len, n_aus)
    except Exception as e:
        print(f"  [WARN] AUs {pid}: {e}")
        return None


def load_visual_data(train_df: pd.DataFrame, dev_df: pd.DataFrame):
    """
    Returns (X_train, y_train, X_dev, y_dev) as numpy arrays.
    Shape: (N, VISUAL_SEQ_LEN, n_aus)
    """
    def _build(df):
        X, y = [], []
        for _, row in tqdm(df.iterrows(), total=len(df), desc="Loading AUs"):
            pid = int(row["Participant_ID"])
            seq = _load_aus(pid)
            if seq is not None:
                X.append(seq)
                y.append(int(row[LABEL_BINARY]))
        return np.array(X, dtype=np.float32), np.array(y, dtype=np.int32)

    X_tr, y_tr = _build(train_df)
    X_dev, y_dev = _build(dev_df)
    print(f"Visual → Train: {X_tr.shape}, Dev: {X_dev.shape}")
    return X_tr, y_tr, X_dev, y_dev


# ─────────────────────────────────────────
# MAIN: Load all splits once
# ─────────────────────────────────────────

def get_splits():
    train_df = _load_labels(TRAIN_SPLIT)
    dev_df   = _load_labels(DEV_SPLIT)
    return train_df, dev_df


if __name__ == "__main__":
    train_df, dev_df = get_splits()
    print(f"Train participants: {len(train_df)} | Dev: {len(dev_df)}")
    print(f"Train label distribution:\n{train_df[LABEL_BINARY].value_counts()}")
    print(f"Dev label distribution:\n{dev_df[LABEL_BINARY].value_counts()}")
