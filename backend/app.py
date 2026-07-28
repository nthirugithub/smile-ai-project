from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import (
    generate_password_hash,
    check_password_hash
)
from config import Config
import re

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
import random
from datetime import datetime, timedelta

from ai_engine.face_mesh_3d import FaceMesh3D
from ai_engine.feature_extractor import FeatureExtractor
from ai_engine.severity_classifier import SeverityClassifier
from ai_engine.treatment_engine import TreatmentEngine

from ai_engine.smile_score_engine import SmileScoreEngine
from ai_engine.smile_reasoning import SmileReasoning

from flask_jwt_extended import (
    JWTManager,
    create_access_token,
    jwt_required,
    get_jwt_identity
)

import logging
# =====================================================
# INIT APP
# =====================================================

app = Flask(__name__)
app.config.from_object(Config)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s"
)

logger = logging.getLogger(__name__)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)
jwt = JWTManager(app)
logger.info(f"Instance Path: {app.instance_path}")
logger.info(f"Database: {app.config['SQLALCHEMY_DATABASE_URI']}")
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

    smile_score = db.Column(
        db.Float,
        default=0
    )

    score_grade = db.Column(
        db.String(5),
        default=""
    )

    score_level = db.Column(
        db.String(50),
        default=""
    )

    clinical_findings = db.Column(
        db.JSON,
        default=list
    )

    clinical_interpretation = db.Column(
        db.JSON,
        default=list
    )

    recommendations = db.Column(
        db.JSON,
        default=list
    )

    strengths = db.Column(
        db.JSON,
        default=list
    )

    improvements = db.Column(
        db.JSON,
        default=list
    )

    analysis_priority = db.Column(
        db.String(50),
        default=""
    )

    created_at = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        index=True
    )
    user_id = db.Column(
    db.Integer,
    db.ForeignKey("user.id"),
    nullable=False,
    index=True
    )
    reviewed = db.Column(
        db.Boolean,
        default=False
    )
class User(db.Model):

    id = db.Column(
        db.Integer,
        primary_key=True
    )

    name = db.Column(
        db.String(100),
        nullable=False
    )

    email = db.Column(
        db.String(120),
        unique=True,
        nullable=False,
        index=True
    )

    password = db.Column(
        db.String(255),
        nullable=False
    )
    reset_otp = db.Column(db.String(6), nullable=True)

    reset_otp_expiry = db.Column(
        db.DateTime,
        nullable=True,
    )

    phone = db.Column(
        db.String(20),
        default=""
    )

    clinic = db.Column(
        db.String(150),
        default=""
    )

    specialization = db.Column(
        db.String(100),
        default="Orthodontist"
    )

    registration_number = db.Column(
        db.String(100),
        default=""
    )

    experience = db.Column(
        db.Integer,
        default=0
    )

    profile_image = db.Column(
        db.Text,
        default=""
    )

class UserSettings(db.Model):

    id = db.Column(
        db.Integer,
        primary_key=True
    )

    user_id = db.Column(
        db.Integer,
        db.ForeignKey("user.id"),
        unique=True,
        nullable=False
    )

    email_notifications = db.Column(
        db.Boolean,
        default=True
    )

    auto_landmark_detection = db.Column(
        db.Boolean,
        default=True
    )

    auto_generate_reports = db.Column(
        db.Boolean,
        default=True
    )

    store_processed_images = db.Column(
        db.Boolean,
        default=True
    )

    auto_backup_reports = db.Column(
        db.Boolean,
        default=False
    )

    confidence_threshold = db.Column(
        db.Integer,
        default=85
    )

    theme = db.Column(
        db.String(20),
        default="System"
    )

# =====================================================
# NOTIFICATIONS
# =====================================================

class Notification(db.Model):

    id = db.Column(
        db.Integer,
        primary_key=True
    )

    user_id = db.Column(
        db.Integer,
        db.ForeignKey("user.id"),
        nullable=False,
        index=True
    )

    title = db.Column(
        db.String(150),
        nullable=False
    )

    message = db.Column(
        db.Text,
        nullable=False
    )

    notification_type = db.Column(
        db.String(50),
        default="info"
    )

    is_read = db.Column(
        db.Boolean,
        default=False
    )

    created_at = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        index=True
    )

