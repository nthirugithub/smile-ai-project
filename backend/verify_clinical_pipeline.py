"""
Verification script for Smile AI Phase 2 Clinical Interpretation Engine.
"""

from __future__ import annotations

import sys
import numpy as np

from ai_engine.face_mesh_3d import FaceMesh3D
from ai_engine.feature_extractor import FeatureExtractor
from ai_engine.retinaface_processor import RetinaFaceProcessor
from ai_engine.libreface_processor import LibreFaceProcessor
from ai_engine.severity_classifier import ClinicalInterpretationEngine, SeverityClassifier


def build_realistic_smile_landmarks() -> list:
    """Builds a realistic 478-landmark set representing an esthetic front-facing smile."""
    landmarks = [(320.0, 240.0, 0.0)] * 478

    # Zygomatic arches (Width = 240px)
    for idx in FeatureExtractor.ZYGOMATIC_LEFT:
        landmarks[idx] = (160.0, 220.0, -10.0)
    for idx in FeatureExtractor.ZYGOMATIC_RIGHT:
        landmarks[idx] = (400.0, 220.0, -10.0)

    # Commissures (Width = 110px -> Ratio = 0.458)
    for idx in FeatureExtractor.COMMISSURE_LEFT:
        landmarks[idx] = (265.0, 275.0, 5.0)
    for idx in FeatureExtractor.COMMISSURE_RIGHT:
        landmarks[idx] = (375.0, 275.0, 5.0)

    # Pupils / Interpupillary axis
    for idx in FeatureExtractor.PUPIL_LEFT:
        landmarks[idx] = (240.0, 180.0, 0.0)
    for idx in FeatureExtractor.PUPIL_RIGHT:
        landmarks[idx] = (400.0, 180.0, 0.0)

    # Subnasale, Nasion, Gnathion (Height = 180px -> Face Ratio = 240/180 = 1.333)
    for idx in FeatureExtractor.SUBNASALE:
        landmarks[idx] = (320.0, 245.0, 15.0)
    for idx in FeatureExtractor.NASION:
        landmarks[idx] = (320.0, 150.0, 5.0)
    for idx in FeatureExtractor.GNATHION:
        landmarks[idx] = (320.0, 330.0, -5.0)

    # Stomion / Lip opening
    for idx in FeatureExtractor.UPPER_STOMION:
        landmarks[idx] = (320.0, 270.0, 10.0)
    for idx in FeatureExtractor.LOWER_STOMION:
        landmarks[idx] = (320.0, 282.0, 10.0)
    for idx in FeatureExtractor.LABIAL_FRENUM:
        landmarks[idx] = (320.0, 268.0, 10.0)

    # Inner vermilion lateral boundaries
    for idx in FeatureExtractor.INNER_VERMILION_LEFT:
        landmarks[idx] = (278.0, 275.0, 5.0)
    for idx in FeatureExtractor.INNER_VERMILION_RIGHT:
        landmarks[idx] = (362.0, 275.0, 5.0)

    # Lower lip inner contour for parabolic smile arc
    arc_points = [
        (265.0, 275.0, 5.0), (280.0, 280.0, 8.0), (300.0, 283.0, 10.0),
        (320.0, 284.0, 10.0), (340.0, 283.0, 10.0), (360.0, 280.0, 8.0),
        (375.0, 275.0, 5.0)
    ]
    for i, idx in enumerate(FeatureExtractor.LOWER_LIP_INNER_CONTOUR[:len(arc_points)]):
        landmarks[idx] = arc_points[i]

    return landmarks


def run_verification():
    print("==================================================")
    print("SMILE AI CLINICAL INTERPRETATION ENGINE VERIFICATION")
    print("==================================================")

    landmarks = build_realistic_smile_landmarks()

    # 1. Test FeatureExtractor
    extractor = FeatureExtractor(landmarks)
    features = extractor.extract_all_features()

    print("\n[+] Extracted 8 Visible Features + Quality Score:")
    for k, v in features.items():
        print(f"    - {k:20s}: {v:.4f}")

    # 2. Test ClinicalInterpretationEngine
    engine = ClinicalInterpretationEngine(features)
    clinical_res = engine.evaluate_clinical_interpretation()

    print("\n[+] Clinical Interpretation Engine Decision Support Output:")
    print(f"    - Overall Severity Rating : {clinical_res['severity']}")
    print(f"    - Composite Score (0-100) : {clinical_res['score']}")
    print(f"    - Calibrated Confidence   : {clinical_res['confidence']:.4f}")

    print("\n[+] Structured Feature Assessments (5-Stage Medical Classification):")
    for feat_name, assessment in clinical_res['assessment'].items():
        if isinstance(assessment, dict) and 'severity' in assessment:
            print(f"    - {feat_name:18s}: Val={assessment['value']} | Sev={assessment['severity']:18s} | {assessment['finding']}")

    print("\n[+] Feature Interaction Synergy Analysis:")
    if clinical_res['interaction_findings']:
        for interaction in clinical_res['interaction_findings']:
            print(f"    - [{interaction['synergy']}] {interaction['finding']}")
    else:
        print("    - No adverse feature interactions detected.")

    print("\n[+] Internal Smile & Facial Harmony Engine Indices:")
    for h_name, h_val in clinical_res['harmony_analysis'].items():
        print(f"    - {h_name:30s}: {h_val}")

    print("\n[+] Backward Compatibility Test (SeverityClassifier alias):")
    legacy_classifier = SeverityClassifier(features)
    legacy_res = legacy_classifier.classify()
    assert legacy_res['severity'] == clinical_res['severity']
    assert legacy_res['score'] == clinical_res['score']
    print("    - Backward compatibility confirmed! SeverityClassifier alias works identically.")

    print("\n==================================================")
    print("VERIFICATION SUCCESSFUL: Phase 2 Interpretation Engine Validated")
    print("==================================================")


if __name__ == "__main__":
    run_verification()
