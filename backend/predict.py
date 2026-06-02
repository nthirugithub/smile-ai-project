import os
import sys
import json
import cv2
import joblib
import numpy as np
import pandas as pd

from datetime import datetime

from ai_engine.face_mesh_3d import FaceMesh3D
from ai_engine.feature_extractor import FeatureExtractor


# =====================================================
# PATHS
# =====================================================

MODEL_PATH = "models/smile_ai_model.pkl"

REPORT_PATH = "reports/prediction_report.json"

DEBUG_IMAGE_PATH = "reports/debug_output.jpg"

RESULT_IMAGE_PATH = "reports/result_output.jpg"

SCALER_PATH = "models/scaler.pkl"


# =====================================================
# LABELS
# =====================================================

LABELS = {
    0: "Normal",
    1: "Mild",
    2: "Moderate",
    3: "Severe"
}


# =====================================================
# REQUIRED FEATURES
# =====================================================

FEATURE_COLUMNS = [
    "smile_width",
    "lip_opening",
    "face_ratio",
    "midline_deviation",
    "smile_symmetry",
    "smile_arc",
    "gingival_display",
    "buccal_corridor"
]


# =====================================================
# CREATE REPORTS FOLDER
# =====================================================

os.makedirs("reports", exist_ok=True)


# =====================================================
# VALIDATE INPUT
# =====================================================

if len(sys.argv) < 2:

    print("\nUsage:")
    print("python predict.py image.jpg")

    sys.exit()


image_path = sys.argv[1]

if not os.path.exists(image_path):

    print(f"\nImage not found: {image_path}")

    sys.exit()


# =====================================================
# LOAD MODEL + SCALER
# =====================================================

print("\nLoading Smile AI model...")

model = joblib.load(MODEL_PATH)

scaler = joblib.load(SCALER_PATH)


# =====================================================
# LOAD IMAGE
# =====================================================

image = cv2.imread(image_path)

if image is None:

    print("\nFailed to load image.")

    sys.exit()


# =====================================================
# FACE MESH DETECTION
# =====================================================

print("\nRunning facial landmark detection...")

mesh_detector = FaceMesh3D()

result = mesh_detector.process_image(image_path)

if result is None:

    print("\nNo face detected.")

    sys.exit()


landmarks = result["landmarks"]


# =====================================================
# FEATURE EXTRACTION
# =====================================================

print("\nExtracting smile features...")

extractor = FeatureExtractor(landmarks)

features = extractor.extract_all_features()


# =====================================================
# FEATURE VALIDATION
# =====================================================

for key, value in features.items():

    if value is None:

        print(f"\nInvalid feature detected: {key}")

        sys.exit()

    if isinstance(value, float):

        if np.isnan(value):

            print(f"\nNaN detected in feature: {key}")

            sys.exit()


# =====================================================
# QUALITY CHECK
# =====================================================

quality_score = features.get("quality_score", 0)

if quality_score < 0.55:

    print("\n=================================")
    print("IMAGE QUALITY TOO LOW")
    print("=================================")

    print(
        "\nPlease upload a:"
        "\n- Front-facing face"
        "\n- Well-lit image"
        "\n- Clear smiling image"
    )

    sys.exit()


# =====================================================
# GEOMETRY VALIDATION
# =====================================================

if (
    features["face_ratio"] < 0.4
    or features["face_ratio"] > 1.8
):

    print("\nInvalid facial geometry detected.")

    sys.exit()


# =====================================================
# DEBUG OVERLAY
# =====================================================

debug_image = extractor.draw_debug_overlay(image.copy())

cv2.imwrite(DEBUG_IMAGE_PATH, debug_image)

print(f"\nDebug overlay saved: {DEBUG_IMAGE_PATH}")


# =====================================================
# PREPARE INPUT
# =====================================================

input_data = pd.DataFrame([[
    features["smile_width"],
    features["lip_opening"],
    features["face_ratio"],
    features["midline_deviation"],
    features["smile_symmetry"],
    features["smile_arc"],
    features["gingival_display"],
    features["buccal_corridor"]
]], columns=FEATURE_COLUMNS)


# =====================================================
# SCALE INPUT
# =====================================================

input_scaled = scaler.transform(input_data)


