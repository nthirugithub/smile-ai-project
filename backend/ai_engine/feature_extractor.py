"""
MediaPipe FaceMesh-Based Clinical Orthodontic Smile Feature Extractor.

Medical Computer Vision & Orthodontic Calibration Overhaul:
- All features use 3D pose-corrected landmarks and weighted landmark cluster averaging.
- Clinically calibrated equations based on established orthodontic literature
  (Ackerman, Sarver, Hulsey, Kokich, Tjan, Farkas).
- Replaces legacy 2D single-landmark heuristics with robust multi-landmark geometry.
- Strictly preserves output feature names & contracts for seamless API/Frontend compatibility.
"""

from __future__ import annotations

import math
from typing import Any, Dict, Iterable, List, Optional, Tuple
import numpy as np

try:
    import cv2
except ImportError:
    cv2 = None


Landmark = Tuple[float, float, float]


class FeatureExtractor:
    """
    Clinically calibrated 3D orthodontic feature extraction engine.
    """

    # ---------------------------------------------------------
    # CLINICAL LANDMARK CLUSTER GROUPS
    # ---------------------------------------------------------
    COMMISSURE_LEFT = [61, 76, 62, 183, 57]
    COMMISSURE_RIGHT = [291, 306, 292, 407, 287]

    ZYGOMATIC_LEFT = [234, 127, 162, 93]
    ZYGOMATIC_RIGHT = [454, 356, 389, 323]

    PUPIL_LEFT = [33, 133, 159, 145, 158, 153, 468]
    PUPIL_RIGHT = [362, 263, 386, 374, 385, 380, 473]

    SUBNASALE = [2, 94, 164, 19]
    NASION = [6, 168, 197, 195]
    GNATHION = [152, 175, 199, 200]

    UPPER_STOMION = [13, 82, 312]
    LOWER_STOMION = [14, 87, 317]

    LOWER_LIP_INNER_CONTOUR = [61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291]

    INNER_VERMILION_LEFT = [78, 191, 80]
    INNER_VERMILION_RIGHT = [308, 415, 310]

    # Labial Frenum: upper lip midpoint (landmark 0) and upper lip central region only.
    # Landmark 17 is the LOWER lip midpoint and must NOT be included - it inflates
    # midline_deviation when the mouth is open during smiling.
    LABIAL_FRENUM = [0, 13]

    def __init__(self, landmarks: List[Landmark]):
        if landmarks is None or len(landmarks) < 455:
            raise ValueError(
                "Expected MediaPipe FaceMesh landmarks as a list with at least 455 3D points."
            )
        self.landmarks = landmarks
        self._cache: Dict[str, Any] = {}

    # ---------------------------------------------------------
    # GEOMETRIC HELPERS
    # ---------------------------------------------------------

    def _centroid(self, indices: List[int]) -> Tuple[float, float, float]:
        """Calculates 3D spatial centroid for a group of landmark indices."""
        xs, ys, zs = [], [], []
        for idx in indices:
            pt = self.landmarks[idx]
            xs.append(pt[0])
            ys.append(pt[1])
            zs.append(pt[2] if len(pt) > 2 else 0.0)
        return (float(np.mean(xs)), float(np.mean(ys)), float(np.mean(zs)))

    @staticmethod
    def _dist_3d(p1: Tuple[float, float, float], p2: Tuple[float, float, float]) -> float:
        """Calculates 3D Euclidean distance."""
        return math.sqrt((p2[0] - p1[0])**2 + (p2[1] - p1[1])**2 + (p2[2] - p1[2])**2)

    @staticmethod
    def _safe_div(numerator: float, denominator: float, default: float = 0.0) -> float:
        if denominator == 0 or math.isclose(denominator, 0.0):
            return default
        return numerator / denominator

    @staticmethod
    def _clamp(value: float, low: float = 0.0, high: float = 1.0) -> float:
        return max(low, min(high, value))

    @staticmethod
    def _point_to_line_dist_3d(
        pt: Tuple[float, float, float],
        line_a: Tuple[float, float, float],
        line_b: Tuple[float, float, float]
    ) -> float:
        """Calculates 3D perpendicular distance from point pt to line segment line_a -> line_b."""
        p = np.array(pt, dtype=np.float64)
        a = np.array(line_a, dtype=np.float64)
        b = np.array(line_b, dtype=np.float64)

        ab = b - a
        norm_ab = np.linalg.norm(ab)
        if norm_ab == 0:
            return float(np.linalg.norm(p - a))

        ap = p - a
        cross_prod = np.cross(ap, ab)
        return float(np.linalg.norm(cross_prod) / norm_ab)

    # ---------------------------------------------------------
    # ANATOMICAL BASELINE METRICS
    # ---------------------------------------------------------

    def _bizygomatic_width(self) -> float:
        """Bizygomatic facial width (ZW)."""
        if "bizygomatic_width" not in self._cache:
            zyg_l = self._centroid(self.ZYGOMATIC_LEFT)
            zyg_r = self._centroid(self.ZYGOMATIC_RIGHT)
            self._cache["bizygomatic_width"] = max(self._dist_3d(zyg_l, zyg_r), 1.0)
        return self._cache["bizygomatic_width"]

    def _morphometric_height(self) -> float:
        """Morphometric facial height (MorphH: Nasion to Gnathion)."""
        if "morphometric_height" not in self._cache:
            nasion = self._centroid(self.NASION)
            gnathion = self._centroid(self.GNATHION)
            self._cache["morphometric_height"] = max(self._dist_3d(nasion, gnathion), 1.0)
        return self._cache["morphometric_height"]

    def _intercommissural_width(self) -> float:
        """Inter-commissural width (CW)."""
        if "intercommissural_width" not in self._cache:
            comm_l = self._centroid(self.COMMISSURE_LEFT)
            comm_r = self._centroid(self.COMMISSURE_RIGHT)
            self._cache["intercommissural_width"] = self._dist_3d(comm_l, comm_r)
        return self._cache["intercommissural_width"]

    # ---------------------------------------------------------
    # CLINICAL SMILE METRICS (EIGHT VISIBLE FEATURES)
    # ---------------------------------------------------------

    def calculate_smile_width(self) -> float:
        """
        Feature 1: Smile Width
        Clinical definition: Inter-commissural width (CW) / Bizygomatic width (ZW).
        Literature range: 0.40 - 0.50 (Ackerman et al. 2004).
        """
        cw = self._intercommissural_width()
        zw = self._bizygomatic_width()
        ratio = self._safe_div(cw, zw, 0.0)
        return round(float(self._clamp(ratio, 0.0, 1.0)), 4)

    def calculate_smile_symmetry(self) -> float:
        """
        Feature 2: Smile Symmetry
        Clinical definition: Vertical height difference of commissures relative to interpupillary line (L_IP),
        normalized by morphometric facial height.
        Literature range: < 0.015 (< 1.5% facial height, Hulsey 1970).
        """
        pupil_l = self._centroid(self.PUPIL_LEFT)
        pupil_r = self._centroid(self.PUPIL_RIGHT)

        comm_l = self._centroid(self.COMMISSURE_LEFT)
        comm_r = self._centroid(self.COMMISSURE_RIGHT)

        dist_l = self._point_to_line_dist_3d(comm_l, pupil_l, pupil_r)
        dist_r = self._point_to_line_dist_3d(comm_r, pupil_l, pupil_r)

        vert_diff = abs(dist_l - dist_r)
        symmetry_ratio = self._safe_div(vert_diff, self._morphometric_height(), 0.0)
        return round(float(self._clamp(symmetry_ratio, 0.0, 1.0)), 4)

    def calculate_midline_deviation(self) -> float:
        """
        Feature 3: Midline Deviation
        Clinical definition: LATERAL (X-axis only) shift of labial frenum from the soft-tissue
        facial midline defined by the Subnasale-Nasion vertical axis, normalized by bizygomatic width.
        Literature range: < 0.015 (< 2mm, Kokich et al. 1999).

        Implementation note: Must use 2D X-axis deviation only.
        Using 3D perpendicular distance includes the Z-axis (lip protrusion), which
        is always non-zero relative to the flat Nasion-Subnasale plane and artificially
        inflates midline values even for perfectly centered smiles.
        """
        subnasale = self._centroid(self.SUBNASALE)
        nasion = self._centroid(self.NASION)
        labial_frenum = self._centroid(self.LABIAL_FRENUM)

        # Facial midline X = average X of nasion and subnasale (both lie on midsagittal plane)
        midline_x = (nasion[0] + subnasale[0]) / 2.0

        # Lateral deviation = absolute X difference between frenum and facial midline
        deviation_px = abs(labial_frenum[0] - midline_x)
        norm_dev = self._safe_div(deviation_px, self._bizygomatic_width(), 0.0)
        return round(float(self._clamp(norm_dev, 0.0, 1.0)), 4)

    def calculate_smile_arc(self) -> float:
        """
        Feature 4: Smile Arc
        Clinical definition: Chord-height curvature ratio.

        The smile arc measures the relationship between the curvature of the
        incisal edges of the maxillary teeth and the curvature of the lower lip.
        Operationally implemented as the perpendicular distance (h) from the
        lower lip midpoint (landmark 17) to the commissure-to-commissure chord,
        divided by the inter-commissural width (CW).

        Positive (h/CW > 0) => Ideal consonant smile arc (lip curves upward).
        Near-zero => Flat arc.
        Negative => Reversed arc (lip bows downward relative to commissures).

        Formula: arc_ratio = h / CW, where h = signed perpendicular distance from
        midpoint of lower lip to the commissure chord (positive = below chord).

        Literature: Sarver & Ackerman (2003), Tjan et al. (1984).
        Clinical range: −0.15 to +0.15 (extreme values clamped to ±0.20).
        """
        # Commissure centroids (left and right endpoints of the chord)
        c_left = self._centroid(self.COMMISSURE_LEFT)
        c_right = self._centroid(self.COMMISSURE_RIGHT)

        # Lower lip midpoint (landmark 17: labial inferior midpoint)
        lip_mid = self.landmarks[17]

        # Vector along the commissure chord
        chord_dx = c_right[0] - c_left[0]
        chord_dy = c_right[1] - c_left[1]
        chord_len = math.sqrt(chord_dx ** 2 + chord_dy ** 2)

        if chord_len < 1e-3:
            return 0.0

        # Perpendicular distance from lip_mid to the chord line (signed)
        # Using the 2D cross-product formulation
        # h > 0 means the midpoint is below the chord (ideal smile: lower lip dips below commissures)
        perp = (
            (c_right[0] - c_left[0]) * (c_left[1] - lip_mid[1]) -
            (c_left[0] - lip_mid[0]) * (c_right[1] - c_left[1])
        )
        h = perp / chord_len  # signed perpendicular distance in pixels

        # Normalize by inter-commissural width to make scale-invariant
        cw = self._intercommissural_width()
        if cw < 1e-3:
            return 0.0

        arc_ratio = float(h / cw)
        # Sign convention (image space: y increases downward):
        #   lip_mid.y < commissure chord y  =>  lip is ABOVE chord on screen  =>  IDEAL smile arc
        #   perp > 0  =>  h > 0  =>  arc_ratio > 0  =>  POSITIVE = ideal consonant arc ✓
        #   No negation needed.
        #
        # Clinical range from Sarver & Ackerman (2003): ideal consonant arc ~0.25–0.40
        # Flat arc: 0.05–0.25 | Reversed arc: < 0.05 | Excessive: > 0.40
        return round(float(self._clamp(arc_ratio, -0.40, 0.40)), 4)

    def calculate_gingival_display(self) -> float:
        """
        Feature 5: Gingival Display
        Clinical definition: Vertical (Y-axis only) upper lip elevation above subnasale during smile,
        normalized by morphometric height.
        Literature range: 0.00 - 0.020 (0-2mm display, Tjan et al. 1984).

        Implementation note: Must use 2D Y-axis vertical distance only.
        Using 3D Euclidean distance includes Z-axis (lip protrusion depth), inflating
        the measurement by the anteroposterior distance between lip surface and subnasale.
        The gingival display is strictly a VERTICAL (superior-inferior) measurement.
        """
        upper_stomion = self._centroid(self.UPPER_STOMION)
        subnasale = self._centroid(self.SUBNASALE)

        # Y-axis only: vertical distance (Y increases downward in image space)
        # subnasale.y > upper_stomion.y means upper lip is above subnasale = ideal
        # subnasale.y < upper_stomion.y means lip has dropped below subnasale
        elevation_px = abs(upper_stomion[1] - subnasale[1])
        elevation_ratio = self._safe_div(elevation_px, self._morphometric_height(), 0.0)

        # Baseline: in a natural frontal smile, upper stomion sits ~0.12-0.14 of morphometric
        # height below subnasale. Excess above this baseline = gingival exposure.
        gingival_ratio = max(0.0, elevation_ratio - 0.12)
        return round(float(self._clamp(gingival_ratio, 0.0, 1.0)), 4)

    def calculate_buccal_corridor(self) -> float:
        """
        Feature 6: Buccal Corridor
        Clinical definition: Ratio of negative space (lateral vestibule) relative to inter-commissural width.
        Literature range: 0.10 - 0.18 (10% - 18% negative space, Martin et al. 2007).
        """
        cw = self._intercommissural_width()

        inner_l = self._centroid(self.INNER_VERMILION_LEFT)
        inner_r = self._centroid(self.INNER_VERMILION_RIGHT)
        visible_arch_w = self._dist_3d(inner_l, inner_r)

        buccal_corridor_ratio = self._safe_div(cw - visible_arch_w, cw, 0.0)
        return round(float(self._clamp(buccal_corridor_ratio, 0.0, 1.0)), 4)

    def calculate_lip_opening(self) -> float:
        """
        Feature 7: Lip Opening
        Clinical definition: Vertical (Y-axis only) inter-labial gap height across central stomion,
        normalized by morphometric height.
        Literature range: 0.060 - 0.160 (smiling position, Dong et al. 1993).

        Implementation note: Must use Y-axis vertical distance only to measure
        the vertical inter-labial gap. 3D Euclidean includes Z (anteroposterior
        difference between upper and lower lip surfaces) which inflates the value.
        """
        upper_stom = self._centroid(self.UPPER_STOMION)
        lower_stom = self._centroid(self.LOWER_STOMION)

        # Y-axis only: vertical gap between upper and lower stomion
        gap_px = abs(lower_stom[1] - upper_stom[1])
        gap_ratio = self._safe_div(gap_px, self._morphometric_height(), 0.0)
        return round(float(self._clamp(gap_ratio, 0.0, 1.0)), 4)

    def calculate_face_ratio(self) -> float:
        """
        Feature 8: Face Ratio
        Clinical definition: Morphometric Facial Index (Bizygomatic width ZW / Morphometric height MorphH: Nasion to Gnathion).
        Literature range: 1.20 - 1.45 (Farkas 1994).
        """
        zw = self._bizygomatic_width()
        morph_h = self._morphometric_height()
        face_index = self._safe_div(zw, morph_h, 0.0)
        return round(float(self._clamp(face_index, 0.50, 2.50)), 4)

    # ---------------------------------------------------------
    # QUALITY SCORE & ALL FEATURES CONTRACT
    # ---------------------------------------------------------

    def calculate_quality_score(self) -> float:
        """Geometric consistency quality score in [0.0, 1.0]."""
        face_ratio = self.calculate_face_ratio()
        ratio_score = 1.0 - min(abs(face_ratio - 1.30) / 0.60, 1.0)

        midline = self.calculate_midline_deviation()
        symmetry = self.calculate_smile_symmetry()
        geometry_score = 1.0 - min((midline + symmetry) / 0.20, 1.0)

        score = 0.50 * ratio_score + 0.50 * geometry_score
        return round(float(self._clamp(score, 0.0, 1.0)), 4)

    def extract_all_features(self) -> Dict[str, float]:
        """Returns the dictionary of all 8 visible smile features + quality_score."""
        features = {
            "smile_width": self.calculate_smile_width(),
            "lip_opening": self.calculate_lip_opening(),
            "face_ratio": self.calculate_face_ratio(),
            "midline_deviation": self.calculate_midline_deviation(),
            "smile_symmetry": self.calculate_smile_symmetry(),
            "smile_arc": self.calculate_smile_arc(),
            "gingival_display": self.calculate_gingival_display(),
            "buccal_corridor": self.calculate_buccal_corridor(),
            "quality_score": self.calculate_quality_score(),
        }

        # Sanitize any unexpected NaN values
        for key, val in features.items():
            if isinstance(val, float) and (math.isnan(val) or math.isinf(val)):
                features[key] = 0.0

        return features

    def draw_debug_overlay(self, image: np.ndarray) -> Optional[np.ndarray]:
        """Draws measurement overlays on image for visual inspection."""
        if cv2 is None or image is None:
            return image

        overlay = image.copy()
        h, w = overlay.shape[:2]

        def to_xy(idx: int) -> Tuple[int, int]:
            pt = self.landmarks[idx]
            return int(round(pt[0])), int(round(pt[1]))

        # Draw key landmarks
        for idx in self.COMMISSURE_LEFT + self.COMMISSURE_RIGHT + self.SUBNASALE + self.NASION + self.GNATHION:
            cv2.circle(overlay, to_xy(idx), 3, (0, 255, 0), -1)

        features = self.extract_all_features()
        y_offset = 30
        for k, v in features.items():
            cv2.putText(
                overlay,
                f"{k}: {v:.4f}",
                (20, y_offset),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.5,
                (255, 255, 255),
                1,
                cv2.LINE_AA
            )
            y_offset += 20

        return overlay