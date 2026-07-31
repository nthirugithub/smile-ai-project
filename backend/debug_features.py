"""
Debug script to print exact feature values and trace why severity is wrong.
"""
import cv2
import os
import sys
import numpy as np

# Add backend to path
sys.path.insert(0, ".")

from ai_engine.face_mesh_3d import FaceMesh3D
from ai_engine.feature_extractor import FeatureExtractor
from ai_engine.severity_classifier import ClinicalInterpretationEngine

mesh_detector = FaceMesh3D()

# Use any recent uploaded image from reports folder to test
import glob
images = sorted(glob.glob("raw_dataset/doctor_images/*.jpeg") + glob.glob("raw_dataset/doctor_images/*.jpg"))
print(f"Found {len(images)} images in doctor_images")

for image_path in images[:3]:
    print(f"\n{'='*60}")
    print(f"Image: {os.path.basename(image_path)}")
    result = mesh_detector.process_image(image_path)
    if result is None:
        print("  -> No face detected, skipping")
        continue

    raw_landmarks = result["raw_landmarks"]
    aligned_landmarks = result["landmarks"]
    img_shape = result["image"].shape

    print(f"Image shape: {img_shape}")

    # --- Test with ALIGNED landmarks (what FeatureExtractor currently uses) ---
    extractor_aligned = FeatureExtractor(aligned_landmarks)
    features_aligned = extractor_aligned.extract_all_features()
    print("\n  Features from ALIGNED landmarks (3D rotation corrected):")
    for k, v in features_aligned.items():
        print(f"    {k}: {v:.4f}")

    # --- Test with RAW landmarks (pixel coordinates) ---
    extractor_raw = FeatureExtractor(raw_landmarks)
    features_raw = extractor_raw.extract_all_features()
    print("\n  Features from RAW landmarks (actual pixel coordinates):")
    for k, v in features_raw.items():
        print(f"    {k}: {v:.4f}")

    # Classify with aligned
    engine_aligned = ClinicalInterpretationEngine(features_aligned)
    result_aligned = engine_aligned.classify()
    print(f"\n  ALIGNED -> Severity: {result_aligned['severity']}, Issues: {result_aligned.get('issue_count', '?')}")

    # Classify with raw
    engine_raw = ClinicalInterpretationEngine(features_raw)
    result_raw = engine_raw.classify()
    print(f"  RAW    -> Severity: {result_raw['severity']}, Issues: {result_raw.get('issue_count', '?')}")
    break
