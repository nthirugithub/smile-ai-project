"""
3D Face Mesh Extraction, Head Pose Estimation, 3D Alignment, & Quality Scoring Engine.

Upgrades:
- EXIF Orientation Auto-Rotation (corrects smartphone portrait upside-down photos).
- MediaPipe 478 3D Refined Facial Mesh (refine_landmarks=True).
- OpenCV SolvePnP 3D Head Pose Estimation (Yaw, Pitch, Roll).
- 3D Rigid Rotation Matrix Normalization.
- Multi-Factor Image Quality Validation (Blur, Brightness/Illumination, Pose Thresholds).
- Integration with RetinaFace and LibreFace processors.
"""

from __future__ import annotations

import math
import os
from typing import Any, Dict, List, Optional, Tuple
import cv2
import mediapipe as mp
import numpy as np

from ai_engine.libreface_processor import LibreFaceProcessor
from ai_engine.retinaface_processor import RetinaFaceProcessor


class FaceMesh3D:

    # 3D Canonical Face Model Points for PnP Pose Estimation
    # Nose tip (1), Chin (152), Left eye corner (33), Right eye corner (263),
    # Left mouth corner (61), Right mouth corner (291)
    CANONICAL_3D_POINTS = np.array([
        (0.0, 0.0, 0.0),           # Nose tip
        (0.0, -330.0, -65.0),      # Chin
        (-225.0, 170.0, -135.0),   # Left eye left corner
        (225.0, 170.0, -135.0),    # Right eye right corner
        (-150.0, -150.0, -125.0),  # Left mouth corner
        (150.0, -150.0, -125.0)    # Right mouth corner
    ], dtype=np.float64)

    LANDMARK_PNP_INDICES = [1, 152, 33, 263, 61, 291]

    def __init__(self):
        self.mp_face_mesh = mp.solutions.face_mesh
        self.face_mesh = self.mp_face_mesh.FaceMesh(
            static_image_mode=True,
            max_num_faces=1,
            refine_landmarks=True,
            min_detection_confidence=0.7,
            min_tracking_confidence=0.7
        )
        self.mp_drawing = mp.solutions.drawing_utils
        self.drawing_spec = self.mp_drawing.DrawingSpec(
            thickness=1,
            circle_radius=1
        )
        self.retinaface_evaluator = RetinaFaceProcessor()
        self.libreface_evaluator = LibreFaceProcessor()

    @staticmethod
    def fix_exif_orientation(image_path: str, image: np.ndarray) -> np.ndarray:
        """Fixes image rotation using EXIF orientation tags from smartphone cameras."""
        try:
            from PIL import Image, ImageOps
            pil_img = Image.open(image_path)
            pil_img = ImageOps.exif_transpose(pil_img)
            return cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGB2BGR)
        except Exception:
            return image

    # =================================================
    # IMAGE QUALITY CHECKS
    # =================================================

    def calculate_blur_score(self, image: np.ndarray) -> float:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        return float(cv2.Laplacian(gray, cv2.CV_64F).var())

    def calculate_brightness(self, image: np.ndarray) -> float:
        hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
        brightness = float(hsv[..., 2].mean())
        return brightness

    def calculate_illumination_uniformity(self, image: np.ndarray) -> float:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        h, w = gray.shape
        left_half = gray[:, :w//2]
        right_half = gray[:, w//2:]
        left_mean = float(np.mean(left_half))
        right_mean = float(np.mean(right_half))
        diff = abs(left_mean - right_mean)
        uniformity = max(0.0, 1.0 - (diff / 128.0))
        return round(uniformity, 4)

    # =================================================
    # 3D POSE ESTIMATION & RIGID ALIGNMENT
    # =================================================

    def estimate_3d_head_pose(
        self,
        landmark_points: List[Tuple[float, float, float]],
        width: int,
        height: int
    ) -> Dict[str, Any]:

        image_points = []
        for idx in self.LANDMARK_PNP_INDICES:
            pt = landmark_points[idx]
            image_points.append([pt[0], pt[1]])

        image_points = np.array(image_points, dtype=np.float64)

        focal_length = width
        center = (width / 2.0, height / 2.0)
        camera_matrix = np.array([
            [focal_length, 0, center[0]],
            [0, focal_length, center[1]],
            [0, 0, 1]
        ], dtype=np.float64)

        dist_coeffs = np.zeros((4, 1), dtype=np.float64)

        success, rvec, tvec = cv2.solvePnP(
            self.CANONICAL_3D_POINTS,
            image_points,
            camera_matrix,
            dist_coeffs,
            flags=cv2.SOLVEPNP_ITERATIVE
        )

        if not success:
            return {
                "yaw": 0.0,
                "pitch": 0.0,
                "roll": 0.0,
                "rotation_matrix": np.identity(3),
                "translation_vector": np.zeros((3, 1))
            }

        R, _ = cv2.Rodrigues(rvec)

        sy = math.sqrt(R[0, 0] * R[0, 0] + R[1, 0] * R[1, 0])
        singular = sy < 1e-6

        if not singular:
            pitch = math.atan2(R[2, 1], R[2, 2])
            yaw = math.atan2(-R[2, 0], sy)
            roll = math.atan2(R[1, 0], R[0, 0])
        else:
            pitch = math.atan2(-R[1, 2], R[1, 1])
            yaw = math.atan2(-R[2, 0], sy)
            roll = 0.0

        yaw_deg = round(math.degrees(yaw), 2)
        pitch_deg_raw = round(math.degrees(pitch), 2)
        roll_deg = round(math.degrees(roll), 2)

        # -----------------------------------------------------------------
        # Pitch Normalization:
        # The ZYX Euler decomposition from the solvePnP rotation matrix
        # produces pitch ≈ ±180° for naturally upright (frontal) faces,
        # because the OpenCV camera frame is oriented such that the face's
        # rest pose has a pitch offset of π radians.
        # We normalize to a "deviation-from-frontal" value centred at 0°
        # so the ±25° pose rejection threshold works as clinically intended.
        # Reference: Lepetit et al. (2009), solvePnP documentation.
        # -----------------------------------------------------------------
        if pitch_deg_raw > 90.0:
            pitch_deg = pitch_deg_raw - 180.0
        elif pitch_deg_raw < -90.0:
            pitch_deg = pitch_deg_raw + 180.0
        else:
            pitch_deg = pitch_deg_raw
        pitch_deg = round(pitch_deg, 2)

        return {
            "yaw": yaw_deg,
            "pitch": pitch_deg,
            "roll": roll_deg,
            "rotation_matrix": R,
            "translation_vector": tvec
        }

    def align_landmarks_3d(
        self,
        landmark_points: List[Tuple[float, float, float]],
        rotation_matrix: np.ndarray
    ) -> List[Tuple[float, float, float]]:
        R_inv = rotation_matrix.T
        aligned_pts = []
        pts_np = np.array(landmark_points, dtype=np.float64)

        nose_center = pts_np[1].copy()
        centered_pts = pts_np - nose_center

        aligned_np = np.dot(centered_pts, R_inv.T) + nose_center

        for pt in aligned_np:
            aligned_pts.append((float(pt[0]), float(pt[1]), float(pt[2])))

        return aligned_pts

    # =================================================
    # FACE SIZE ESTIMATION
    # =================================================

    def estimate_face_size(
        self,
        landmarks: Any,
        width: int,
        height: int
    ) -> float:
        xs = [int(lm.x * width) for lm in landmarks.landmark]
        ys = [int(lm.y * height) for lm in landmarks.landmark]
        face_width = max(xs) - min(xs)
        face_height = max(ys) - min(ys)
        return float(face_width * face_height)

    def estimate_head_tilt(
        self,
        landmark_points: List[Tuple[float, float, float]]
    ) -> float:
        left_eye = landmark_points[33]
        right_eye = landmark_points[263]
        dx = right_eye[0] - left_eye[0]
        dy = right_eye[1] - left_eye[1]
        angle = math.degrees(math.atan2(dy, dx))
        return round(angle, 2)

    # =================================================
    # MAIN PROCESSING
    # =================================================

    def process_image(self, image_path: str) -> Optional[Dict[str, Any]]:

        if not os.path.exists(image_path):
            print("Image path not found")
            return None

        raw_image = cv2.imread(image_path)
        if raw_image is None:
            print("Failed to load image")
            return None

        # Fix EXIF orientation auto-rotation
        image = self.fix_exif_orientation(image_path, raw_image)
        h, w, c = image.shape

        # ---------------------------------------------
        # IMAGE QUALITY CHECKS
        # ---------------------------------------------
        blur_score = self.calculate_blur_score(image)
        brightness = self.calculate_brightness(image)
        illumination_uniformity = self.calculate_illumination_uniformity(image)

        # CLAHE Image enhancement for robust landmark detection
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        enhanced_gray = clahe.apply(gray)
        enhanced_bgr = cv2.cvtColor(enhanced_gray, cv2.COLOR_GRAY2BGR)
        rgb_image = cv2.cvtColor(enhanced_bgr, cv2.COLOR_BGR2RGB)

        # ---------------------------------------------
        # MEDIAPIPE PROCESSING
        # ---------------------------------------------
        results = self.face_mesh.process(rgb_image)

        # Evaluate RetinaFace fallback if MediaPipe fails
        retinaface_eval = self.retinaface_evaluator.evaluate_face_detection(
            image_np=image,
            mediapipe_detected=bool(results and results.multi_face_landmarks),
            mediapipe_confidence=1.0 if (results and results.multi_face_landmarks) else 0.0
        )

        if not results or not results.multi_face_landmarks:
            print("No face detected by MediaPipe")
            return None

        # Select largest face
        largest_face = None
        largest_size = 0.0
        for face_landmarks in results.multi_face_landmarks:
            size = self.estimate_face_size(face_landmarks, w, h)
            if size > largest_size:
                largest_size = size
                largest_face = face_landmarks

        face_landmarks = largest_face

        # ---------------------------------------------
        # LANDMARK EXTRACTION (3D Normalized & Pixel)
        # ---------------------------------------------
        landmark_points: List[Tuple[float, float, float]] = []
        for landmark in face_landmarks.landmark:
            x = float(landmark.x * w)
            y = float(landmark.y * h)
            z = float(landmark.z * w)
            landmark_points.append((x, y, z))

        # ---------------------------------------------
        # 3D HEAD POSE ESTIMATION & ALIGNMENT
        # ---------------------------------------------
        pose_info = self.estimate_3d_head_pose(landmark_points, w, h)
        head_tilt = self.estimate_head_tilt(landmark_points)

        yaw = pose_info["yaw"]
        pitch = pose_info["pitch"]
        roll = pose_info["roll"]

        # -----------------------------------------------------------------
        # Pose Gate: Reject images with extreme head orientation.
        # Thresholds are based on the clinically validated frontal-view
        # acquisition protocol (Ackerman et al. 2004, Andrews 1972).
        # Yaw/Roll: ±25° | Pitch (normalized): ±30°
        # Pitch is wider (±30°) to allow slight chin-up/down variation
        # typical in intra-oral photography (Schabel et al. 2010).
        # -----------------------------------------------------------------
        if abs(yaw) > 25.0 or abs(pitch) > 30.0 or abs(roll) > 25.0:
            print(f"Extreme head pose rejected: Yaw={yaw}, Pitch={pitch}, Roll={roll}")
            return None

        # 3D Pose Normalization Matrix Transformation
        aligned_landmarks = self.align_landmarks_3d(
            landmark_points,
            pose_info["rotation_matrix"]
        )

        # ---------------------------------------------
        # FACE SIZE VALIDATION
        # ---------------------------------------------
        if largest_size < 40000:
            print("Face too small for reliable clinical analysis")
            return None

        # ---------------------------------------------
        # LIBREFACE EXPRESSION & AUTHENTICITY VALIDATION
        # ---------------------------------------------
        face_w_px = abs(landmark_points[454][0] - landmark_points[234][0])
        face_h_px = abs(landmark_points[152][1] - landmark_points[10][1])
        expression_eval = self.libreface_evaluator.evaluate_expression_and_quality(
            landmarks=landmark_points,
            face_width=face_w_px,
            face_height=face_h_px
        )

        # ---------------------------------------------
        # COMPOSITE QUALITY SCORE
        # ---------------------------------------------
        blur_quality = min(blur_score / 200.0, 1.0)
        brightness_quality = 1.0 if brightness >= 70 else (0.7 if brightness >= 40 else 0.4)
        pose_quality = max(0.0, 1.0 - (abs(yaw) + abs(pitch) + abs(roll)) / 75.0)

        quality_score = (
            0.35 * blur_quality +
            0.25 * brightness_quality +
            0.20 * pose_quality +
            0.20 * expression_eval["quality_confidence"]
        )
        quality_score = round(float(min(max(quality_score, 0.0), 1.0)), 4)

        # ---------------------------------------------
        # DRAW ANNOTATED MESH OVERLAY
        # ---------------------------------------------
        mesh_image = image.copy()
        self.mp_drawing.draw_landmarks(
            image=mesh_image,
            landmark_list=face_landmarks,
            connections=self.mp_face_mesh.FACEMESH_TESSELATION,
            landmark_drawing_spec=None,
            connection_drawing_spec=self.drawing_spec
        )

        cv2.putText(
            mesh_image,
            f"Quality: {quality_score:.2f} | Pose Yaw: {yaw:.1f} P: {pitch:.1f} R: {roll:.1f}",
            (20, 40),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.7,
            (0, 255, 0),
            2
        )

        output_path = f"reports/mesh_output_{os.getpid()}.jpg"
        os.makedirs("reports", exist_ok=True)
        cv2.imwrite(output_path, mesh_image)

        return {
            "image": image,
            "mesh_image": mesh_image,
            "landmarks": aligned_landmarks,
            "raw_landmarks": landmark_points,
            "output_path": output_path,
            "quality_score": quality_score,
            "blur_score": round(float(blur_score), 2),
            "brightness": round(float(brightness), 2),
            "head_tilt": head_tilt,
            "pose_yaw": yaw,
            "pose_pitch": pitch,
            "pose_roll": roll,
            "face_area": int(largest_size),
            "retinaface_eval": retinaface_eval,
            "expression_eval": expression_eval
        }