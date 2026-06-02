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

from sklearn.impute import SimpleImputer

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

DATASET_PATH = "dataset/smile_dataset.csv"

LABELED_DATASET_PATH = "dataset/smile_dataset_labeled.csv"

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
    3: "Severe",
}


# =====================================================
# NORMALIZATION
# =====================================================

def minmax(series):

    series = pd.to_numeric(series, errors="coerce")

    smin = series.min()
    smax = series.max()

    if pd.isna(smin) or pd.isna(smax) or smax == smin:
        return pd.Series(np.zeros(len(series)), index=series.index)

    return (series - smin) / (smax - smin)


# =====================================================
# OUTLIER CLIPPING
# =====================================================

def clip_outliers(df, columns):

    df = df.copy()

    for col in columns:

        q1 = df[col].quantile(0.25)
        q3 = df[col].quantile(0.75)

        iqr = q3 - q1

        lower = q1 - 1.5 * iqr
        upper = q3 + 1.5 * iqr

        df[col] = df[col].clip(lower, upper)

    return df


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

    df = clip_outliers(df, FEATURE_COLUMNS)

    df = df.reset_index(drop=True)

    return df


# =====================================================
# WEAK LABEL GENERATION
# =====================================================

def build_weak_labels(df):

    work = df.copy()

    work["symmetry_n"] = minmax(work["smile_symmetry"])

    work["midline_n"] = minmax(work["midline_deviation"])

    work["gingival_n"] = minmax(work["gingival_display"])

    work["buccal_issue_n"] = 1.0 - minmax(work["buccal_corridor"])

    work["arc_issue_n"] = minmax(work["smile_arc"].abs())

    work["face_ratio_issue_n"] = minmax(
        (work["face_ratio"] - work["face_ratio"].median()).abs()
    )

    work["smile_width_n"] = minmax(work["smile_width"])

    work["lip_opening_n"] = minmax(work["lip_opening"])

    # Clinical-style weighted severity score

    work["severity_score"] = (
        0.28 * work["midline_n"]
        + 0.26 * work["symmetry_n"]
        + 0.16 * work["gingival_n"]
        + 0.12 * work["buccal_issue_n"]
        + 0.08 * work["arc_issue_n"]
        + 0.05 * work["face_ratio_issue_n"]
        + 0.03 * work["smile_width_n"]
        + 0.02 * work["lip_opening_n"]
    )

    work["severity_label"] = pd.qcut(
        work["severity_score"].rank(method="first"),
        q=4,
        labels=False
    ).astype(int)

    return work


# =====================================================
# MODEL CANDIDATES
# =====================================================

def make_models():

    return {
        "ExtraTrees": ExtraTreesClassifier(
            n_estimators=500,
            random_state=42,
            class_weight="balanced_subsample",
            min_samples_leaf=2,
            n_jobs=-1,
        ),

        "RandomForest": RandomForestClassifier(
            n_estimators=500,
            random_state=42,
            class_weight="balanced_subsample",
            min_samples_leaf=2,
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

    df = build_weak_labels(df)

    df.to_csv(LABELED_DATASET_PATH, index=False)

    X = df[FEATURE_COLUMNS]

    y = df["severity_label"]

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
            scoring="accuracy",
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
    )

    print("\nClassification Report:")
    print(report)

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