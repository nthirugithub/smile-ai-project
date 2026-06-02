from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

import base64
import os
import traceback
import uuid

import cv2
import joblib
import numpy as np
import pandas as pd
from flask import Flask, jsonify, request
from flask_cors import CORS

from ai_engine.face_mesh_3d import FaceMesh3D
from ai_engine.feature_extractor import FeatureExtractor
from ai_engine.severity_classifier import SeverityClassifier
from ai_engine.treatment_engine import TreatmentEngine


# =====================================================
# INIT APP
# =====================================================

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///smile_analysis.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)
class SmileReport(db.Model):

    id = db.Column(
        db.Integer,
        primary_key=True
    )

    patient_name = db.Column(
        db.String(100)
    )

    smile_symmetry = db.Column(
        db.Float
    )

    smile_width = db.Column(
        db.Float
    )

    smile_arc = db.Column(
        db.Float
    )

    midline_deviation = db.Column(
        db.Float
    )

    lip_opening = db.Column(
        db.Float
    )

    gingival_display = db.Column(
        db.Float
    )

    buccal_corridor = db.Column(
        db.Float
    )

    face_ratio = db.Column(
        db.Float
    )

    severity = db.Column(
        db.String(50)
    )

    confidence = db.Column(
        db.Float
    )

    treatment_priority = db.Column(
        db.String(50)
    )

    overlay_image = db.Column(
        db.Text
    )

    created_at = db.Column(
        db.DateTime,
        default=datetime.utcnow
    )

CORS(app)


# =====================================================
# PATHS
# =====================================================

MODEL_PATH = "models/smile_ai_model.pkl"
SCALER_PATH = "models/scaler.pkl"
UPLOAD_FOLDER = "uploads"
REPORT_FOLDER = "reports"

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(REPORT_FOLDER, exist_ok=True)


# =====================================================
# LOAD MODEL
# =====================================================

print("\nLoading Smile AI Backend...")

if not os.path.exists(MODEL_PATH):
    raise FileNotFoundError(f"Missing model file: {MODEL_PATH}")

if not os.path.exists(SCALER_PATH):
    raise FileNotFoundError(f"Missing scaler file: {SCALER_PATH}")

model = joblib.load(MODEL_PATH)
scaler = joblib.load(SCALER_PATH)
mesh_detector = FaceMesh3D()

print("Backend Ready.")


# =====================================================
# LABELS
# =====================================================

LABELS = {
    0: "Normal",
    1: "Mild",
    2: "Moderate",
    3: "Severe",
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
    "buccal_corridor",
]


# =====================================================
# VALID EXTENSIONS
# =====================================================

VALID_EXTENSIONS = {".jpg", ".jpeg", ".png"}


# =====================================================
# HELPERS
# =====================================================

def is_valid_extension(filename: str) -> bool:
    ext = os.path.splitext(filename.lower())[1]
    return ext in VALID_EXTENSIONS


def safe_point_xy(point, image_width: int, image_height: int):
    """
    Supports:
    - MediaPipe-like landmark objects with .x and .y
    - tuples/lists in normalized form (0..1)
    - tuples/lists in pixel form
    """
    if hasattr(point, "x") and hasattr(point, "y"):
        px = float(point.x)
        py = float(point.y)
    elif isinstance(point, (list, tuple)) and len(point) >= 2:
        px = float(point[0])
        py = float(point[1])
    else:
        raise TypeError(f"Unsupported point type: {type(point)}")

    # If normalized coordinates, convert to pixels.
    # Otherwise assume pixel coordinates.
    if 0.0 <= px <= 1.5 and 0.0 <= py <= 1.5:
        x = int(px * image_width)
        y = int(py * image_height)
    else:
        x = int(px)
        y = int(py)

    return x, y


