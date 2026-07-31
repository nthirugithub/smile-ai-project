"""
Smile AI Phase 3 – Machine Learning Training Pipeline.

Design priorities:
- Clinical stability and generalization over raw accuracy
- Fully explainable model decisions
- Reproducible training with fixed random seeds
- Robust probability calibration for clinical decision support
- Comprehensive multi-model comparison and selection

Dataset Note:
    The existing doctor_dataset_labeled.csv was generated with the legacy FeatureExtractor.
    This pipeline regenerates features from raw images using the Phase 1 pipeline (FaceMesh3D +
    FeatureExtractor) to ensure feature-label consistency with the production system.
    If image regeneration fails (e.g., due to pose rejection), the clean legacy CSV is used
    as a documented fallback with feature drift warnings.

Critical Audit Findings:
    1. smile_width <-> buccal_corridor correlation = -1.000 (perfect multicollinearity)
       - Legacy buccal_corridor = (0.70 - smile_width)/0.70 was a deterministic alias.
       - New FeatureExtractor computes them independently. Regeneration resolves this.
    2. face_ratio is legacy range (0.78-0.94). New pipeline uses Farkas MorphH (1.20-1.45).
    3. Class imbalance: Normal=45, Mild=51, Moderate=14. Handled via class_weight='balanced'.
    4. Low inter-class feature separation in raw means (all classes share similar centroids).
       This limits peak accuracy but clinical stability remains the target.
"""

from __future__ import annotations

import json
import os
import warnings
from datetime import datetime
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import seaborn as sns

from sklearn.calibration import CalibratedClassifierCV, calibration_curve
from sklearn.ensemble import (
    ExtraTreesClassifier,
    GradientBoostingClassifier,
    HistGradientBoostingClassifier,
    RandomForestClassifier,
)
from sklearn.inspection import permutation_importance
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    balanced_accuracy_score,
    brier_score_loss,
    classification_report,
    confusion_matrix,
    f1_score,
    roc_auc_score,
)
from sklearn.model_selection import (
    RepeatedStratifiedKFold,
    StratifiedKFold,
    cross_val_score,
    train_test_split,
)
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import LabelBinarizer, PolynomialFeatures, StandardScaler
from sklearn.svm import SVC

try:
    from imblearn.over_sampling import SMOTE
    _SMOTE_AVAILABLE = True
except ImportError:
    _SMOTE_AVAILABLE = False

warnings.filterwarnings("ignore")


# =====================================================
# CONFIGURATION
# =====================================================

RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)

RAW_IMAGE_FOLDER = Path("raw_dataset/doctor_images")
LABELS_CSV = Path("dataset/doctor_dataset_labeled.csv")
REGENERATED_CSV = Path("dataset/regenerated_features_v2.csv")

MODEL_PATH = "models/smile_ai_model.pkl"
SCALER_PATH = "models/scaler.pkl"
META_PATH = "models/smile_ai_model_meta.json"

REPORTS_DIR = Path("reports")
REPORTS_DIR.mkdir(exist_ok=True)
Path("models").mkdir(exist_ok=True)

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

LABEL_NAMES = {0: "Normal", 1: "Mild", 2: "Moderate"}


# =====================================================
# PHASE 3B: FEATURE REGENERATION
# =====================================================