CORS(
    app,
    resources={
        r"/*": {
            "origins": "*",
            "allow_headers": [
                "Content-Type",
                "Authorization"
            ],
            "methods": [
                "GET",
                "POST",
                "PUT",
                "DELETE",
                "OPTIONS"
            ]
        }
    }
)


# =====================================================
# PATHS
# =====================================================

MODEL_PATH = app.config["MODEL_PATH"]
SCALER_PATH = app.config["SCALER_PATH"]
UPLOAD_FOLDER = app.config["UPLOAD_FOLDER"]
REPORT_FOLDER = app.config["REPORT_FOLDER"]

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(REPORT_FOLDER, exist_ok=True)


# =====================================================
# LOAD MODEL
# =====================================================

logger.info("Loading Smile AI Backend...")

if not os.path.exists(MODEL_PATH):
    raise FileNotFoundError(f"Missing model file: {MODEL_PATH}")

if not os.path.exists(SCALER_PATH):
    raise FileNotFoundError(f"Missing scaler file: {SCALER_PATH}")

model = joblib.load(MODEL_PATH)
scaler = joblib.load(SCALER_PATH)
mesh_detector = FaceMesh3D()

score_engine = SmileScoreEngine()
reasoning_engine = SmileReasoning()

logger.info("Backend Ready.")


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
            output.get("clinical_interpretation", []),
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
    
def cleanup_old_notifications(user_id, limit=15):
    notifications = (
        Notification.query
        .filter_by(user_id=user_id)
        .order_by(Notification.created_at.desc())
        .offset(limit)
        .all()
    )

    for notification in notifications:
        db.session.delete(notification)


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
@jwt_required()
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
        allowed_mime_types = {
            "image/jpeg",
            "image/png",
            "image/jpg",
        }

        if image.mimetype not in allowed_mime_types:
            return jsonify({
                "success": False,
                "error": "Only JPG and PNG images are allowed."
            }), 400

        current_user_id = int(get_jwt_identity())
        user_id = current_user_id

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
        # VERIFY IMAGE IS VALID
        # -------------------------------------------------
        test_image = cv2.imread(upload_path)

        if test_image is None:
            if os.path.exists(upload_path):
                os.remove(upload_path)

            return jsonify({
                "success": False,
                "error": "Invalid or corrupted image."
            }), 400

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


        # ==========================================
        # AI Smile Reasoning
        # ==========================================



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

                # -------------------------------------------------
        # RULE-BASED CLASSIFIER
        # -------------------------------------------------
        severity_engine = SeverityClassifier(features)
        severity_analysis = severity_engine.classify()

        final_severity = severity_analysis["severity"]

        # -------------------------------------------------
        # AI SMILE SCORE
        # -------------------------------------------------

        score_result = score_engine.calculate_score(
            features,
            probabilities,
            severity_analysis,
        )

        smile_score = min(score_result["smile_score"], 9.4)
        # ---------------------------------------
        # Smile Score Grade
        # ---------------------------------------

        if smile_score >= 9.0:
            score_grade = "A+"
            score_level = "Excellent"

        elif smile_score >= 8.0:
            score_grade = "A"
            score_level = "Very Good"

        elif smile_score >= 7.0:
            score_grade = "B"
            score_level = "Good"

        elif smile_score >= 6.0:
            score_grade = "C"
            score_level = "Fair"

        elif smile_score >= 5.0:
            score_grade = "D"
            score_level = "Needs Improvement"

        else:
            score_grade = "F"
            score_level = "Poor"

        confidence = float(np.max(probabilities))
        severity = LABELS.get(prediction, "Unknown")
        

        probability_breakdown = {
            LABELS.get(idx, f"Class {idx}"): round(float(prob * 100), 2)
            for idx, prob in enumerate(probabilities)
        }





        # ==========================================
        # AI Smile Reasoning
        # ==========================================

        reasoning = reasoning_engine.analyze(
            features,
            severity_analysis,
        )

        strengths = reasoning["strengths"]
        improvements = reasoning["improvements"]

        # -------------------------------------------------
        # TREATMENT ENGINE
        # -------------------------------------------------
        treatment_engine = TreatmentEngine(
            features,
            {
                "severity": final_severity,
                "confidence": confidence,
            },
            severity_analysis,
        )

        treatment_output = treatment_engine.generate_recommendations()
        logger.info(
            f"Treatment generated successfully. Severity: {final_severity}"
        )

        clinical_findings, recommendations, treatment_priority, clinical_interpretation = normalize_treatment_output(
            treatment_output,
            severity,
        )
        priority = treatment_priority

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
        patient_count = SmileReport.query.filter_by(
            user_id=user_id
        ).count()

        patient_name = f"Patient {patient_count + 1}"

        new_report = SmileReport(

            patient_name=patient_name,

            smile_symmetry=features.get("smile_symmetry", 0),

            smile_width=features.get("smile_width", 0),

            smile_arc=features.get("smile_arc", 0),

            midline_deviation=features.get("midline_deviation", 0),

            lip_opening=features.get("lip_opening", 0),

            gingival_display=features.get("gingival_display", 0),

            buccal_corridor=features.get("buccal_corridor", 0),

            face_ratio=features.get("face_ratio", 0),

            severity=final_severity,

            confidence=confidence,

            treatment_priority=treatment_priority,

            overlay_image=overlay_base64,

            smile_score=smile_score,

            score_grade=score_grade,

            score_level=score_level,

            clinical_findings=clinical_findings,

            clinical_interpretation=clinical_interpretation,

            recommendations=recommendations,

            strengths=strengths,

            improvements=improvements,

            analysis_priority=priority,

            user_id=user_id,

            reviewed=False,
        )

        db.session.add(new_report)

        notification = Notification(

            user_id=user_id,

            title="Smile Analysis Completed",

            message=f"{patient_name} analyzed successfully.",

            notification_type="success",

        )

        db.session.add(notification)

        cleanup_old_notifications(user_id)

        db.session.commit()

        logger.info(
            f"Notification created successfully for User {user_id}"
        )

        logger.info(
            f"Prediction completed | "
            f"User={user_id} | "
            f"Severity={final_severity} | "
            f"Confidence={confidence:.2f} | "
            f"Quality={quality_score:.2f}"
        )


        # -------------------------------------------------
        # RESPONSE
        
        return jsonify({
            "success": True,
            "severity": final_severity,
            "ml_prediction": severity,
            "confidence": round(confidence * 100, 1),

            "analysis_confidence": round(
                severity_analysis["confidence"] * 100,
                1
            ),
            "smile_score": round(smile_score, 1),
            "grade": score_grade,
            "level": score_level,
            "strengths": strengths,
            "improvements": improvements,
            "priority": priority,
            "quality_score": round(quality_score, 4),
            "head_tilt": round(head_tilt, 2),
            "features": features,
            "probabilities": probability_breakdown,
            "severity_analysis": severity_analysis,
            "clinical_findings": clinical_findings,
            "recommendations": recommendations,
            "clinical_interpretation": clinical_interpretation,
            "overlay_image": overlay_base64,
            "overlay_image_path": annotated_path,
        })

    except Exception:
        db.session.rollback()
        logger.exception("Prediction failed")

        if upload_path and os.path.exists(upload_path):
            try:
                os.remove(upload_path)
            except OSError:
                pass

        return jsonify({
            "success": False,
            "error": "Prediction failed"
        }), 500