def normalize_treatment_output(output, severity: str):
    """
    Makes the treatment engine output safe even if it returns
    dict, list, or something unexpected.
    """
    if isinstance(output, dict):
        return (
            output.get("clinical_findings", []),
            output.get("recommendations", []),
            output.get("treatment_priority", "Unknown"),
        )

    if isinstance(output, list):
        if severity == "Severe":
            priority = "High"
        elif severity == "Moderate":
            priority = "Medium"
        elif severity == "Mild":
            priority = "Low-Medium"
        else:
            priority = "Low"
        return [], output, priority

    return [], [], "Unknown"


def draw_smile_overlay(overlay_image, landmarks):
    """
    Draws a simple, visible smile overlay:
    - mouth landmark points
    - contour lines
    - center midline
    - title label
    """
    image_height, image_width = overlay_image.shape[:2]

    upper_lip = [
        61, 185, 40, 39, 37,
        0, 267, 269, 270, 409, 291
    ]

    lower_lip = [
        61, 146, 91, 181, 84,
        17, 314, 405, 321, 375, 291
    ]

    # ==============================
    # DRAW UPPER LIP
    # ==============================

    upper_points = []

    for idx in upper_lip:

        point = landmarks[idx]

        x, y = safe_point_xy(
            point,
            image_width,
            image_height
        )

        upper_points.append((x, y))

    for i in range(len(upper_points) - 1):

        cv2.line(
            overlay_image,
            upper_points[i],
            upper_points[i + 1],
            (0, 255, 0),
            3,
            lineType=cv2.LINE_AA,
        )

    # ==============================
    # DRAW LOWER LIP
    # ==============================

    lower_points = []

    for idx in lower_lip:

        point = landmarks[idx]

        x, y = safe_point_xy(
            point,
            image_width,
            image_height
        )

        lower_points.append((x, y))

    for i in range(len(lower_points) - 1):

        cv2.line(
            overlay_image,
            lower_points[i],
            lower_points[i + 1],
            (255, 0, 0),
            3,
            lineType=cv2.LINE_AA,
        )

    # ==============================
    # DRAW LANDMARK DOTS
    # ==============================

    for (x, y) in upper_points + lower_points:

        cv2.circle(
            overlay_image,
            (x, y),
            4,
            (0, 255, 255),
            -1,
            lineType=cv2.LINE_AA,
        )

        # Title
        cv2.putText(
            overlay_image,
            "Smile AI Analysis",
            (40, 60),
            cv2.FONT_HERSHEY_SIMPLEX,
            1.2,
            (255, 255, 255),
            3,
            lineType=cv2.LINE_AA,
        )


        # =====================================
        # PROFESSIONAL FACE MIDLINE
        # =====================================

        # Nose bridge landmark
        nose_top = landmarks[168]

        # Chin landmark
        chin = landmarks[152]

        nose_x, nose_y = safe_point_xy(
            nose_top,
            image_width,
            image_height
        )

        chin_x, chin_y = safe_point_xy(
            chin,
            image_width,
            image_height
        )

        # Average X for better symmetry line
        center_x = int((nose_x + chin_x) / 2)

        cv2.line(
            overlay_image,
            (center_x, nose_y - 40),
            (center_x, chin_y + 20),
            (0, 255, 255),
            2,
            lineType=cv2.LINE_AA,
        )

        return overlay_image


# =====================================================
# HOME
# =====================================================

@app.route("/")
def home():
    return jsonify({
        "success": True,
        "message": "Smile AI Backend Running",
        "version": "2.0",
    })


# =====================================================
# HEALTH
# =====================================================

@app.route("/health")
def health():
    return jsonify({
        "success": True,
        "status": "healthy",
    })


# =====================================================
# PREDICT
# =====================================================

