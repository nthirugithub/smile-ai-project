import os
import json
from datetime import datetime

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

from joblib import dump

from sklearn.ensemble import (
    RandomForestClassifier,
    ExtraTreesClassifier
)


from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    balanced_accuracy_score,
    f1_score,
)

from sklearn.model_selection import (
    StratifiedKFold,
    cross_val_score,
    train_test_split,
)

from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.calibration import CalibratedClassifierCV


# =====================================================
# PATHS
# =====================================================

DATASET_PATH = "dataset/doctor_dataset_labeled.csv"

MODEL_PATH = "models/smile_ai_model.pkl"

SCALER_PATH = "models/scaler.pkl"

META_PATH = "models/smile_ai_model_meta.json"

FEATURE_IMPORTANCE_CSV = "reports/feature_importance.csv"

MODEL_COMPARISON_CSV = "reports/model_comparison.csv"

CONFUSION_MATRIX_PNG = "reports/confusion_matrix.png"

FEATURE_IMPORTANCE_PNG = "reports/feature_importance.png"

TRAINING_REPORT_TXT = "reports/training_report.txt"


# =====================================================
# CREATE FOLDERS
# =====================================================

os.makedirs("models", exist_ok=True)
os.makedirs("reports", exist_ok=True)


# =====================================================
# FEATURES
# =====================================================

FEATURE_COLUMNS = [
    "smile_width",
    "lip_opening",
    "face_ratio",
    "midline_deviation",
    "smile_symmetry",
    "smile_arc",
    "gingival_display",
    "buccal_corridor",
]

LABEL_NAMES = {
    0: "Normal",
    1: "Mild",
    2: "Moderate",
}



# =====================================================
# LOAD DATASET
# =====================================================

def load_dataset(path):

    df = pd.read_csv(path)

    missing = [c for c in FEATURE_COLUMNS if c not in df.columns]

    if missing:
        raise ValueError(f"Missing columns: {missing}")

    for col in FEATURE_COLUMNS:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    df = df.dropna(subset=FEATURE_COLUMNS)

    df = df.reset_index(drop=True)

    return df


# =====================================================
# MODEL CANDIDATES
# =====================================================

def make_models():

    return {

        "ExtraTrees": ExtraTreesClassifier(
            n_estimators=300,
            max_depth=None,
            min_samples_split=2,
            min_samples_leaf=1,
            max_features="sqrt",
            class_weight="balanced",
            random_state=42,
            n_jobs=-1,
        ),

        "RandomForest": RandomForestClassifier(
            n_estimators=300,
            max_depth=None,
            min_samples_split=2,
            min_samples_leaf=1,
            max_features="sqrt",
            class_weight="balanced",
            random_state=42,
            n_jobs=-1,
        ),

    }


# =====================================================
# MAIN
# =====================================================