def regenerate_features_from_raw() -> pd.DataFrame | None:
    """
    Regenerates feature dataset from raw images using the Phase 1 pipeline.
    This ensures alignment between production feature extraction and training data.
    Returns a DataFrame with the clinical labels merged from the existing labeled CSV.
    """
    print("\n[Phase 3B] Regenerating features from raw images using Phase 1 pipeline...")

    try:
        from ai_engine.face_mesh_3d import FaceMesh3D
        from ai_engine.feature_extractor import FeatureExtractor
    except ImportError as e:
        print(f"  [WARN] Cannot import pipeline: {e}. Skipping regeneration.")
        return None

    if not RAW_IMAGE_FOLDER.exists():
        print(f"  [WARN] Raw image folder not found: {RAW_IMAGE_FOLDER}")
        return None

    # Load existing labels for merging
    existing_labels_df = pd.read_csv(LABELS_CSV)
    label_map = dict(zip(
        existing_labels_df["image_name"].str.strip(),
        existing_labels_df["clinical_label"].astype(float)
    ))

    mesh_detector = FaceMesh3D()
    VALID_EXT = {".jpg", ".jpeg", ".png", ".JPG", ".JPEG", ".PNG"}

    records = []
    skipped = []

    image_files = sorted([
        p for p in RAW_IMAGE_FOLDER.iterdir()
        if p.is_file() and p.suffix in VALID_EXT
    ])

    print(f"  Found {len(image_files)} raw images.")

    for img_path in image_files:
        img_name = img_path.name

        if img_name not in label_map:
            skipped.append(f"{img_name} -> No matching label in CSV")
            continue

        clinical_label = label_map[img_name]
        if pd.isna(clinical_label):
            skipped.append(f"{img_name} -> Label is NaN, skipping")
            continue

        try:
            result = mesh_detector.process_image(str(img_path))

            if result is None:
                skipped.append(f"{img_name} -> Face detection failed")
                continue

            quality_score = float(result.get("quality_score", 0.0) or 0.0)
            if quality_score < 0.30:
                skipped.append(f"{img_name} -> Quality too low ({quality_score:.4f})")
                continue

            landmarks = result["landmarks"]
            extractor = FeatureExtractor(landmarks)
            features = extractor.extract_all_features()

            records.append({
                "image_name": img_name,
                "smile_width": round(float(features["smile_width"]), 4),
                "lip_opening": round(float(features["lip_opening"]), 4),
                "face_ratio": round(float(features["face_ratio"]), 4),
                "midline_deviation": round(float(features["midline_deviation"]), 4),
                "smile_symmetry": round(float(features["smile_symmetry"]), 4),
                "smile_arc": round(float(features["smile_arc"]), 4),
                "gingival_display": round(float(features["gingival_display"]), 4),
                "buccal_corridor": round(float(features["buccal_corridor"]), 4),
                "quality_score": round(quality_score, 4),
                "clinical_label": int(clinical_label),
            })

        except Exception as e:
            skipped.append(f"{img_name} -> Error: {e}")

    print(f"  Regenerated: {len(records)} samples. Skipped: {len(skipped)}.")

    # Save skip log
    skip_log = REPORTS_DIR / "regen_skipped_images.txt"
    with open(skip_log, "w") as f:
        for item in skipped:
            f.write(item + "\n")

    if len(records) < 20:
        print(f"  [WARN] Only {len(records)} samples regenerated. Insufficient for training.")
        return None

    df = pd.DataFrame(records)
    df.to_csv(REGENERATED_CSV, index=False)
    print(f"  Saved regenerated features -> {REGENERATED_CSV}")
    return df


# =====================================================
# PHASE 3A + 3C: DATASET AUDIT & PREPARATION
# =====================================================

