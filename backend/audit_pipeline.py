"""
End-to-End Pipeline Audit Script
Tests ALL 102 doctor images through the complete pipeline and reports:
- Feature distribution across normal/mild/moderate/severe
- Overlay success rate
- Any errors or crashes
- Severity distribution for sanity check
"""
import cv2
import os
import sys
import math
import numpy as np
import traceback

sys.path.insert(0, ".")

from ai_engine.face_mesh_3d import FaceMesh3D
from ai_engine.feature_extractor import FeatureExtractor
from ai_engine.severity_classifier import ClinicalInterpretationEngine
from app import draw_smile_overlay

mesh_detector = FaceMesh3D()

import glob
images = sorted(glob.glob("raw_dataset/doctor_images/*.jpeg") + glob.glob("raw_dataset/doctor_images/*.jpg"))
print(f"\nFound {len(images)} images for end-to-end audit\n")

results = []
errors = []
no_face = []

for image_path in images:
    fname = os.path.basename(image_path)
    try:
        result = mesh_detector.process_image(image_path)
        if result is None:
            no_face.append(fname)
            continue

        raw_landmarks = result["raw_landmarks"]
        landmarks = result["landmarks"]
        img = result["image"].copy()
        quality = result["quality_score"]

        # Feature extraction (aligned, as in production)
        extractor = FeatureExtractor(landmarks)
        features = extractor.extract_all_features()

        # Severity classification
        engine = ClinicalInterpretationEngine(features)
        severity_result = engine.classify()
        severity = severity_result["severity"]
        score = severity_result["score"]

        # Overlay test
        overlay_ok = True
        try:
            overlay_img = draw_smile_overlay(img, raw_landmarks)
        except Exception as e:
            overlay_ok = False

        # Check for NaN/invalid features
        invalid_feats = [k for k, v in features.items()
                         if v is None or (isinstance(v, float) and (math.isnan(v) or math.isinf(v)))]

        results.append({
            "file": fname,
            "severity": severity,
            "score": score,
            "quality": quality,
            "overlay_ok": overlay_ok,
            "invalid_feats": invalid_feats,
            "smile_arc": features["smile_arc"],
            "midline": features["midline_deviation"],
            "gingival": features["gingival_display"],
            "lip_opening": features["lip_opening"],
            "smile_width": features["smile_width"],
        })

    except Exception as e:
        errors.append({"file": fname, "error": str(e), "trace": traceback.format_exc()})

print(f"{'='*60}")
print(f"  END-TO-END AUDIT RESULTS")
print(f"{'='*60}")
print(f"  Total images        : {len(images)}")
print(f"  Successfully processed: {len(results)}")
print(f"  No face detected    : {len(no_face)}")
print(f"  Errors              : {len(errors)}")
print()

# Severity distribution
from collections import Counter
sev_dist = Counter(r["severity"] for r in results)
print(f"{'='*60}")
print(f"  SEVERITY DISTRIBUTION")
print(f"{'='*60}")
for sev in ["Normal", "Mild", "Moderate", "Severe"]:
    count = sev_dist.get(sev, 0)
    pct = count / len(results) * 100 if results else 0
    bar = "#" * int(pct / 2)
    print(f"  {sev:<10}: {count:>3} ({pct:5.1f}%) {bar}")


# Overlay success rate
overlay_ok_count = sum(1 for r in results if r["overlay_ok"])
print(f"\n  Overlay success rate : {overlay_ok_count}/{len(results)} ({overlay_ok_count/len(results)*100:.1f}%)")

# Invalid features check
invalid_any = [r for r in results if r["invalid_feats"]]
print(f"  Invalid features     : {len(invalid_any)} images")

# Feature range summary
if results:
    print(f"\n{'='*60}")
    print(f"  FEATURE VALUE RANGES (min / mean / max)")
    print(f"{'='*60}")
    for feat in ["smile_arc", "midline", "gingival", "lip_opening", "smile_width"]:
        vals = [r[feat] for r in results]
        print(f"  {feat:<14}: min={min(vals):.4f}  mean={sum(vals)/len(vals):.4f}  max={max(vals):.4f}")

# Score distribution
if results:
    scores = [r["score"] for r in results]
    print(f"\n  Penalty score range : min={min(scores):.1f}  mean={sum(scores)/len(scores):.1f}  max={max(scores):.1f}")

# Normal smile sanity check
normal_cases = [r for r in results if r["severity"] == "Normal"]
if normal_cases:
    print(f"\n  Normal cases sample (first 3):")
    for r in normal_cases[:3]:
        print(f"    {r['file']}: arc={r['smile_arc']:.3f} mid={r['midline']:.3f} ging={r['gingival']:.3f} lip={r['lip_opening']:.3f} score={r['score']:.1f}")

# Errors
if errors:
    print(f"\n{'='*60}")
    print(f"  ERRORS")
    print(f"{'='*60}")
    for e in errors[:5]:
        print(f"  {e['file']}: {e['error']}")