# =====================================================
# GET ALL REPORTS
# =====================================================

@app.route(
    "/dashboard-stats",
    methods=["GET"]
)
@jwt_required()
def dashboard_stats():

    current_user_id = int(get_jwt_identity())
    print("CURRENT USER:", current_user_id)
    all_reports = SmileReport.query.all()

    for report in all_reports:
        print(
            "REPORT:",
            report.id,
            "PATIENT:",
            report.patient_name,
            "USER_ID:",
            report.user_id
        )

    total_cases = SmileReport.query.filter_by(
        user_id=current_user_id
    ).count()

    avg_confidence = db.session.query(
        db.func.avg(SmileReport.confidence)
    ).filter(
        SmileReport.user_id == current_user_id
    ).scalar()

    if avg_confidence is None:
        avg_confidence = 0

    pending_review = SmileReport.query.filter_by(
        user_id=current_user_id,
        reviewed=False
    ).count()



    return jsonify({

        "success": True,

        "total_cases": total_cases,

        "total_reports": total_cases,

        "avg_confidence": round(
            avg_confidence * 100,
            1
        ),
        "pending_review": pending_review,
    })
@app.route(
    "/reports",
    methods=["GET"]
)
@jwt_required()
def get_reports():

    try:
        current_user_id = int(get_jwt_identity())

        reports = SmileReport.query.filter_by(
            user_id=current_user_id
        ).order_by(
            SmileReport.created_at.desc()
        ).limit(40).all()

        reports_data = []

        for report in reports:

            reports_data.append({

                "id": report.id,
                "patient_name": report.patient_name,
                "severity": report.severity,
                "confidence": round(report.confidence * 100, 1),
                "treatment_priority": report.treatment_priority,
                "smile_symmetry": report.smile_symmetry,
                "smile_width": report.smile_width,
                "smile_arc": report.smile_arc,
                "midline_deviation": report.midline_deviation,
                "lip_opening": report.lip_opening,
                "gingival_display": report.gingival_display,
                "buccal_corridor": report.buccal_corridor,
                "face_ratio": report.face_ratio,
                "overlay_image_base64": report.overlay_image,

                "created_at":
                    report.created_at.strftime(
                        "%Y-%m-%d %H:%M"
                    )
                

            })

        return jsonify({

            "success": True,
            "reports": reports_data

        })

    except Exception:
        logger.exception("Failed to fetch reports")

        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500