@app.route("/predict", methods=["POST"])
def predict():
    upload_path = None

    try:
        # -------------------------------------------------
        # FILE CHECK
        # -------------------------------------------------
        if "image" not in request.files:
            return jsonify({
                "success": False,
                "error": "No image uploaded",
            }), 400

        image = request.files["image"]

        if image.filename == "":
            return jsonify({
                "success": False,
                "error": "Empty filename",
            }), 400

        # -------------------------------------------------
        # EXTENSION CHECK
        # -------------------------------------------------
        if not is_valid_extension(image.filename):
            return jsonify({
                "success": False,
                "error": "Unsupported file format",
            }), 400

        # -------------------------------------------------
        # SAVE IMAGE
        # -------------------------------------------------
        extension = os.path.splitext(image.filename)[1]
        unique_name = f"{uuid.uuid4()}{extension}"
        upload_path = os.path.join(UPLOAD_FOLDER, unique_name)
        image.save(upload_path)

        # -------------------------------------------------
        # FACE MESH DETECTION
        # -------------------------------------------------
        result = mesh_detector.process_image(upload_path)

        if result is None:
            return jsonify({
                "success": False,
                "error": "No face detected",
            }), 400

        landmarks = result["landmarks"]
        quality_score = float(result.get("quality_score", 0) or 0)
        head_tilt = float(result.get("head_tilt", 0) or 0)

        # -------------------------------------------------
        # QUALITY CHECK
        # -------------------------------------------------
        if quality_score < 0.35:
            return jsonify({
                "success": False,
                "error": "Image quality too low",
                "quality_score": quality_score,
            }), 400

        # -------------------------------------------------
        # LOAD IMAGE
        # -------------------------------------------------
        overlay_image = cv2.imread(upload_path)
        if overlay_image is None:
            return jsonify({
                "success": False,
                "error": "Failed to load image",
            }), 500

        # -------------------------------------------------
        # DRAW OVERLAY
        # -------------------------------------------------
        overlay_image = draw_smile_overlay(overlay_image, landmarks)

        # -------------------------------------------------
        # FEATURE EXTRACTION
        # -------------------------------------------------
        extractor = FeatureExtractor(landmarks)
        features = extractor.extract_all_features()

        # -------------------------------------------------
        # VALIDATE FEATURES
        # -------------------------------------------------
        for key, value in features.items():
            if value is None:
                return jsonify({
                    "success": False,
                    "error": f"Invalid feature: {key}",
                }), 400

            if isinstance(value, (float, np.floating)) and np.isnan(value):
                return jsonify({
                    "success": False,
                    "error": f"NaN in {key}",
                }), 400

        # -------------------------------------------------
        # PREPARE INPUT
        # -------------------------------------------------
        input_data = pd.DataFrame([[
            features["smile_width"],
            features["lip_opening"],
            features["face_ratio"],
            features["midline_deviation"],
            features["smile_symmetry"],
            features["smile_arc"],
            features["gingival_display"],
            features["buccal_corridor"],
        ]], columns=FEATURE_COLUMNS)

        # -------------------------------------------------
        # SCALE
        # -------------------------------------------------
        input_scaled = scaler.transform(input_data)

        # -------------------------------------------------
        # PREDICTION
        # -------------------------------------------------
        prediction = int(model.predict(input_scaled)[0])

        if hasattr(model, "predict_proba"):
            probabilities = model.predict_proba(input_scaled)[0]
        else:
            probabilities = np.zeros(len(LABELS), dtype=float)
            if prediction in LABELS:
                probabilities[prediction] = 1.0

        confidence = float(np.max(probabilities))
        severity = LABELS.get(prediction, "Unknown")

        probability_breakdown = {
            LABELS.get(idx, f"Class {idx}"): round(float(prob * 100), 2)
            for idx, prob in enumerate(probabilities)
        }

        # -------------------------------------------------
        # RULE-BASED CLASSIFIER
        # -------------------------------------------------
        severity_engine = SeverityClassifier(features)
        severity_analysis = severity_engine.classify()

        # -------------------------------------------------
        # TREATMENT ENGINE
        # -------------------------------------------------
        treatment_engine = TreatmentEngine(
            features,
            {
                "severity": severity,
                "confidence": confidence,
            },
        )

        treatment_output = treatment_engine.generate_recommendations()
        clinical_findings, recommendations, treatment_priority = normalize_treatment_output(
            treatment_output,
            severity,
        )

        # -------------------------------------------------
        # ENCODE OVERLAY IMAGE
        # -------------------------------------------------
        success, buffer = cv2.imencode(".jpg", overlay_image)
        if not success:
            return jsonify({
                "success": False,
                "error": "Failed to encode overlay",
            }), 500

        overlay_base64 = base64.b64encode(buffer).decode("utf-8")

        # -------------------------------------------------
        # SAVE ANNOTATED IMAGE
        # -------------------------------------------------
        annotated_name = f"{uuid.uuid4()}_annotated.jpg"
        annotated_path = os.path.join(REPORT_FOLDER, annotated_name)
        cv2.imwrite(annotated_path, overlay_image)

        # -------------------------------------------------
        # CLEANUP
        # -------------------------------------------------
        try:
            os.remove(upload_path)
        except OSError:
            pass

        # SAVE REPORT TO DATABASE

        new_report = SmileReport(

            patient_name="Patient",

            smile_symmetry=features.get("smile_symmetry", 0),

            smile_width=features.get("smile_width", 0),

            smile_arc=features.get("smile_arc", 0),

            midline_deviation=features.get("midline_deviation", 0),

            lip_opening=features.get("lip_opening", 0),

            gingival_display=features.get("gingival_display", 0),

            buccal_corridor=features.get("buccal_corridor", 0),

            face_ratio=features.get("face_ratio", 0),

            severity=severity,

            confidence=confidence,

            treatment_priority=treatment_priority,

            overlay_image=overlay_base64
        )

        db.session.add(new_report)

        db.session.commit()


        # -------------------------------------------------
        # RESPONSE
        # -------------------------------------------------
        return jsonify({
            "success": True,
            "severity": severity,
            "confidence": round(confidence, 4),
            "quality_score": round(quality_score, 4),
            "head_tilt": round(head_tilt, 2),
            "features": features,
            "probabilities": probability_breakdown,
            "severity_analysis": severity_analysis,
            "clinical_findings": clinical_findings,
            "recommendations": recommendations,
            "treatment_priority": treatment_priority,
            "overlay_image": overlay_base64,
            "overlay_image_path": annotated_path,
        })

    except Exception as e:
        traceback.print_exc()

        if upload_path and os.path.exists(upload_path):
            try:
                os.remove(upload_path)
            except OSError:
                pass

        return jsonify({
            "success": False,
            "error": str(e),
        }), 500