def main():

    print("\n======================================")
    print("SMILE AI TRAINING PIPELINE")
    print("======================================")

    # ---------------------------------

    df = load_dataset(DATASET_PATH)

    df = df.dropna(subset=["clinical_label"])

    df["clinical_label"] = df["clinical_label"].astype(int)

    X = df[FEATURE_COLUMNS]

    y = df["clinical_label"]

    # ---------------------------------

    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        stratify=y,
        test_size=0.2,
        random_state=42
    )

    # ---------------------------------

    scaler = StandardScaler()

    X_train_scaled = scaler.fit_transform(X_train)

    X_test_scaled = scaler.transform(X_test)

    dump(scaler, SCALER_PATH)

    # ---------------------------------

    models = make_models()

    skf = StratifiedKFold(
        n_splits=5,
        shuffle=True,
        random_state=42
    )

    comparison_results = []

    best_model = None
    best_name = None
    best_score = -1

    # ---------------------------------

    for name, model in models.items():

        print(f"\nTraining: {name}")

        scores = cross_val_score(
            model,
            X_train_scaled,
            y_train,
            cv=skf,
            scoring="balanced_accuracy",
            n_jobs=-1,
        )

        mean_acc = scores.mean()

        print(f"CV Accuracy: {mean_acc:.4f}")

        comparison_results.append({
            "model": name,
            "cv_accuracy": mean_acc,
            "cv_std": scores.std(),
        })

        if mean_acc > best_score:
            best_score = mean_acc
            best_model = model
            best_name = name

    # ---------------------------------

    comparison_df = pd.DataFrame(comparison_results)

    comparison_df.to_csv(
        MODEL_COMPARISON_CSV,
        index=False
    )

    # ---------------------------------

    print(f"\nBest Model: {best_name}")

    # Probability calibration

    calibrated_model = CalibratedClassifierCV(
        best_model,
        method="sigmoid",
        cv=3
    )

    calibrated_model.fit(X_train_scaled, y_train)

    # ---------------------------------

    y_pred = calibrated_model.predict(X_test_scaled)

    y_proba = calibrated_model.predict_proba(X_test_scaled)

    confidence_scores = np.max(y_proba, axis=1)

    # ---------------------------------

    accuracy = accuracy_score(y_test, y_pred)

    balanced_acc = balanced_accuracy_score(
        y_test,
        y_pred
    )

    f1 = f1_score(
        y_test,
        y_pred,
        average="weighted"
    )

    # ---------------------------------

    print("\n======================================")
    print(f"Test Accuracy: {accuracy:.4f}")
    print(f"Balanced Accuracy: {balanced_acc:.4f}")
    print(f"Weighted F1 Score: {f1:.4f}")
    print("======================================")

    # ---------------------------------

    report = classification_report(
        y_test,
        y_pred,
        target_names=[
            LABEL_NAMES[i]
            for i in sorted(LABEL_NAMES.keys())
        ],
        digits=4,
        zero_division=0
    )

    print("\nClassification Report:")
    print(report)
    print("\nTraining Distribution:")
    print(y.value_counts())

    # ---------------------------------

    cm = confusion_matrix(y_test, y_pred)

    plt.figure(figsize=(7, 6))

    sns.heatmap(
        cm,
        annot=True,
        fmt="d",
        cmap="Blues",
        xticklabels=LABEL_NAMES.values(),
        yticklabels=LABEL_NAMES.values()
    )

    plt.xlabel("Predicted")

    plt.ylabel("Actual")

    plt.title("Smile AI Confusion Matrix")

    plt.tight_layout()

    plt.savefig(CONFUSION_MATRIX_PNG)

    plt.close()

    # ---------------------------------

    fitted_model = calibrated_model.estimator

    if hasattr(fitted_model, "feature_importances_"):

        importances = pd.Series(
            fitted_model.feature_importances_,
            index=FEATURE_COLUMNS
        ).sort_values(ascending=False)

        print("\nFeature Importances:")
        print(importances)

        importance_df = pd.DataFrame({
            "feature": importances.index,
            "importance": importances.values
        })

        importance_df.to_csv(
            FEATURE_IMPORTANCE_CSV,
            index=False
        )

        plt.figure(figsize=(8, 5))

        sns.barplot(
            x=importances.values,
            y=importances.index
        )

        plt.title("Feature Importance")

        plt.tight_layout()

        plt.savefig(FEATURE_IMPORTANCE_PNG)

        plt.close()

    # ---------------------------------

    dump(calibrated_model, MODEL_PATH)

    # ---------------------------------

    metadata = {

        "training_date":
            datetime.now().strftime("%Y-%m-%d %H:%M:%S"),

        "model_name":
            best_name,

        "cv_accuracy":
            float(best_score),

        "test_accuracy":
            float(accuracy),

        "balanced_accuracy":
            float(balanced_acc),

        "weighted_f1":
            float(f1),

        "feature_columns":
            FEATURE_COLUMNS,

        "label_names":
            LABEL_NAMES,

        "average_confidence":
            float(np.mean(confidence_scores)),

        "dataset_size":
            int(len(df)),
    }

    with open(META_PATH, "w") as f:
        json.dump(metadata, f, indent=2)

    # ---------------------------------

    with open(TRAINING_REPORT_TXT, "w") as f:

        f.write("SMILE AI TRAINING REPORT\n")
        f.write("============================\n\n")

        f.write(f"Model: {best_name}\n")

        f.write(f"CV Accuracy: {best_score:.4f}\n")

        f.write(f"Test Accuracy: {accuracy:.4f}\n")

        f.write(f"Balanced Accuracy: {balanced_acc:.4f}\n")

        f.write(f"Weighted F1 Score: {f1:.4f}\n")

        f.write(
            f"Average Confidence: "
            f"{np.mean(confidence_scores):.4f}\n\n"
        )

        f.write("Classification Report\n")
        f.write("=====================\n")

        f.write(report)

    # ---------------------------------

    #print("\nFeature Importances:")
   # for feature, importance in zip(FEATURE_COLUMNS, best_model.feature_importances_):
    #    print(f"{feature}: {importance:.4f}")

    print("\n======================================")
    print("TRAINING COMPLETED SUCCESSFULLY")
    print("======================================")

    print(f"\nModel saved: {MODEL_PATH}")

    print(f"Scaler saved: {SCALER_PATH}")

    print(f"Metadata saved: {META_PATH}")

    print(f"Confusion matrix saved: {CONFUSION_MATRIX_PNG}")

    print(f"Feature importance saved: {FEATURE_IMPORTANCE_PNG}")

    print(f"Training report saved: {TRAINING_REPORT_TXT}")

# =====================================================

if __name__ == "__main__":
    main()