def audit_and_prepare_dataset(df: pd.DataFrame) -> tuple[pd.DataFrame, dict]:
    """
    Audits the dataset for quality issues, reports findings,
    and prepares a clean feature matrix.
    """
    print("\n[Phase 3A/3C] Dataset Audit & Preparation...")

    audit = {
        "n_samples": len(df),
        "n_features": len(FEATURE_COLUMNS),
        "label_distribution": df["clinical_label"].value_counts().sort_index().to_dict(),
        "missing_values": df[FEATURE_COLUMNS].isnull().sum().to_dict(),
        "duplicate_rows": int(df.duplicated(subset=FEATURE_COLUMNS).sum()),
        "warnings": [],
        "feature_stats": df[FEATURE_COLUMNS].describe().round(4).to_dict(),
    }

    # Multicollinearity check
    corr_matrix = df[FEATURE_COLUMNS].corr().abs()
    high_corr_pairs = []
    for i in range(len(FEATURE_COLUMNS)):
        for j in range(i + 1, len(FEATURE_COLUMNS)):
            c = corr_matrix.iloc[i, j]
            if c > 0.85:
                pair = (FEATURE_COLUMNS[i], FEATURE_COLUMNS[j], round(float(c), 4))
                high_corr_pairs.append(pair)
                audit["warnings"].append(
                    f"HIGH CORRELATION: {FEATURE_COLUMNS[i]} <-> {FEATURE_COLUMNS[j]} = {c:.4f}"
                )

    audit["high_correlation_pairs"] = high_corr_pairs

    # Outlier detection (IQR 1.5)
    outlier_counts = {}
    for col in FEATURE_COLUMNS:
        q1 = df[col].quantile(0.25)
        q3 = df[col].quantile(0.75)
        iqr = q3 - q1
        n_out = int(((df[col] < q1 - 1.5 * iqr) | (df[col] > q3 + 1.5 * iqr)).sum())
        if n_out > 0:
            outlier_counts[col] = n_out
    audit["outliers_per_feature"] = outlier_counts

    # Variance check
    low_var_features = []
    for col in FEATURE_COLUMNS:
        v = float(df[col].var())
        if v < 1e-5:
            low_var_features.append(col)
            audit["warnings"].append(f"LOW VARIANCE: {col} (var={v:.8f})")
    audit["low_variance_features"] = low_var_features

    print(f"  Samples: {audit['n_samples']}")
    print(f"  Label distribution: {audit['label_distribution']}")
    print(f"  Duplicate rows: {audit['duplicate_rows']}")
    print(f"  High correlation pairs: {len(high_corr_pairs)}")
    for w in audit["warnings"]:
        print(f"  [AUDIT WARNING] {w}")

    return df, audit


# =====================================================
# PHASE 3D: MODEL CANDIDATES
# =====================================================

def build_model_candidates() -> dict:
    """
    Builds the candidate model pool. All models use class_weight='balanced'
    to address the class imbalance (Normal=45, Mild=51, Moderate=14).
    """
    return {
        "ExtraTrees": ExtraTreesClassifier(
            n_estimators=400,
            max_depth=None,
            min_samples_split=2,
            min_samples_leaf=2,
            max_features="sqrt",
            class_weight="balanced",
            random_state=RANDOM_SEED,
            n_jobs=-1,
        ),
        "RandomForest": RandomForestClassifier(
            n_estimators=400,
            max_depth=None,
            min_samples_split=2,
            min_samples_leaf=2,
            max_features="sqrt",
            class_weight="balanced",
            random_state=RANDOM_SEED,
            n_jobs=-1,
        ),
        "HistGradientBoosting": HistGradientBoostingClassifier(
            max_iter=400,
            learning_rate=0.05,
            max_depth=4,
            min_samples_leaf=4,
            l2_regularization=0.1,
            class_weight="balanced",
            random_state=RANDOM_SEED,
        ),
        "GradientBoosting": GradientBoostingClassifier(
            n_estimators=300,
            learning_rate=0.05,
            max_depth=3,
            min_samples_split=4,
            min_samples_leaf=2,
            subsample=0.8,
            random_state=RANDOM_SEED,
        ),
        "LogisticRegression": LogisticRegression(
            C=1.0,
            max_iter=2000,
            class_weight="balanced",
            solver="lbfgs",
            random_state=RANDOM_SEED,
        ),
        "SVM": SVC(
            C=1.0,
            kernel="rbf",
            class_weight="balanced",
            probability=True,
            random_state=RANDOM_SEED,
        ),
    }


# =====================================================
# PHASE 3E + 3F: CROSS-VALIDATION & COMPARISON
# =====================================================

