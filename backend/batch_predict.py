import os
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

SCALER_PATH = "models/scaler.pkl"

IMAGE_FOLDER = "raw_dataset/doctor_images"

OUTPUT_CSV = "reports/doctor_predictions.csv"

OUTPUT_JSON = "reports/doctor_predictions.json"


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
    "buccal_corridor"
]

# =====================================================
# CREATE REPORTS FOLDER
# =====================================================

os.makedirs("reports", exist_ok=True)

# =====================================================
# LOAD MODEL
# =====================================================

print("\nLoading Smile AI model...")

model = joblib.load(MODEL_PATH)

scaler = joblib.load(SCALER_PATH)

mesh_detector = FaceMesh3D()

# =====================================================
# RESULTS
# =====================================================

results = []


# =====================================================
# PROCESS IMAGES
# =====================================================

image_files = os.listdir(IMAGE_FOLDER)

valid_extensions = (
    ".jpg",
    ".jpeg",
    ".png",
    ".JPG",
    ".JPEG",
    ".PNG"
)

total_images = 0
successful_predictions = 0
failed_predictions = 0


# =====================================================
# LOOP
# =====================================================

for filename in image_files:

    if not filename.endswith(valid_extensions):
        continue

    total_images += 1

    image_path = os.path.join(
        IMAGE_FOLDER,
        filename
    )

    print("\n====================================")
    print(f"Processing: {filename}")
    print("====================================")

    try:

        # -----------------------------------------
        # LOAD IMAGE
        # -----------------------------------------

        image = cv2.imread(image_path)

        if image is None:

            raise Exception("Failed to load image")

        # -----------------------------------------
        # FACE DETECTION
        # -----------------------------------------

        result = mesh_detector.process_image(
            image_path
        )

        if result is None:

            raise Exception("No face detected")

        landmarks = result["landmarks"]

        # -----------------------------------------
        # FEATURE EXTRACTION
        # -----------------------------------------

        extractor = FeatureExtractor(landmarks)

        features = extractor.extract_all_features()

        # -----------------------------------------
        # QUALITY CHECK
        # -----------------------------------------

        quality_score = features.get(
            "quality_score",
            0
        )

        if quality_score < 0.55:

            raise Exception(
                "Low quality image"
            )

        # -----------------------------------------
        # VALIDATE FEATURES
        # -----------------------------------------

        for key, value in features.items():

            if value is None:

                raise Exception(
                    f"Invalid feature: {key}"
                )

            if isinstance(value, float):

                if np.isnan(value):

                    raise Exception(
                        f"NaN detected: {key}"
                    )

        # -----------------------------------------
        # PREPARE DATA
        # -----------------------------------------

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

        # -----------------------------------------
        # SCALE FEATURES
        # -----------------------------------------

        input_scaled = scaler.transform(
            input_data
        )

        # -----------------------------------------
        # PREDICTION
        # -----------------------------------------

        prediction = model.predict(
            input_scaled
        )[0]

        probabilities = model.predict_proba(
            input_scaled
        )[0]

        confidence = float(
            np.max(probabilities)
        )

        severity = LABELS[prediction]

        # -----------------------------------------
        # PROBABILITY REPORT
        # -----------------------------------------

        probability_report = {}

        for idx, prob in enumerate(
            probabilities
        ):

            probability_report[
                LABELS[idx]
            ] = round(float(prob * 100), 2)

        # -----------------------------------------
        # CLINICAL FINDINGS
        # -----------------------------------------

        findings = []

        if features["midline_deviation"] > 0.03:

            findings.append(
                "Midline deviation elevated"
            )

        if features["smile_symmetry"] > 0.03:

            findings.append(
                "Smile asymmetry observed"
            )

        if features["gingival_display"] > 0.03:

            findings.append(
                "Gingival display increased"
            )

        if len(findings) == 0:

            findings.append(
                "Smile proportions balanced"
            )

        # -----------------------------------------
        # SAVE RESULT
        # -----------------------------------------

        row = {

            "image":
                filename,

            "severity":
                severity,

            "confidence":
                round(confidence, 4),

            "quality_score":
                round(float(quality_score), 4),

            "midline_deviation":
                round(
                    float(
                        features[
                            "midline_deviation"
                        ]
                    ),
                    4
                ),

            "smile_symmetry":
                round(
                    float(
                        features[
                            "smile_symmetry"
                        ]
                    ),
                    4
                ),

            "gingival_display":
                round(
                    float(
                        features[
                            "gingival_display"
                        ]
                    ),
                    4
                ),

            "clinical_findings":
                "; ".join(findings),

            "probabilities":
                json.dumps(
                    probability_report
                )
        }

        results.append(row)

        successful_predictions += 1

        print(f"\nPrediction: {severity}")

        print(
            f"Confidence: "
            f"{confidence * 100:.2f}%"
        )

    except Exception as e:

        failed_predictions += 1

        print(f"\nFAILED: {filename}")

        print(f"Reason: {e}")


# =====================================================
# SAVE CSV
# =====================================================

results_df = pd.DataFrame(results)

results_df.to_csv(
    OUTPUT_CSV,
    index=False
)

# =====================================================
# SAVE JSON
# =====================================================

json_output = {

    "timestamp":
        datetime.now().strftime(
            "%Y-%m-%d %H:%M:%S"
        ),

    "total_images":
        total_images,

    "successful_predictions":
        successful_predictions,

    "failed_predictions":
        failed_predictions,

    "results":
        results
}

with open(OUTPUT_JSON, "w") as f:

    json.dump(
        json_output,
        f,
        indent=4
    )


# =====================================================
# FINAL REPORT
# =====================================================

print("\n====================================")
print("BATCH PREDICTION COMPLETED")
print("====================================")

print(f"\nTotal Images: {total_images}")

print(
    f"Successful Predictions: "
    f"{successful_predictions}"
)

print(
    f"Failed Predictions: "
    f"{failed_predictions}"
)

print(f"\nCSV Saved: {OUTPUT_CSV}")

print(f"JSON Saved: {OUTPUT_JSON}")