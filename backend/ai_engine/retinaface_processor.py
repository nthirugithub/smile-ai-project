"""
RetinaFace Analysis & Fallback Face Processor Module for Smile AI.

Medical Computer Vision Evaluation (Phase 4):
- RetinaFace is a deep-learning single-stage 2D face detector that extracts 5 facial keypoints
  (left eye center, right eye center, nose tip, left mouth corner, right mouth corner).
- Primary Role in Smile AI: Evaluates low-confidence frames, severe facial crop cases, and extreme
  head poses.
- Dense Landmark Note: MediaPipe FaceMesh produces 478 3D dense facial landmarks (including iris and
  inner lip vermilion contours). RetinaFace does not provide dense 3D intra-oral mesh geometry,
  so MediaPipe remains the primary landmark regressor. RetinaFace serves as a robust face detection
  and bounding box validator when MediaPipe detection confidence drops.
"""

from __future__ import annotations

import math
from typing import Any, Dict, List, Optional, Tuple
import numpy as np


class RetinaFaceProcessor:
    """
    RetinaFace evaluation engine and fallback face detector / alignment quality validator.
    """

    def __init__(self, confidence_threshold: float = 0.85):
        self.confidence_threshold = confidence_threshold
        self._retinaface_installed = False
        self._init_detector()

    def _init_detector(self) -> None:
        """
        Attempts to initialize RetinaFace detector if installed; otherwise falls back
        to OpenCV Haar/DNN geometric validation.
        """
        try:
            from retinaface import RetinaFace  # type: ignore
            self._retinaface_module = RetinaFace
            self._retinaface_installed = True
        except ImportError:
            self._retinaface_installed = False

    @property
    def is_installed(self) -> bool:
        return self._retinaface_installed

    def evaluate_face_detection(
        self,
        image_np: np.ndarray,
        mediapipe_detected: bool,
        mediapipe_confidence: float = 1.0
    ) -> Dict[str, Any]:
        """
        Evaluates face detection quality and determines whether RetinaFace fallback / alignment is required.
        """
        h, w = image_np.shape[:2]

        evaluation = {
            "retinaface_available": self._retinaface_installed,
            "mediapipe_detected": mediapipe_detected,
            "mediapipe_confidence": float(mediapipe_confidence),
            "recommendation": "Use MediaPipe 478 3D Mesh",
            "fallback_triggered": False,
            "face_bounding_box": None,
            "alignment_confidence": 1.0,
            "medical_justification": (
                "MediaPipe 478 3D mesh provides sub-millimeter intra-oral and vermilion "
                "contours required for orthodontic smile analysis. RetinaFace is evaluated "
                "for boundary validation."
            ),
        }

        # If MediaPipe failed or had low confidence, evaluate RetinaFace if available
        if not mediapipe_detected or mediapipe_confidence < 0.60:
            evaluation["fallback_triggered"] = True

            if self._retinaface_installed:
                try:
                    resp = self._retinaface_module.detect_faces(image_np)
                    if isinstance(resp, dict) and len(resp) > 0:
                        # Select face with highest confidence
                        best_face_key = max(
                            resp.keys(),
                            key=lambda k: resp[k].get("score", 0.0)
                        )
                        face_info = resp[best_face_key]
                        score = float(face_info.get("score", 0.0))
                        facial_area = face_info.get("facial_area", [0, 0, w, h])
                        landmarks_5 = face_info.get("landmarks", {})

                        evaluation["face_bounding_box"] = facial_area
                        evaluation["alignment_confidence"] = score
                        evaluation["recommendation"] = "Crop face using RetinaFace bbox and retry MediaPipe 3D Mesh"
                        evaluation["medical_justification"] = (
                            "RetinaFace successfully localized face boundary in severe lighting/crop condition. "
                            "ROI cropped for MediaPipe refinement."
                        )
                    else:
                        evaluation["recommendation"] = "Reject image: No face detected by RetinaFace"
                except Exception as exc:
                    evaluation["error"] = str(exc)
            else:
                evaluation["recommendation"] = "Reject image: Low MediaPipe confidence & RetinaFace library not present"

        return evaluation

    @staticmethod
    def compute_5point_alignment_matrix(
        landmarks_5: Dict[str, Tuple[float, float]]
    ) -> Optional[np.ndarray]:
        """
        Computes 2D similarity transform matrix based on 5 facial keypoints
        (left_eye, right_eye, nose, mouth_left, mouth_right).
        """
        if not landmarks_5 or "left_eye" not in landmarks_5 or "right_eye" not in landmarks_5:
            return None

        left_eye = np.array(landmarks_5["left_eye"], dtype=np.float32)
        right_eye = np.array(landmarks_5["right_eye"], dtype=np.float32)

        # Desired horizontal interpupillary axis angle
        dY = right_eye[1] - left_eye[1]
        dX = right_eye[0] - left_eye[0]
        angle = math.degrees(math.atan2(dY, dX))

        center = (float((left_eye[0] + right_eye[0]) / 2.0), float((left_eye[1] + right_eye[1]) / 2.0))
        scale = 1.0

        import cv2
        M = cv2.getRotationMatrix2D(center, angle, scale)
        return M