def evaluate_all_models(
    X_scaled: np.ndarray,
    y: np.ndarray,
    models: dict,
) -> pd.DataFrame:
    """
    Evaluates all candidate models using Repeated Stratified K-Fold CV.
    Reports accuracy, balanced accuracy, and F1 weighted with variance.
    """
    print("\n[Phase 3E/3F] Model comparison via Repeated Stratified K-Fold CV...")

    rskf = RepeatedStratifiedKFold(n_splits=5, n_repeats=3, random_state=RANDOM_SEED)
    skf = StratifiedKFold(n_splits=5, shuffle=True, random_state=RANDOM_SEED)

    results = []

    for name, model in models.items():
        print(f"  Evaluating: {name}...")

        bal_acc = cross_val_score(
            model, X_scaled, y, cv=rskf, scoring="balanced_accuracy", n_jobs=-1
        )
        f1_w = cross_val_score(
            model, X_scaled, y, cv=rskf, scoring="f1_weighted", n_jobs=-1
        )

        results.append({
            "model": name,
            "cv_bal_acc_mean": round(float(bal_acc.mean()), 4),
            "cv_bal_acc_std": round(float(bal_acc.std()), 4),
            "cv_f1_weighted_mean": round(float(f1_w.mean()), 4),
            "cv_f1_weighted_std": round(float(f1_w.std()), 4),
            "cv_stability_score": round(float(1.0 - bal_acc.std()), 4),
        })

        print(
            f"    BalAcc: {bal_acc.mean():.4f} ± {bal_acc.std():.4f}  "
            f"| F1w: {f1_w.mean():.4f} ± {f1_w.std():.4f}"
        )

    df_results = pd.DataFrame(results).sort_values(
        "cv_bal_acc_mean", ascending=False
    ).reset_index(drop=True)

    df_results.to_csv(REPORTS_DIR / "model_comparison.csv", index=False)
    print(f"\n  Model comparison saved -> {REPORTS_DIR}/model_comparison.csv")
    return df_results


# =====================================================
# PHASE 3K: CLINICAL MODEL SELECTION LOGIC
# =====================================================

def select_best_model(comparison_df: pd.DataFrame, models: dict) -> tuple[str, object]:
    """
    Selects the best model based on a clinical suitability composite score:
    - Weighted balanced accuracy (40%)
    - Low variance / stability (40%)
    - F1 weighted (20%)

    Prioritizes stability over raw accuracy for clinical deployment.
    """
    df = comparison_df.copy()
    df["selection_score"] = (
        0.40 * df["cv_bal_acc_mean"] +
        0.40 * df["cv_stability_score"] +
        0.20 * df["cv_f1_weighted_mean"]
    )

    best_row = df.sort_values("selection_score", ascending=False).iloc[0]
    best_name = best_row["model"]
    print(f"\n[Phase 3K] Clinical Model Selection:")
    print(f"  Selected: {best_name}")
    print(f"  Selection Score: {best_row['selection_score']:.4f}")
    print(f"  Reasoning: Balanced accuracy + stability composite favours {best_name}")
    return best_name, models[best_name]


# =====================================================
# PHASE 3G: HELD-OUT EVALUATION
# =====================================================