@app.route("/reports/<int:report_id>", methods=["GET"])
@jwt_required()
def get_report(report_id):

    current_user_id = int(get_jwt_identity())

    report = SmileReport.query.filter_by(
        id=report_id,
        user_id=current_user_id
    ).first()

    if not report:
        return jsonify({
            "success": False,
            "error": "Report not found"
        }), 404

    return jsonify({
        "success": True,
        "report": {

            "id": report.id,

            "patient_name": report.patient_name,

            "severity": report.severity,

            "confidence": round(report.confidence * 100, 1),

            "treatment_priority": report.treatment_priority,

            "smile_score": round(report.smile_score, 1),

            "grade": report.score_grade,

            "level": report.score_level,

            "strengths": report.strengths,

            "improvements": report.improvements,

            "priority": report.analysis_priority,

            "clinical_findings": report.clinical_findings,

            "clinical_interpretation": report.clinical_interpretation,

            "recommendations": report.recommendations,

            "features": {

                "smile_symmetry": report.smile_symmetry,

                "smile_width": report.smile_width,

                "smile_arc": report.smile_arc,

                "midline_deviation": report.midline_deviation,

                "lip_opening": report.lip_opening,

                "gingival_display": report.gingival_display,

                "buccal_corridor": report.buccal_corridor,

                "face_ratio": report.face_ratio,
            },

            "overlay_image": report.overlay_image,

            "created_at": report.created_at.strftime("%Y-%m-%d %H:%M")
        }
    })

@app.route(
    "/reports/<int:report_id>/review",
    methods=["PUT"]
)
@jwt_required()
def mark_report_reviewed(report_id):

    try:

        current_user_id = int(get_jwt_identity())

        report = SmileReport.query.filter_by(
            id=report_id,
            user_id=current_user_id
        ).first()

        if not report:
            return jsonify({
                "success": False,
                "error": "Report not found"
            }), 404


        report.reviewed = True

        db.session.commit()


        return jsonify({
            "success": True
        })


    except Exception:

        db.session.rollback()

        logger.exception(
            "Failed to mark report reviewed"
        )

        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500
    
@app.route("/search-patients", methods=["GET"])
@jwt_required()
def search_patients():

    try:
        current_user_id = int(get_jwt_identity())

        query = request.args.get("q", "").strip()

        if not query:
            return jsonify({
                "success": True,
                "patients": []
            })

        reports = (
            SmileReport.query
            .filter(
                SmileReport.user_id == current_user_id,
                SmileReport.patient_name.ilike(f"%{query}%")
            )
            .order_by(SmileReport.created_at.desc())
            .limit(10)
            .all()
        )

        patients = []

        for report in reports:
            patients.append({
                "id": report.id,
                "patient_name": report.patient_name,
                "severity": report.severity,
                "confidence": report.confidence,
                "created_at": report.created_at.strftime(
                    "%Y-%m-%d %H:%M"
                ),
            })

        return jsonify({
            "success": True,
            "patients": patients
        })

    except Exception:
        logger.exception("Patient search failed")

        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500
# =====================================================
# GET NOTIFICATIONS
# =====================================================

