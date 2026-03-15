import os
import joblib
import pandas as pd
import numpy as np
from catboost import CatBoostClassifier
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score
# from imblearn.over_sampling import SMOTE

def train_adhd_behavioral_model(data_path: str = None, output_dir: str = "../Models/adhd"):
    """
    Retrains the ADHD behavioral model using clinical datasets.
    Supports ASRS-1.1 aligned features and behavioral indicators.
    """
    print("--- ADHD Behavioral Model Retraining Pipeline ---")
    
    # 1. Load / Consolidate Datasets
    # If no path provided, we'll create a clinical-aligned synthetic baseline for demonstration
    if data_path and os.path.exists(data_path):
        df = pd.read_csv(data_path)
    else:
        print("Warning: No clinical dataset provided. Using ASRS-1.1 synthetic baseline for demonstration.")
        df = generate_clinical_adhd_data(500)
    
    # 2. Feature Engineering
    # We focus on the features collected by the Flutter app
    target = 'adhd_label'
    features = [c for c in df.columns if c != target]
    
    X = df[features]
    y = df[target]
    
    # 3. Handle Class Imbalance
    print(f"Original class distribution: {np.bincount(y)}")
    X_res, y_res = X, y # Simplified: skip SMOTE if lib missing
    # print(f"Balanced class distribution: {np.bincount(y_res)}")
    
    # 4. Split
    X_train, X_test, y_train, y_test = train_test_split(X_res, y_res, test_size=0.2, random_state=42)
    
    # 5. Train CatBoost
    model = CatBoostClassifier(
        iterations=500,
        depth=6,
        learning_rate=0.03,
        loss_function='Logloss',
        verbose=100,
        random_seed=42
    )
    
    model.fit(X_train, y_train, eval_set=(X_test, y_test))
    
    # 6. Evaluate
    y_pred = model.predict(X_test)
    y_proba = model.predict_proba(X_test)[:, 1]
    
    print("\n--- Evaluation Results ---")
    print(classification_report(y_test, y_pred))
    print(f"ROC-AUC Score: {roc_auc_score(y_test, y_proba):.4f}")
    
    # 7. Save Model and Feature Names
    os.makedirs(output_dir, exist_ok=True)
    model_path = os.path.join(output_dir, "adhd_behavior_catboost.pkl")
    names_path = os.path.join(output_dir, "adhd_behavior_feature_names.pkl")
    
    joblib.dump(model, model_path)
    joblib.dump(features, names_path)
    
    print(f"\nModel saved to: {model_path}")
    print(f"Feature names saved to: {names_path}")

def generate_clinical_adhd_data(n=500):
    """Generates synthetic data aligned with ASRS-1.1 and App questions."""
    np.random.seed(42)
    data = []
    for _ in range(n):
        label = np.random.choice([0, 1])
        # ASRS-1.1 features (0-4 scale: Never to Very Often)
        # Patterns: ADHD=1 tends to have higher scores on inattention/hyperactivity
        base_noise = np.random.normal(0, 0.5)
        
        row = {
            'initial_q_0': int(np.clip(np.random.randint(0, 3) + (label * 2) + base_noise, 0, 4)),
            'initial_q_1': int(np.clip(np.random.randint(0, 3) + (label * 2) + base_noise, 0, 4)),
            'chat_q_0_score': int(np.clip(np.random.randint(0, 3) + (label * 2) + base_noise, 0, 4)),
            'chat_q_1_score': int(np.clip(np.random.randint(0, 3) + (label * 2) + base_noise, 0, 4)),
            'chat_q_2_score': int(np.clip(np.random.randint(0, 3) + (label * 2) + base_noise, 0, 4)),
            'chat_q_3_score': int(np.clip(np.random.randint(0, 3) + (label * 2) + base_noise, 0, 4)),
            'age': np.random.randint(18, 60),
            'adhd_label': label
        }
        data.append(row)
    return pd.DataFrame(data)

if __name__ == "__main__":
    train_adhd_behavioral_model()
