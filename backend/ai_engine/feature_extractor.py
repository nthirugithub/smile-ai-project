from __future__ import annotations

import math
from typing import Dict, Iterable, List, Optional, Tuple

try:
    import cv2
except ImportError:  # optional, only needed for debug overlays
    cv2 = None


Landmark = Tuple[float, float, float]


class FeatureExtractor:
    """
    MediaPipe FaceMesh-based orthodontic smile feature extractor.

    All returned features are normalized ratios, not raw pixel distances.
    That makes them more stable across image size, camera distance, and scaling.

    NOTE:
    - gingival_display here is a proxy derived from lip geometry because
      FaceMesh does not directly detect teeth/gum boundaries.
    - Re-train your model after replacing this file.
    """

    # MediaPipe FaceMesh landmark indices commonly used in smile analysis
    FOREHEAD = 10
    NOSE_TIP = 1
    CHIN = 152

    LEFT_FACE = 234
    RIGHT_FACE = 454

    LEFT_MOUTH_CORNER = 61
    RIGHT_MOUTH_CORNER = 291

    UPPER_LIP_CENTER = 13
    LOWER_LIP_CENTER = 14

    # Proxy points for a gum-display style measurement
    UPPER_LIP_PROXY_A = 13
    UPPER_LIP_PROXY_B = 12

    def __init__(self, landmarks: List[Landmark]):
        if not landmarks or len(landmarks) <= self.RIGHT_FACE:
            raise ValueError(
                "Expected MediaPipe FaceMesh landmarks as a list with at least 455 points."
            )
        self.landmarks = landmarks
        self._face_width: Optional[float] = None
        self._face_height: Optional[float] = None

    # -----------------------------
    # Core helpers
    # -----------------------------
    def _pt(self, idx: int) -> Landmark:
        return self.landmarks[idx]

    def _xy(self, idx: int) -> Tuple[float, float]:
        x, y, _ = self.landmarks[idx]
        return float(x), float(y)

    def distance(self, p1: int, p2: int) -> float:
        x1, y1 = self._xy(p1)
        x2, y2 = self._xy(p2)
        return math.hypot(x2 - x1, y2 - y1)

    @staticmethod
    def _safe_div(numerator: float, denominator: float, default: float = 0.0) -> float:
        if denominator == 0 or math.isclose(denominator, 0.0):
            return default
        return numerator / denominator

    @staticmethod
    def _clamp(value: float, low: float = 0.0, high: float = 1.0) -> float:
        return max(low, min(high, value))

    def _face_width_px(self) -> float:
        if self._face_width is None:
            self._face_width = self.distance(self.LEFT_FACE, self.RIGHT_FACE)
        return self._face_width

    def _face_height_px(self) -> float:
        if self._face_height is None:
            self._face_height = self.distance(self.FOREHEAD, self.CHIN)
        return self._face_height

    @staticmethod
    def _point_to_line_distance(
        point: Tuple[float, float],
        line_a: Tuple[float, float],
        line_b: Tuple[float, float],
    ) -> float:
        """
        Perpendicular distance from a point to a line AB.
        """
        px, py = point
        ax, ay = line_a
        bx, by = line_b

        dx = bx - ax
        dy = by - ay

        if math.isclose(dx, 0.0) and math.isclose(dy, 0.0):
            return math.hypot(px - ax, py - ay)

        numerator = abs(dy * px - dx * py + bx * ay - by * ax)
        denominator = math.hypot(dx, dy)
        return numerator / denominator

    def _normalize_by_face_width(self, value: float) -> float:
        return self._safe_div(value, self._face_width_px(), 0.0)

    def _normalize_by_face_height(self, value: float) -> float:
        return self._safe_div(value, self._face_height_px(), 0.0)

    # -----------------------------
    # Feature 1: Smile width
    # -----------------------------
    def calculate_smile_width(self) -> float:
        """
        Normalized smile width = mouth-corner distance / face width
        """
        width_px = self.distance(self.LEFT_MOUTH_CORNER, self.RIGHT_MOUTH_CORNER)
        return round(self._normalize_by_face_width(width_px), 4)

    # -----------------------------
    # Feature 2: Lip opening
    # -----------------------------
    def calculate_lip_opening(self) -> float:
        """
        Normalized lip opening = upper-lower lip distance / face height
        """
        opening_px = self.distance(self.UPPER_LIP_CENTER, self.LOWER_LIP_CENTER)
        return round(self._normalize_by_face_height(opening_px), 4)

    # -----------------------------
    # Feature 3: Face ratio
    # -----------------------------
    def calculate_face_ratio(self) -> float:
        """
        Face width / face height (a classic facial proportion metric)
        """
        face_width = self._face_width_px()
        face_height = self._face_height_px()
        return round(self._safe_div(face_width, face_height, 0.0), 4)

    # -----------------------------
    # Feature 4: Midline deviation
    # -----------------------------
    def calculate_midline_deviation(self) -> float:
        """
        Distance from facial midline to nose tip, normalized by face width.

        Facial midline is approximated by the line connecting forehead (10) to chin (152).
        This is more robust than a raw x-coordinate difference.
        """
        nose = self._xy(self.NOSE_TIP)
        forehead = self._xy(self.FOREHEAD)
        chin = self._xy(self.CHIN)

        deviation_px = self._point_to_line_distance(nose, forehead, chin)
        return round(self._normalize_by_face_width(deviation_px), 4)

    # -----------------------------
    # Feature 5: Smile symmetry
    # -----------------------------
    def calculate_smile_symmetry(self) -> float:
        """
        Vertical corner-height difference, normalized by face height.
        Lower value = more symmetric.
        """
        _, y_left = self._xy(self.LEFT_MOUTH_CORNER)
        _, y_right = self._xy(self.RIGHT_MOUTH_CORNER)

        diff_px = abs(y_left - y_right)
        return round(self._normalize_by_face_height(diff_px), 4)

    # -----------------------------
    # Feature 6: Smile arc
    # -----------------------------
    def calculate_smile_arc(self) -> float:
        """
        Arc proxy = how much the mouth corners sit below/above the upper-lip center,
        normalized by face height.

        Positive value usually means corners are lower than the center point.
        """
        _, y_left = self._xy(self.LEFT_MOUTH_CORNER)
        _, y_right = self._xy(self.RIGHT_MOUTH_CORNER)
        _, y_upper = self._xy(self.UPPER_LIP_CENTER)

        avg_corner_y = (y_left + y_right) / 2.0
        arc_px = avg_corner_y - y_upper
        return round(self._normalize_by_face_height(arc_px), 4)

    # -----------------------------
    # Feature 7: Gingival display
    # -----------------------------
    def calculate_gingival_display(self) -> float:
        """
        Proxy gingival display feature.

        FaceMesh does not directly detect gum/teeth exposure, so this uses a small
        lip-geometry proxy normalized by face height.
        """
        proxy_px = self.distance(self.UPPER_LIP_PROXY_A, self.UPPER_LIP_PROXY_B)
        return round(self._normalize_by_face_height(proxy_px), 4)

    # -----------------------------
    # Feature 8: Buccal corridor
    # -----------------------------
    def calculate_buccal_corridor(self) -> float:
        """
        Buccal corridor proxy:
        larger smile width -> smaller visible side space.
        Normalized as 1 - smile_width_ratio.
        """
        smile_width_ratio = self.calculate_smile_width()
        corridor = 1.0 - smile_width_ratio
        return round(self._clamp(corridor, 0.0, 1.0), 4)

    # -----------------------------
    # Optional quality score
    # -----------------------------
    def calculate_quality_score(self) -> float:
        """
        Simple geometry-based quality score in [0, 1].
        You can use this later to reject extreme profiles / bad frames.
        """
        face_ratio = self.calculate_face_ratio()

        # A very rough quality heuristic:
        # faces that are extremely distorted in framing often have odd ratios.
        ratio_score = 1.0 - min(abs(face_ratio - 0.75), 0.75) / 0.75

        # Midline and smile symmetry should not be absurdly large
        midline = self.calculate_midline_deviation()
        symmetry = self.calculate_smile_symmetry()

        geometry_score = 1.0 - min((midline + symmetry) / 0.50, 1.0)

        score = 0.6 * ratio_score + 0.4 * geometry_score
        return round(self._clamp(score, 0.0, 1.0), 4)

    # -----------------------------
    # Main output
    # -----------------------------
    def extract_all_features(self) -> Dict[str, float]:
        return {
            # Keep these keys stable for downstream training/prediction
            "smile_width": self.calculate_smile_width(),
            "lip_opening": self.calculate_lip_opening(),
            "face_ratio": self.calculate_face_ratio(),
            "midline_deviation": self.calculate_midline_deviation(),
            "smile_symmetry": self.calculate_smile_symmetry(),
            "smile_arc": self.calculate_smile_arc(),
            "gingival_display": self.calculate_gingival_display(),
            "buccal_corridor": self.calculate_buccal_corridor(),
            # Useful for filtering/debugging
            "quality_score": self.calculate_quality_score(),
        }

    # -----------------------------
    # Visual debugging overlay
    # -----------------------------
    def draw_debug_overlay(self, image):
        """
        Draws measurement lines on an image for sanity-checking.
        Requires OpenCV.
        """
        if cv2 is None:
            raise ImportError("OpenCV (cv2) is required for draw_debug_overlay().")

        if image is None:
            return None

        h, w = image.shape[:2]

        def to_int_xy(idx: int) -> Tuple[int, int]:
            x, y = self._xy(idx)
            return int(round(x)), int(round(y))

        def draw_point(idx: int, color=(0, 255, 0), radius: int = 3):
            x, y = to_int_xy(idx)
            cv2.circle(image, (x, y), radius, color, -1)

        def draw_line(a: int, b: int, color=(255, 0, 0), thickness: int = 2):
            x1, y1 = to_int_xy(a)
            x2, y2 = to_int_xy(b)
            cv2.line(image, (x1, y1), (x2, y2), color, thickness)

        # Basic debug geometry
        draw_point(self.LEFT_MOUTH_CORNER)
        draw_point(self.RIGHT_MOUTH_CORNER)
        draw_point(self.UPPER_LIP_CENTER)
        draw_point(self.LOWER_LIP_CENTER)
        draw_point(self.NOSE_TIP)
        draw_point(self.FOREHEAD)
        draw_point(self.CHIN)

        draw_line(self.LEFT_MOUTH_CORNER, self.RIGHT_MOUTH_CORNER, (0, 255, 255), 2)
        draw_line(self.FOREHEAD, self.CHIN, (255, 0, 255), 2)
        draw_line(self.UPPER_LIP_CENTER, self.LOWER_LIP_CENTER, (0, 255, 0), 2)

        features = self.extract_all_features()
        y = 30
        for key in [
            "smile_width",
            "lip_opening",
            "face_ratio",
            "midline_deviation",
            "smile_symmetry",
            "smile_arc",
            "gingival_display",
            "buccal_corridor",
            "quality_score",
        ]:
            text = f"{key}: {features[key]:.4f}"
            cv2.putText(
                image,
                text,
                (20, y),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.55,
                (255, 255, 255),
                2,
                cv2.LINE_AA,
            )
            y += 22

        return image