@app.route("/notifications", methods=["GET"])
@jwt_required()
def get_notifications():

    try:
        current_user_id = int(get_jwt_identity())
        user_id = current_user_id

        notifications = Notification.query.filter_by(
            user_id=user_id
        ).order_by(
            Notification.created_at.desc()
        ).all()

        data = []

        for n in notifications:

            data.append({

                "id": n.id,

                "title": n.title,

                "message": n.message,

                "type": n.notification_type,

                "is_read": n.is_read,

                "created_at": n.created_at.strftime(
                    "%d %b %Y %I:%M %p"
                ),

            })

        return jsonify({

            "success": True,

            "notifications": data,

        })

    except Exception:
        logger.exception("Failed to fetch notifications")

        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500
    
# =====================================================
# MARK NOTIFICATIONS AS READ
# =====================================================

@app.route("/notifications/read", methods=["PUT"])
@jwt_required()
def mark_notifications_read():

    try:
        current_user_id = int(get_jwt_identity())

        try:
            Notification.query.filter_by(
                user_id=current_user_id,
                is_read=False
            ).update({
                "is_read": True
            })

            db.session.commit()

        except Exception:
            db.session.rollback()
            logger.exception("Mark notifications as read failed")

            return jsonify({
                "success": False,
                "error": "Internal server error"
            }), 500

        return jsonify({
            "success": True
        })

    except Exception:
        logger.exception("Failed to mark notifications as read")

        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500
    
    
# =====================================================
# REGISTER
# =====================================================

@app.route("/register", methods=["POST"])
def register():

    data = request.get_json()
    

    if not data:
        return jsonify({
            "success": False,
            "error": "Request body is required"
        }), 400

    name = data.get("name", "").strip()
    email = data.get("email", "").strip().lower()
    password = data.get("password", "")

    if not name:
        return jsonify({
            "success": False,
            "error": "Name is required"
        }), 400

    if len(name) < 2:
        return jsonify({
            "success": False,
            "error": "Name must be at least 2 characters"
        }), 400

    if len(name) > 100:
        return jsonify({
            "success": False,
            "error": "Name is too long"
        }), 400
    
    email_pattern = r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'

    if not email:
        return jsonify({
            "success": False,
            "error": "Email is required"
        }), 400

    if not re.match(email_pattern, email):
        return jsonify({
            "success": False,
            "error": "Invalid email address"
        }), 400
    
    if not password:
        return jsonify({
            "success": False,
            "error": "Password is required"
        }), 400

    if len(password) < 8:
        return jsonify({
            "success": False,
            "error": "Password must be at least 8 characters"
        }), 400

    if len(password) > 128:
        return jsonify({
            "success": False,
            "error": "Password is too long"
        }), 400

    existing_user = User.query.filter_by(
        email=email
    ).first()

    if existing_user:
        return jsonify({
            "success": False,
            "error": "Email already exists"
        }), 400

    user = User(
        name=name,
        email=email,
        password=generate_password_hash(password)
    )

    try:
        db.session.add(user)
        db.session.flush()      # assigns user.id without committing

        settings = UserSettings(user_id=user.id)
        db.session.add(settings)

        db.session.commit()

    except Exception:
        db.session.rollback()
        logger.exception("Registration failed")
        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500

    return jsonify({
        "success": True,
        "message": "User registered successfully"
    })

@app.route("/login", methods=["POST"])
def login():

    data = request.get_json()

    if not data:
        return jsonify({
            "success": False,
            "error": "Request body is required"
        }), 400

    email = data.get("email", "").strip().lower()
    password = data.get("password", "")

    if not email:
        return jsonify({
            "success": False,
            "error": "Email is required"
        }), 400

    email_pattern = r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'

    if not re.match(email_pattern, email):
        return jsonify({
            "success": False,
            "error": "Invalid email address"
        }), 400

    if not password:
        return jsonify({
            "success": False,
            "error": "Password is required"
        }), 400

    user = User.query.filter_by(
        email=email
    ).first()

    if not user:
        return jsonify({
            "success": False,
            "error": "User not found"
        }), 401

    if not check_password_hash(
        user.password,
        password
    ):
        return jsonify({
            "success": False,
            "error": "Invalid password"
        }), 401
    
    access_token = create_access_token(identity=str(user.id))

    return jsonify({
        "success": True,
        "access_token": access_token,
        "user_id": user.id,
        "name": user.name,
        "email": user.email
    })