# =====================================================
# GET ALL REPORTS
# =====================================================

@app.route(
    "/dashboard-stats",
    methods=["GET"]
)
def dashboard_stats():

    total_cases = SmileReport.query.count()

    avg_confidence = db.session.query(
        db.func.avg(SmileReport.confidence)
    ).scalar()

    if avg_confidence is None:
        avg_confidence = 0

    return jsonify({

        "success": True,

        "total_cases": total_cases,

        "total_reports": total_cases,

        "avg_confidence": round(
            avg_confidence * 100,
            1
        ),
    })
@app.route(
    "/reports",
    methods=["GET"]
)
def get_reports():

    try:

        reports = SmileReport.query.order_by(
            SmileReport.created_at.desc()
        ).all()

        reports_data = []

        for report in reports:

            reports_data.append({

                "id": report.id,
                "patient_name": report.patient_name,
                "smile_symmetry": report.smile_symmetry,
                "smile_width": report.smile_width,
                "smile_arc": report.smile_arc,
                "midline_deviation": report.midline_deviation,
                "lip_opening": report.lip_opening,
                "gingival_display": report.gingival_display,
                "buccal_corridor": report.buccal_corridor,
                "face_ratio": report.face_ratio,
                "overlay_image": report.overlay_image,

                "created_at":
                    report.created_at.strftime(
                        "%Y-%m-%d %H:%M"
                    )

            })

        return jsonify({

            "success": True,
            "reports": reports_data

        })

    except Exception as e:

        return jsonify({

            "success": False,
            "error": str(e)

        }), 500

# =====================================================
# RUN SERVER
# =====================================================
with app.app_context():
    db.create_all()

if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=True,
    )