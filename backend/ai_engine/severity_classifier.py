from __future__ import annotations

from typing import Dict, Any


class SeverityClassifier:
    """
    Rule-based clinical severity estimator for SmileAI.

    This is a fallback / explainability layer, not the main ML model.
    It works best with normalized features from FeatureExtractor.
    """

    def __init__(self, features: Dict[str, float]):
        self.features = features or {}

    # -------------------------------------------------
    # Basic helpers
    # -------------------------------------------------
    @staticmethod
    def _clamp(value: float, low: float = 0.0, high: float = 1.0) -> float:
        return max(low, min(high, value))

    def _get(self, key: str, default: float = 0.0) -> float:
        try:
            return float(self.features.get(key, default))
        except (TypeError, ValueError):
            return float(default)

    def _range_penalty(self, value: float, low: float, high: float, max_dev: float) -> float:
        """
        Penalty = 0 when value is inside [low, high].
        Outside the range, penalty grows linearly up to 1.
        """
        if low <= value <= high:
            return 0.0

        if value < low:
            dev = low - value
        else:
            dev = value - high

        return self._clamp(dev / max_dev, 0.0, 1.0)

    def _upper_penalty(self, value: float, threshold: float, max_dev: float) -> float:
        """
        Penalty = 0 when value <= threshold.
        Higher values increase penalty linearly up to 1.
        """
        if value <= threshold:
            return 0.0
        return self._clamp((value - threshold) / max_dev, 0.0, 1.0)

    def _target_penalty(self, value: float, target: float, tolerance: float) -> float:
        """
        Penalty = 0 when value is close to target.
        Grows as value moves away from the target.
        """
        return self._clamp(abs(value - target) / tolerance, 0.0, 1.0)

    # -------------------------------------------------
    # Main scoring logic
    # -------------------------------------------------
    def classify(self) -> Dict[str, Any]:
        # Normalized features
        smile_width = self._get("smile_width")
        lip_opening = self._get("lip_opening")
        face_ratio = self._get("face_ratio")
        midline_deviation = self._get("midline_deviation")
        smile_symmetry = self._get("smile_symmetry")
        smile_arc = self._get("smile_arc")
        gingival_display = self._get("gingival_display")
        buccal_corridor = self._get("buccal_corridor")
        quality_score = self._get("quality_score", 1.0)

        # -------------------------------------------------
        # Component penalties (0..1)
        # Higher penalty = more clinically concerning
        # -------------------------------------------------
        width_penalty = self._range_penalty(smile_width, low=0.42, high=0.62, max_dev=0.18)
        lip_penalty = self._range_penalty(lip_opening, low=0.03, high=0.13, max_dev=0.10)
        ratio_penalty = self._range_penalty(face_ratio, low=0.72, high=1.05, max_dev=0.40)

        # These are the strongest clinical drivers
        midline_penalty = self._upper_penalty(midline_deviation, threshold=0.020, max_dev=0.060)
        symmetry_penalty = self._upper_penalty(smile_symmetry, threshold=0.010, max_dev=0.040)
        gingival_penalty = self._upper_penalty(gingival_display, threshold=0.012, max_dev=0.050)

        # Smile arc is best around a gentle positive arc; too flat or too extreme is penalized
        arc_penalty = self._target_penalty(smile_arc, target=0.015, tolerance=0.030)

        # In this project, higher buccal_corridor generally means a narrower smile band
        buccal_penalty = self._upper_penalty(buccal_corridor, threshold=0.50, max_dev=0.25)

        # -------------------------------------------------
        # Weighted composite score out of 100
        # -------------------------------------------------
        weighted_score = (
            24.0 * midline_penalty +
            22.0 * symmetry_penalty +
            16.0 * gingival_penalty +
            10.0 * arc_penalty +
            10.0 * buccal_penalty +
            8.0  * width_penalty +
            5.0  * lip_penalty +
            5.0  * ratio_penalty
        )

        # Small quality adjustment: lower quality slightly increases score
        if quality_score < 0.60:
            weighted_score += 8.0 * (0.60 - quality_score) / 0.60
        elif quality_score < 0.80:
            weighted_score += 3.0 * (0.80 - quality_score) / 0.20

        weighted_score = round(self._clamp(weighted_score, 0.0, 100.0), 2)

        # -------------------------------------------------
        # Severity mapping
        # -------------------------------------------------
        if weighted_score < 18:
            severity = "Normal"
        elif weighted_score < 38:
            severity = "Mild"
        elif weighted_score < 60:
            severity = "Moderate"
        else:
            severity = "Severe"

        # -------------------------------------------------
        # Confidence estimate
        # -------------------------------------------------
        if severity == "Normal":
            boundary = 18.0
            distance = boundary - weighted_score
        elif severity == "Mild":
            boundary = 18.0 if weighted_score < 28 else 38.0
            distance = min(abs(weighted_score - 18.0), abs(weighted_score - 38.0))
        elif severity == "Moderate":
            distance = min(abs(weighted_score - 38.0), abs(weighted_score - 60.0))
        else:
            distance = weighted_score - 60.0

        confidence = 0.50 + 0.50 * self._clamp(distance / 18.0, 0.0, 1.0)
        confidence *= self._clamp(quality_score, 0.55, 1.0)
        confidence = round(self._clamp(confidence, 0.50, 0.99), 4)

        # -------------------------------------------------
        # Explanatory details
        # -------------------------------------------------
        details = {
            "smile_width_penalty": round(width_penalty * 8.0, 2),
            "lip_opening_penalty": round(lip_penalty * 5.0, 2),
            "face_ratio_penalty": round(ratio_penalty * 5.0, 2),
            "midline_penalty": round(midline_penalty * 24.0, 2),
            "smile_symmetry_penalty": round(symmetry_penalty * 22.0, 2),
            "smile_arc_penalty": round(arc_penalty * 10.0, 2),
            "gingival_display_penalty": round(gingival_penalty * 16.0, 2),
            "buccal_corridor_penalty": round(buccal_penalty * 10.0, 2),
            "quality_score": round(quality_score, 4),
        }

        findings = []
        if midline_deviation > 0.020:
            findings.append("Midline deviation elevated")
        if smile_symmetry > 0.010:
            findings.append("Smile asymmetry observed")
        if gingival_display > 0.012:
            findings.append("Gingival display increased")
        if buccal_corridor > 0.50:
            findings.append("Narrow smile pattern detected")
        if abs(smile_arc - 0.015) > 0.030:
            findings.append("Smile arc outside preferred range")
        if quality_score < 0.60:
            findings.append("Low image quality may reduce reliability")

        if not findings:
            findings.append("Smile proportions balanced")

        recommendation = self._build_recommendation(severity, findings)

        return {
            "severity": severity,
            "score": weighted_score,
            "confidence": confidence,
            "details": details,
            "clinical_findings": findings,
            "recommendation": recommendation,
        }

    def _build_recommendation(self, severity: str, findings: list[str]) -> str:
        if severity == "Normal":
            return "Smile aesthetics within acceptable range."
        if severity == "Mild":
            return "Mild orthodontic consultation recommended."
        if severity == "Moderate":
            return "Orthodontic evaluation advised for smile correction."
        return "Comprehensive orthodontic treatment planning recommended."