@app.route(
    "/forgot-password",
    methods=["POST"]
)
def forgot_password():

    try:

        data = request.get_json()

        if not data:
            return jsonify({
                "success": False,
                "error": "Request body is required"
            }), 400

        email = data.get("email")

        if not email:

            return jsonify({
                "success": False,
                "error": "Email is required"
            }), 400

        user = User.query.filter_by(
            email=email
        ).first()

        if not user:

            return jsonify({
                "success": False,
                "error": "Email not found"
            }), 404

        otp = str(
            random.randint(
                100000,
                999999
            )
        )

        user.reset_otp = otp

        user.reset_otp_expiry = (
            datetime.now()
            + timedelta(minutes=5)
        )

        db.session.commit()

        print("\n========================")
        print("PASSWORD RESET OTP")
        print(f"Email : {email}")
        print(f"OTP   : {otp}")
        print("========================\n")

        return jsonify({

            "success": True,
            "message":
                "OTP generated successfully."

        })

    except Exception:
        db.session.rollback()
        logger.exception("Forgot password failed")

        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500
    
@app.route(
    "/verify-otp",
    methods=["POST"]
)
def verify_otp():

    try:

        data = request.get_json()

        if not data:
            return jsonify({
                "success": False,
                "error": "Request body is required"
            }), 400

        email = data.get("email")
        otp = data.get("otp")

        if not email or not otp:

            return jsonify({
                "success": False,
                "error": "Email and OTP are required"
            }), 400

        user = User.query.filter_by(
            email=email
        ).first()

        if not user:

            return jsonify({
                "success": False,
                "error": "User not found"
            }), 404

        if user.reset_otp != otp:

            return jsonify({
                "success": False,
                "error": "Invalid OTP"
            }), 400

        if (
            user.reset_otp_expiry is None or
            datetime.now() > user.reset_otp_expiry
        ):

            return jsonify({
                "success": False,
                "error": "OTP has expired"
            }), 400

        return jsonify({

            "success": True,
            "message": "OTP verified successfully."

        })

    except Exception:
        db.session.rollback()
        logger.exception("OTP verification failed")

        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500

@app.route(
    "/reset-password",
    methods=["POST"]
)
def reset_password():

    try:

        data = request.get_json()

        if not data:
            return jsonify({
                "success": False,
                "error": "Request body is required"
            }), 400

        email = data.get("email")
        new_password = data.get("new_password")

        if not email or not new_password:

            return jsonify({
                "success": False,
                "error": "Email and new password are required"
            }), 400
        
        if len(new_password) < 8:
            return jsonify({
                "success": False,
                "error": "Password must be at least 8 characters"
            }), 400

        if len(new_password) > 128:
            return jsonify({
                "success": False,
                "error": "Password is too long"
            }), 400

        user = User.query.filter_by(
            email=email
        ).first()

        if not user:

            return jsonify({
                "success": False,
                "error": "User not found"
            }), 404

        try:
            user.password = generate_password_hash(new_password)

            user.reset_otp = None
            user.reset_otp_expiry = None

            notification = Notification(
                user_id=user.id,
                title="Password Reset",
                message="Your account password has been reset successfully.",
                notification_type="info",
            )

            db.session.add(notification)

            cleanup_old_notifications(user.id)

            db.session.commit()

        except Exception:
            db.session.rollback()
            logger.exception("Password reset failed")

            return jsonify({
                "success": False,
                "error": "Internal server error"
            }), 500

        return jsonify({
            "success": True,
            "message": "Password reset successfully."
        })

    except Exception:
        logger.exception("Failed to fetch reports")

        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500
# =====================================================
# GET PROFILE
# =====================================================

@app.route("/profile/<int:user_id>", methods=["GET"])
@jwt_required()
def get_profile(user_id):

    current_user_id = int(get_jwt_identity())

    if current_user_id != user_id:
        return jsonify({
            "success": False,
            "error": "Unauthorized access"
        }), 403

    user = User.query.get(user_id)

    if not user:
        return jsonify({
            "success": False,
            "error": "User not found"
        }), 404
    
    total_cases = SmileReport.query.filter_by(
        user_id=user_id
    ).count()
    recent_reports = SmileReport.query.filter_by(
        user_id=user_id
    ).order_by(
        SmileReport.created_at.desc()
    ).limit(3).all()
    recent_activity = []

    for report in recent_reports:

        recent_activity.append({

            "patient_name": report.patient_name,

            "severity": report.severity,

            "created_at": report.created_at.strftime(
                "%d %b %Y"
            ),

        })
    latest_report = SmileReport.query.filter_by(
        user_id=user_id
    ).order_by(
        SmileReport.created_at.desc()
    ).first()

    reports_generated = total_cases

    average_confidence = db.session.query(
        db.func.avg(SmileReport.confidence)
    ).filter(
        SmileReport.user_id == user_id
    ).scalar()

    if average_confidence is None:
        average_confidence = 0
    else:
        average_confidence = round(
            average_confidence * 100,
            1
        )

    if latest_report:

        last_analysis = latest_report.created_at.strftime(
            "%d %b %Y, %I:%M %p"
        )

    else:

        last_analysis = "No Analysis Yet"

    return jsonify({

        "success": True,

        "profile": {

            "id": user.id,
            "name": user.name,
            "email": user.email,
            "phone": user.phone,
            "clinic": user.clinic,
            "specialization": user.specialization,
            "registration_number": user.registration_number,
            "experience": user.experience,
            "profile_image": user.profile_image

        },
        "stats": {

            "total_cases": total_cases,

            "reports_generated": reports_generated,

            "average_confidence": average_confidence,

            "last_analysis": last_analysis,

        },
        "recent_activity": recent_activity,
        

    })