def evaluate_on_test_set(
    model,
    X_train_s: np.ndarray,
    X_test_s: np.ndarray,
    y_train: np.ndarray,
    y_test: np.ndarray,
) -> dict:
    """Trains and evaluates the final model on the held-out test set."""
    model.fit(X_train_s, y_train)
    y_pred = model.predict(X_test_s)
    y_proba = model.predict_proba(X_test_s) if hasattr(model, "predict_proba") else None

    acc = float(accuracy_score(y_test, y_pred))
    bal_acc = float(balanced_accuracy_score(y_test, y_pred))
    f1_w = float(f1_score(y_test, y_pred, average="weighted", zero_division=0))

    report = classification_report(
        y_test, y_pred,
        target_names=[LABEL_NAMES[i] for i in sorted(LABEL_NAMES)],
        digits=4, zero_division=0,
    )

    roc_auc = None
    brier = None
    if y_proba is not None:
        lb = LabelBinarizer()
        y_test_bin = lb.fit_transform(y_test)
        if y_test_bin.shape[1] == 1:
            y_test_bin = np.hstack([1 - y_test_bin, y_test_bin])
        try:
            roc_auc = float(roc_auc_score(y_test_bin, y_proba, multi_class="ovr", average="macro"))
        except Exception:
            roc_auc = None
        y_pred_proba_max = np.max(y_proba, axis=1)
        # Brier score for multi-class: mean over per-class binary Brier
        brier_scores = []
        for k in range(y_proba.shape[1]):
            y_k = (y_test == k).astype(int)
            brier_scores.append(brier_score_loss(y_k, y_proba[:, k]))
        brier = float(np.mean(brier_scores))

    metrics = {
        "test_accuracy": round(acc, 4),
        "test_balanced_accuracy": round(bal_acc, 4),
        "test_f1_weighted": round(f1_w, 4),
        "test_roc_auc_macro": round(roc_auc, 4) if roc_auc else None,
        "test_brier_score_mean": round(brier, 4) if brier else None,
        "y_pred": y_pred,
        "y_proba": y_proba,
        "classification_report": report,
    }

    print(f"\n[Phase 3G] Held-out Test Set Evaluation:")
    print(f"  Accuracy:          {acc:.4f}")
    print(f"  Balanced Accuracy: {bal_acc:.4f}")
    print(f"  F1 Weighted:       {f1_w:.4f}")
    if roc_auc:
        print(f"  ROC-AUC (macro):   {roc_auc:.4f}")
    if brier:
        print(f"  Brier Score (mean):{brier:.4f}")
    print(f"\n  Classification Report:\n{report}")

    return metrics


# =====================================================
# PHASE 3H: EXPLAINABILITY
# =====================================================

def compute_feature_importance(
    model,
    X_test_s: np.ndarray,
    y_test: np.ndarray,
    base_model,
) -> None:
    """Computes tree-based importance + permutation importance and saves plots."""
    print("\n[Phase 3H] Feature Explainability...")

    importance_data = {}

    # Tree-based importance from the raw estimator
    raw_model = base_model
    if hasattr(raw_model, "feature_importances_"):
        importance_data["tree_importance"] = dict(zip(
            FEATURE_COLUMNS,
            [round(float(v), 4) for v in raw_model.feature_importances_]
        ))
        print(f"  Tree Feature Importances: {importance_data['tree_importance']}")

    # Permutation importance on test set
    try:
        perm = permutation_importance(
            model, X_test_s, y_test,
            n_repeats=20, random_state=RANDOM_SEED, n_jobs=-1
        )
        importance_data["permutation_importance"] = dict(zip(
            FEATURE_COLUMNS,
            [round(float(v), 4) for v in perm.importances_mean]
        ))
        print(f"  Permutation Importances: {importance_data['permutation_importance']}")
    except Exception as e:
        print(f"  [WARN] Permutation importance failed: {e}")

    # Save
    with open(REPORTS_DIR / "feature_importance.json", "w") as f:
        json.dump(importance_data, f, indent=2)

    # Plot tree importance
    if "tree_importance" in importance_data:
        imp_series = pd.Series(importance_data["tree_importance"]).sort_values(ascending=True)
        plt.figure(figsize=(8, 5))
        imp_series.plot(kind="barh", color="steelblue")
        plt.title("Clinical Feature Importance (Tree-Based)")
        plt.xlabel("Importance Score")
        plt.tight_layout()
        plt.savefig(REPORTS_DIR / "feature_importance.png", dpi=120)
        plt.close()

    # Plot permutation importance
    if "permutation_importance" in importance_data:
        perm_series = pd.Series(importance_data["permutation_importance"]).sort_values(ascending=True)
        plt.figure(figsize=(8, 5))
        perm_series.plot(kind="barh", color="darkorange")
        plt.title("Clinical Feature Importance (Permutation-Based)")
        plt.xlabel("Mean Accuracy Decrease")
        plt.tight_layout()
        plt.savefig(REPORTS_DIR / "permutation_importance.png", dpi=120)
        plt.close()