# =====================================================
# PREDICTION
# =====================================================

prediction = model.predict(input_scaled)[0]

probabilities = model.predict_proba(input_scaled)[0]

confidence = float(np.max(probabilities))

severity = LABELS[prediction]


# =====================================================
# PROBABILITY BREAKDOWN
# =====================================================

probability_report = {}

for idx, prob in enumerate(probabilities):

    probability_report[LABELS[idx]] = round(
        float(prob * 100),
        2
    )


# =====================================================
# CLINICAL EXPLANATION
# =====================================================

clinical_findings = []

if features["midline_deviation"] > 0.03:

    clinical_findings.append(
        "Elevated midline deviation detected"
    )

if features["smile_symmetry"] > 0.03:

    clinical_findings.append(
        "Smile asymmetry observed"
    )

if features["gingival_display"] > 0.03:

    clinical_findings.append(
        "Increased gingival display observed"
    )

if features["buccal_corridor"] < 0.45:

    clinical_findings.append(
        "Reduced smile width / buccal corridor imbalance"
    )

if len(clinical_findings) == 0:

    clinical_findings.append(
        "Smile proportions appear balanced"
    )


# =====================================================
# RECOMMENDATION ENGINE
# =====================================================

if severity == "Normal":

    recommendation = (
        "Smile aesthetics within acceptable range."
    )

elif severity == "Mild":

    recommendation = (
        "Mild orthodontic consultation recommended."
    )

elif severity == "Moderate":

    recommendation = (
        "Orthodontic evaluation advised for smile correction."
    )

else:

    recommendation = (
        "Comprehensive orthodontic treatment planning recommended."
    )


# =====================================================
# DRAW RESULT ON IMAGE
# =====================================================

cv2.putText(
    debug_image,
    f"Severity: {severity}",
    (20, 40),
    cv2.FONT_HERSHEY_SIMPLEX,
    1,
    (0, 255, 0),
    2
)

cv2.putText(
    debug_image,
    f"Confidence: {confidence * 100:.1f}%",
    (20, 80),
    cv2.FONT_HERSHEY_SIMPLEX,
    0.8,
    (255, 255, 0),
    2
)

cv2.imwrite(RESULT_IMAGE_PATH, debug_image)

print(f"\nResult image saved: {RESULT_IMAGE_PATH}")


# =====================================================
# TERMINAL OUTPUT
# =====================================================

print("\n====================================")
print("AI SMILE ANALYSIS RESULT")
print("====================================")

print(f"\nPredicted Severity: {severity}")

print(f"Confidence Score: {confidence * 100:.2f}%")

print(f"Quality Score: {quality_score:.3f}")


# =====================================================
# FEATURE OUTPUT
# =====================================================

print("\nExtracted Features:")

for key, value in features.items():

    print(f"{key}: {round(value, 4)}")


# =====================================================
# PROBABILITY OUTPUT
# =====================================================

print("\nProbability Breakdown:")

for label, prob in probability_report.items():

    print(f"{label}: {prob}%")


# =====================================================
# CLINICAL FINDINGS
# =====================================================

print("\nClinical Findings:")

for finding in clinical_findings:

    print(f"- {finding}")


# =====================================================
# RECOMMENDATION
# =====================================================

print("\nTreatment Recommendation:")

print(f"- {recommendation}")


# =====================================================
# SAVE JSON REPORT
# =====================================================

report_data = {

    "timestamp":
        datetime.now().strftime("%Y-%m-%d %H:%M:%S"),

    "image_path":
        image_path,

    "severity":
        severity,

    "confidence":
        round(confidence, 4),

    "quality_score":
        round(float(quality_score), 4),

    "features":
        {
            k: round(float(v), 4)
            for k, v in features.items()
        },

    "probabilities":
        probability_report,

    "clinical_findings":
        clinical_findings,

    "recommendation":
        recommendation
}

with open(REPORT_PATH, "w") as f:

    json.dump(report_data, f, indent=4)


print("\n====================================")
print("REPORT GENERATED SUCCESSFULLY")
print("====================================")

print(f"\nJSON Report: {REPORT_PATH}")

print(f"Debug Image: {DEBUG_IMAGE_PATH}")

print(f"Result Image: {RESULT_IMAGE_PATH}")