# =====================================================
# UPDATE PROFILE
# =====================================================
@app.route("/profile/<int:user_id>", methods=["PUT"])
@jwt_required()
def update_profile(user_id):

    current_user_id = int(get_jwt_identity())

    if current_user_id != user_id:
        return jsonify({
            "success": False,
            "error": "Unauthorized access"
        }), 403

    user = User.query.get(user_id)

    if not user:
        return jsonify({
            "success": False,
            "error": "User not found"
        }), 404

    data = request.get_json()
  

    if not data:
        return jsonify({
            "success": False,
            "error": "Request body is required"
        }), 400

    name = data.get("name", user.name).strip()
    phone = data.get("phone", user.phone).strip()
    clinic = data.get("clinic", user.clinic).strip()

    registration_number = data.get(
        "registration_number",
        user.registration_number
    ).strip()

    specialization = data.get(
        "specialization",
        user.specialization
    ).strip()

    experience = data.get(
        "experience",
        user.experience
    )

    # -----------------------------
    # Name Validation
    # -----------------------------
    if not name:
        return jsonify({
            "success": False,
            "error": "Name is required"
        }), 400

    if len(name) > 100:
        return jsonify({
            "success": False,
            "error": "Name is too long"
        }), 400

    # -----------------------------
    # Phone Validation
    # -----------------------------
    if phone:

        if not phone.isdigit():
            return jsonify({
                "success": False,
                "error": "Phone number must contain only digits"
            }), 400

        if len(phone) != 10:
            return jsonify({
                "success": False,
                "error": "Phone number must be exactly 10 digits"
            }), 400

    # -----------------------------
    # Experience Validation
    # -----------------------------
    try:
        experience = int(experience)

    except (TypeError, ValueError):
        return jsonify({
            "success": False,
            "error": "Experience must be a valid number"
        }), 400

    if experience < 0:
        return jsonify({
            "success": False,
            "error": "Experience cannot be negative"
        }), 400

    if experience > 60:
        return jsonify({
            "success": False,
            "error": "Experience seems unrealistic"
        }), 400

    # -----------------------------
    # Registration Number
    # -----------------------------
    if len(registration_number) > 100:
        return jsonify({
            "success": False,
            "error": "Registration number is too long"
        }), 400
    
    user.name = name
    user.phone = phone
    user.clinic = clinic
    user.registration_number = registration_number
    user.specialization = specialization
    user.experience = experience

    notification = Notification(

        user_id=user_id,

        title="Profile Updated",

        message="Your profile information was updated successfully.",

        notification_type="info",

    )

    try:
        db.session.add(notification)

        cleanup_old_notifications(user_id)

        db.session.commit()

    except Exception:
        db.session.rollback()
        logger.exception("Profile update failed")

        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500

    return jsonify({
        "success": True,
        "message": "Profile updated successfully"
    })

# =====================================================
# GET SETTINGS
# =====================================================