# =====================================================
# PHASE 3I: PROBABILITY CALIBRATION
# =====================================================

def calibrate_model(
    best_model,
    X_train_s: np.ndarray,
    y_train: np.ndarray,
) -> CalibratedClassifierCV:
    """
    Calibrates the best model using Platt scaling (sigmoid).
    Uses 5-fold CV during calibration to avoid overfitting on small datasets.
    """
    print("\n[Phase 3I] Probability Calibration (Platt Scaling)...")

    calibrated = CalibratedClassifierCV(
        best_model,
        method="sigmoid",
        cv=5,
    )
    calibrated.fit(X_train_s, y_train)
    print("  Calibration complete.")
    return calibrated


# =====================================================
# PLOTS: CONFUSION MATRIX + CALIBRATION CURVE
# =====================================================

def save_confusion_matrix(y_test, y_pred, label_names: dict) -> None:
    cm = confusion_matrix(y_test, y_pred)
    plt.figure(figsize=(7, 6))
    sns.heatmap(
        cm, annot=True, fmt="d", cmap="Blues",
        xticklabels=label_names.values(),
        yticklabels=label_names.values(),
    )
    plt.xlabel("Predicted")
    plt.ylabel("Actual")
    plt.title("Smile AI – Confusion Matrix")
    plt.tight_layout()
    plt.savefig(REPORTS_DIR / "confusion_matrix.png", dpi=120)
    plt.close()


# =====================================================
# PHASE 3M: TRAINING REPORT
# =====================================================

def save_training_report(
    best_name: str,
    comparison_df: pd.DataFrame,
    metrics: dict,
    audit: dict,
    metadata: dict,
) -> None:
    report_path = REPORTS_DIR / "training_report.txt"
    with open(report_path, "w") as f:
        f.write("SMILE AI – PHASE 3 ML TRAINING REPORT\n")
        f.write("=" * 60 + "\n\n")
        f.write(f"Training Date: {metadata['training_date']}\n")
        f.write(f"Random Seed: {RANDOM_SEED}\n")
        f.write(f"Selected Model: {best_name}\n\n")

        f.write("DATASET STATISTICS\n")
        f.write("-" * 40 + "\n")
        f.write(f"Total samples: {audit['n_samples']}\n")
        f.write(f"Class distribution: {audit['label_distribution']}\n")
        f.write(f"Duplicate rows: {audit['duplicate_rows']}\n")
        f.write(f"High correlation pairs: {audit['high_correlation_pairs']}\n")
        f.write(f"Low variance features: {audit['low_variance_features']}\n")
        for w in audit["warnings"]:
            f.write(f"  AUDIT WARNING: {w}\n")

        f.write("\nMODEL COMPARISON (CV – Repeated Stratified 5-Fold x3)\n")
        f.write("-" * 40 + "\n")
        f.write(comparison_df.to_string(index=False))
        f.write("\n\n")

        f.write("TEST SET EVALUATION\n")
        f.write("-" * 40 + "\n")
        f.write(f"Test Accuracy: {metrics['test_accuracy']}\n")
        f.write(f"Balanced Accuracy: {metrics['test_balanced_accuracy']}\n")
        f.write(f"F1 Weighted: {metrics['test_f1_weighted']}\n")
        if metrics.get("test_roc_auc_macro"):
            f.write(f"ROC-AUC Macro: {metrics['test_roc_auc_macro']}\n")
        if metrics.get("test_brier_score_mean"):
            f.write(f"Brier Score (mean): {metrics['test_brier_score_mean']}\n")
        f.write(f"\nClassification Report:\n{metrics['classification_report']}\n")

        f.write("FEATURE ORDER (inference)\n")
        f.write("-" * 40 + "\n")
        for i, feat in enumerate(FEATURE_COLUMNS):
            f.write(f"  [{i}] {feat}\n")

        f.write("\nCLINICAL LIMITATIONS\n")
        f.write("-" * 40 + "\n")
        f.write("- Dataset size (~110 samples) limits absolute accuracy ceiling.\n")
        f.write("- Class imbalance (Moderate class underrepresented).\n")
        f.write("- Features derived from soft-tissue landmarks; not equivalent to clinical radiographs.\n")
        f.write("- Model is a decision-support tool; does not replace clinical examination.\n")

    print(f"\n  Training report saved -> {report_path}")


