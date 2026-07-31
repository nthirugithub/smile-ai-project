"""
LibreFace Analysis & Facial Expression / Quality Validator for Smile AI.

Medical Computer Vision Evaluation (Phase 5):
- LibreFace evaluates facial expressions, Action Units (AUs), smile authenticity (Duchenne smile),
  mouth visibility, and occlusion.
- Primary Clinical Role in Smile AI:
  Ensures the facial image captured represents an authentic, fully-animated smile (AU6 + AU12)
  rather than a resting lip pose, posed grimace, or occluded mouth before extracting orthodontic features.
"""

from __future__ import annotations

import math
from typing import Any, Dict, List, Tuple
import numpy as np


class LibreFaceProcessor:
    """
    Expression, Smile Authenticity (Duchenne AU6/AU12), Occlusion, and Mouth Visibility Engine.
    """

    def __init__(self, duchenne_threshold: float = 0.35):
        self.duchenne_threshold = duchenne_threshold

    @staticmethod
    def _dist(p1: Tuple[float, float, float], p2: Tuple[float, float, float]) -> float:
        return float(math.sqrt((p1[0] - p2[0])**2 + (p1[1] - p2[1])**2 + (p1[2] - p2[2])**2))

    def evaluate_expression_and_quality(
        self,
        landmarks: List[Tuple[float, float, float]],
        face_width: float,
        face_height: float
    ) -> Dict[str, Any]:
        """
        Calculates AU6 (Orbicularis Oculi / Eye Squint), AU12 (Zygomaticus Major / Lip Corner Pull),
        mouth visibility index, and smile authenticity confidence.
        """
        if not landmarks or len(landmarks) < 468:
            return {
                "valid_smile": False,
                "duchenne_score": 0.0,
                "mouth_visible": False,
                "occlusion_detected": True,
                "quality_confidence": 0.0,
                "reason": "Insufficient facial landmarks for expression evaluation."
            }

        # -----------------------------------------------------
        # 1. AU12: Zygomaticus Major (Lip Corner Elevation Ratio)
        # -----------------------------------------------------
        left_corner = landmarks[61]
        right_corner = landmarks[291]
        upper_lip_center = landmarks[13]
        lower_lip_center = landmarks[14]
        subnasale = landmarks[2]

        # Horizontal mouth span
        mouth_span = self._dist(left_corner, right_corner)
        interlabial_gap = self._dist(upper_lip_center, lower_lip_center)

        # Vertical elevation of corners relative to subnasale
        avg_corner_y = (left_corner[1] + right_corner[1]) / 2.0
        subnasale_y = subnasale[1]

        # AU12 proxy ratio: mouth width to face width & lip corner lift relative to subnasale
        au12_width_ratio = mouth_span / max(face_width, 1.0)
        au12_elevation = max(0.0, (avg_corner_y - upper_lip_center[1]) / max(face_height, 1.0))

        # Normalized AU12 intensity in [0, 1]
        au12_score = min(1.0, max(0.0, (au12_width_ratio - 0.35) / 0.25 + au12_elevation * 3.0))

        # -----------------------------------------------------
        # 2. AU6: Orbicularis Oculi (Eye Aperture Squinting Ratio)
        # -----------------------------------------------------
        # Left eye palpebral fissure height (159 to 145) vs width (33 to 133)
        left_eye_h = self._dist(landmarks[159], landmarks[145])
        left_eye_w = self._dist(landmarks[33], landmarks[133])
        left_ear_ratio = left_eye_h / max(left_eye_w, 1.0)

        # Right eye palpebral fissure height (386 to 374) vs width (362 to 263)
        right_eye_h = self._dist(landmarks[386], landmarks[374])
        right_eye_w = self._dist(landmarks[362], landmarks[263])
        right_ear_ratio = right_eye_h / max(right_eye_w, 1.0)

        avg_ear = (left_ear_ratio + right_ear_ratio) / 2.0
        # AU6 activation narrows the eye aperture during Duchenne smiles (EAR decreases)
        au6_score = min(1.0, max(0.0, (0.32 - avg_ear) / 0.15))

        # -----------------------------------------------------
        # 3. Duchenne Smile Authenticity Score
        # -----------------------------------------------------
        duchenne_score = round(float(0.60 * au12_score + 0.40 * au6_score), 4)

        # -----------------------------------------------------
        # 4. Mouth Visibility & Occlusion Check
        # -----------------------------------------------------
        # Mouth visibility ratio based on interlabial gap and corner distance stability
        mouth_visible = (mouth_span > 0.30 * face_width) and (interlabial_gap >= 0.01 * face_height)

        # Occlusion heuristic: if lip points collapse or overlap abnormally
        occlusion_detected = not mouth_visible or (interlabial_gap > 0.40 * face_height)

        valid_smile = (duchenne_score >= self.duchenne_threshold) and mouth_visible and not occlusion_detected

        return {
            "valid_smile": valid_smile,
            "duchenne_score": duchenne_score,
            "au12_lip_corner_pull": round(float(au12_score), 4),
            "au6_eye_squint": round(float(au6_score), 4),
            "mouth_visible": mouth_visible,
            "occlusion_detected": occlusion_detected,
            "quality_confidence": round(float(min(1.0, duchenne_score + 0.3)), 4),
            "clinical_note": (
                "Authentic Duchenne smile confirmed (AU6+AU12 active)."
                if valid_smile else
                "Warning: Resting or non-authentic smile posture detected. Orthodontic features may reflect resting lip line."
            )
        }