@app.route("/settings/<int:user_id>", methods=["GET"])
@jwt_required()
def get_settings(user_id):
    current_user_id = int(get_jwt_identity())

    if current_user_id != user_id:
        return jsonify({
            "success": False,
            "error": "Unauthorized access"
        }), 403

    user = User.query.get(user_id)

    if not user:
        return jsonify({
            "success": False,
            "error": "User not found"
        }), 404

    settings = UserSettings.query.filter_by(
        user_id=user_id
    ).first()

    if settings is None:
        try:
            settings = UserSettings(user_id=user_id)
            db.session.add(settings)
            db.session.commit()

        except Exception:
            db.session.rollback()
            logger.exception("Failed to create default settings")

            return jsonify({
                "success": False,
                "error": "Internal server error"
            }), 500

    return jsonify({

        "success": True,

        "settings": {

            "email_notifications":
                settings.email_notifications,

            "auto_landmark_detection":
                settings.auto_landmark_detection,

            "auto_generate_reports":
                settings.auto_generate_reports,

            "store_processed_images":
                settings.store_processed_images,

            "auto_backup_reports":
                settings.auto_backup_reports,

            "confidence_threshold":
                settings.confidence_threshold,

            "theme":
                settings.theme,

        }

    })
# =====================================================
# UPDATE SETTINGS
# =====================================================

@app.route("/settings/<int:user_id>", methods=["PUT"])
@jwt_required()
def update_settings(user_id):

    current_user_id = int(get_jwt_identity())

    if current_user_id != user_id:
        return jsonify({
            "success": False,
            "error": "Unauthorized access"
        }), 403

    settings = UserSettings.query.filter_by(
        user_id=user_id
    ).first()

    if settings is None:

        settings = UserSettings(
            user_id=user_id
        )

        db.session.add(settings)

    data = request.get_json()
    if not data:
        return jsonify({
            "success": False,
            "error": "Request body is required"
        }), 400

    settings.email_notifications = data.get(
        "email_notifications",
        settings.email_notifications
    )

    settings.auto_landmark_detection = data.get(
        "auto_landmark_detection",
        settings.auto_landmark_detection
    )

    settings.auto_generate_reports = data.get(
        "auto_generate_reports",
        settings.auto_generate_reports
    )

    settings.store_processed_images = data.get(
        "store_processed_images",
        settings.store_processed_images
    )

    settings.auto_backup_reports = data.get(
        "auto_backup_reports",
        settings.auto_backup_reports
    )

    settings.confidence_threshold = data.get(
        "confidence_threshold",
        settings.confidence_threshold
    )

    settings.theme = data.get(
        "theme",
        settings.theme
    )
    notification = Notification(

        user_id=user_id,

        title="Settings Updated",

        message="Your application settings were updated successfully.",

        notification_type="info",

    )

    try:
        db.session.add(notification)

        cleanup_old_notifications(user_id)

        db.session.commit()

    except Exception:
        db.session.rollback()
        logger.exception("Settings update failed")

        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500

    return jsonify({
        "success": True,
        "message": "Settings updated successfully"
    })
# =====================================================
# CHANGE PASSWORD
# =====================================================

@app.route("/change-password/<int:user_id>", methods=["PUT"])
@jwt_required()
def change_password(user_id):

    current_user_id = int(get_jwt_identity())

    if current_user_id != user_id:
        return jsonify({
            "success": False,
            "error": "Unauthorized access"
        }), 403

    user = User.query.get(user_id)

    if not user:
        return jsonify({
            "success": False,
            "error": "User not found"
        }), 404

    data = request.get_json()
    if not data:
        return jsonify({
            "success": False,
            "error": "Request body is required"
        }), 400

    current_password = data.get("current_password")
    new_password = data.get("new_password")

    if not current_password or not new_password:
        return jsonify({
            "success": False,
            "error": "Current password and new password are required"
        }), 400
    
    if len(new_password) < 8:
        return jsonify({
            "success": False,
            "error": "Password must be at least 8 characters"
        }), 400

    if len(new_password) > 128:
        return jsonify({
            "success": False,
            "error": "Password is too long"
        }), 400

    if not check_password_hash(
        user.password,
        current_password
    ):
        return jsonify({
            "success": False,
            "error": "Current password is incorrect"
        }), 400
    if check_password_hash(user.password, new_password):
        return jsonify({
            "success": False,
            "error": "New password must be different from the current password"
        }), 400

    try:
        user.password = generate_password_hash(new_password)

        notification = Notification(
            user_id=user_id,
            title="Password Changed",
            message="Your account password was changed successfully.",
            notification_type="info",
        )

        db.session.add(notification)

        cleanup_old_notifications(user_id)

        db.session.commit()

    except Exception:
        db.session.rollback()
        logger.exception("Password change failed")

        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500

    return jsonify({
        "success": True,
        "message": "Password changed successfully"
    })

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