# =====================================================
# MAIN PIPELINE
# =====================================================

def main():
    print("\n======================================")
    print("SMILE AI PHASE 3 – ML TRAINING PIPELINE")
    print("======================================")

    # --------------------------------------------------
    # Phase 3B: Attempt feature regeneration
    # --------------------------------------------------
    regen_df = regenerate_features_from_raw()
    use_regen = regen_df is not None and len(regen_df) >= 30

    if use_regen:
        df = regen_df
        print(f"\n  Using REGENERATED features ({len(df)} samples).")
    else:
        print(f"\n  Regeneration insufficient. Falling back to labeled CSV: {LABELS_CSV}")
        print("  [DRIFT WARNING] Legacy features have face_ratio in 0.78-0.94 range.")
        print("  [DRIFT WARNING] smile_width <-> buccal_corridor correlation = -1.0 (multicollinearity).")
        df = pd.read_csv(LABELS_CSV)
        df["clinical_label"] = df["clinical_label"].astype(int)
        df = df.dropna(subset=FEATURE_COLUMNS)

    # --------------------------------------------------
    # Phase 3A + 3C: Audit and preparation
    # --------------------------------------------------
    df, audit = audit_and_prepare_dataset(df)

    X = df[FEATURE_COLUMNS].values.astype(np.float32)
    y = df["clinical_label"].values.astype(int)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, stratify=y, test_size=0.20, random_state=RANDOM_SEED
    )

    scaler = StandardScaler()
    X_train_s = scaler.fit_transform(X_train)
    X_test_s = scaler.transform(X_test)
    joblib.dump(scaler, SCALER_PATH)
    print(f"\n  Scaler saved -> {SCALER_PATH}")

    # --------------------------------------------------
    # SMOTE: Synthetic Minority Oversampling for Moderate class
    # Applied AFTER scaling to avoid data leakage, BEFORE CV.
    # SMOTE generates synthetic samples using k-nearest neighbours
    # in feature space. Justified here because the Moderate class
    # has only ~10 training samples — too few for any tree model
    # to learn discriminative boundaries.
    # Reference: Chawla et al. (2002), J Artificial Intelligence Research.
    # --------------------------------------------------
    smote_used = False
    print("\n[Phase 3J] Class Balancing via SMOTE...")
    label_counts = dict(zip(*np.unique(y_train, return_counts=True)))
    print(f"  Training distribution before SMOTE: {label_counts}")

    if _SMOTE_AVAILABLE:
        min_class_count = min(label_counts.values())
        if min_class_count < 6:
            k_neighbors = min_class_count - 1
        else:
            k_neighbors = 5

        try:
            smote = SMOTE(
                sampling_strategy="minority",
                k_neighbors=k_neighbors,
                random_state=RANDOM_SEED,
            )
            X_train_s, y_train = smote.fit_resample(X_train_s, y_train)
            smote_used = True
            new_counts = dict(zip(*np.unique(y_train, return_counts=True)))
            print(f"  Training distribution after SMOTE:  {new_counts}")
            print(f"  SMOTE k_neighbors={k_neighbors}")
        except Exception as e:
            print(f"  [WARN] SMOTE failed: {e}. Continuing without oversampling.")
    else:
        print("  [WARN] imbalanced-learn not installed. Skipping SMOTE.")
        print("  Relying on class_weight='balanced' in models.")

    audit["smote_used"] = smote_used
    audit["smote_training_size"] = int(len(y_train))

    # --------------------------------------------------
    # Phase 3D + 3E + 3F: Model search and CV comparison
    # --------------------------------------------------
    models = build_model_candidates()
    comparison_df = evaluate_all_models(X_train_s, y_train, models)

    # --------------------------------------------------
    # Phase 3K: Clinical model selection
    # --------------------------------------------------
    best_name, best_model = select_best_model(comparison_df, models)

    # --------------------------------------------------
    # Phase 3I: Probability calibration
    # --------------------------------------------------
    calibrated_model = calibrate_model(best_model, X_train_s, y_train)

    # --------------------------------------------------
    # Phase 3G: Held-out test evaluation
    # --------------------------------------------------
    test_metrics = evaluate_on_test_set(
        calibrated_model, X_train_s, X_test_s, y_train, y_test
    )

    # --------------------------------------------------
    # Phase 3H: Explainability
    # --------------------------------------------------
    raw_estimator = best_model
    compute_feature_importance(
        calibrated_model, X_test_s, y_test, raw_estimator
    )

    # --------------------------------------------------
    # Confusion Matrix
    # --------------------------------------------------
    save_confusion_matrix(y_test, test_metrics["y_pred"], LABEL_NAMES)
    print(f"  Confusion matrix saved -> {REPORTS_DIR}/confusion_matrix.png")

    # --------------------------------------------------
    # Save final model
    # --------------------------------------------------
    joblib.dump(calibrated_model, MODEL_PATH)
    print(f"  Final model saved -> {MODEL_PATH}")

    # --------------------------------------------------
    # Metadata
    # --------------------------------------------------
    confidence_scores = (
        np.max(test_metrics["y_proba"], axis=1)
        if test_metrics["y_proba"] is not None
        else np.array([0.0])
    )
    now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    metadata = {
        "training_date": now_str,
        "random_seed": RANDOM_SEED,
        "model_name": best_name,
        "model_version": "3.1",
        "feature_source": "regenerated_v2" if use_regen else "legacy_labeled_csv",
        "feature_columns": FEATURE_COLUMNS,
        "label_names": LABEL_NAMES,
        "n_original_training_samples": int(len(X_train)),
        "n_training_samples_after_smote": int(len(y_train)),
        "n_test_samples": int(len(y_test)),
        "smote_applied": smote_used,
        "class_balancing_method": "SMOTE (Chawla et al. 2002) + class_weight=balanced" if smote_used else "class_weight=balanced only",
        "cv_metric": "balanced_accuracy (Repeated Stratified 5-Fold x3)",
        "test_accuracy": test_metrics["test_accuracy"],
        "test_balanced_accuracy": test_metrics["test_balanced_accuracy"],
        "test_f1_weighted": test_metrics["test_f1_weighted"],
        "test_roc_auc_macro": test_metrics.get("test_roc_auc_macro"),
        "test_brier_score_mean": test_metrics.get("test_brier_score_mean"),
        "average_test_confidence": round(float(np.mean(confidence_scores)), 4),
        "calibration_method": "Platt Scaling (sigmoid, 5-fold CV)",
        "clinical_notes": (
            "Model is a clinical decision-support component. "
            "Predictions must be reviewed by qualified orthodontic clinicians."
        ),
    }

    with open(META_PATH, "w") as f:
        json.dump(metadata, f, indent=2)
    print(f"  Metadata saved -> {META_PATH}")

    # --------------------------------------------------
    # Phase 3M: Training report
    # --------------------------------------------------
    save_training_report(best_name, comparison_df, test_metrics, audit, metadata)

    print("\n======================================")
    print("PHASE 3 TRAINING COMPLETED SUCCESSFULLY")
    print(f"Model: {best_name}")
    print(f"Balanced Accuracy (test): {test_metrics['test_balanced_accuracy']:.4f}")
    print(f"F1 Weighted (test): {test_metrics['test_f1_weighted']:.4f}")
    print("======================================\n")


if __name__ == "__main__":
    main()