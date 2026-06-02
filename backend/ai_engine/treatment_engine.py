from __future__ import annotations

from typing import Dict, List, Any


class TreatmentEngine:
    """
    Clinical recommendation engine for SmileAI.

    Uses:
    - extracted normalized features
    - severity prediction
    - confidence score
    - quality score

    Generates:
    - orthodontic recommendations
    - aesthetic findings
    - treatment priority
    """

    def __init__(
        self,
        features: Dict[str, float],
        prediction: Dict[str, Any]
    ):

        self.features = features or {}
        self.prediction = prediction or {}

    # -------------------------------------------------
    # Helpers
    # -------------------------------------------------

    def _get_feature(
        self,
        key: str,
        default: float = 0.0
    ) -> float:

        try:
            return float(
                self.features.get(key, default)
            )

        except Exception:
            return default

    def _get_prediction(
        self,
        key: str,
        default=None
    ):

        return self.prediction.get(key, default)

    # -------------------------------------------------
    # Main recommendation generator
    # -------------------------------------------------

    def generate_recommendations(self) -> Dict[str, Any]:

        recommendations: List[str] = []

        findings: List[str] = []

        priority = "Low"

        # ---------------------------------------------
        # Extract Features
        # ---------------------------------------------

        midline = self._get_feature(
            "midline_deviation"
        )

        symmetry = self._get_feature(
            "smile_symmetry"
        )

        gingival = self._get_feature(
            "gingival_display"
        )

        buccal = self._get_feature(
            "buccal_corridor"
        )

        smile_arc = self._get_feature(
            "smile_arc"
        )

        lip_opening = self._get_feature(
            "lip_opening"
        )

        quality_score = self._get_feature(
            "quality_score",
            1.0
        )

        severity = self._get_prediction(
            "severity",
            "Unknown"
        )

        confidence = self._get_prediction(
            "confidence",
            0.0
        )

        # ---------------------------------------------
        # Midline Analysis
        # ---------------------------------------------

        if midline > 0.020:

            findings.append(
                "Facial midline deviation detected."
            )

            recommendations.append(
                "Orthodontic midline correction evaluation recommended."
            )

        # ---------------------------------------------
        # Smile Symmetry
        # ---------------------------------------------

        if symmetry > 0.012:

            findings.append(
                "Smile asymmetry observed."
            )

            recommendations.append(
                "Smile alignment and symmetry assessment suggested."
            )

        # ---------------------------------------------
        # Gingival Display
        # ---------------------------------------------

        if gingival > 0.020:

            findings.append(
                "Elevated gingival display detected."
            )

            recommendations.append(
                "Periodontal or orthodontic evaluation may improve smile aesthetics."
            )

        # ---------------------------------------------
        # Buccal Corridor
        # ---------------------------------------------

        if buccal > 0.55:

            findings.append(
                "Narrow smile pattern identified."
            )

            recommendations.append(
                "Arch expansion assessment may improve smile fullness."
            )

        # ---------------------------------------------
        # Smile Arc
        # ---------------------------------------------

        if abs(smile_arc - 0.015) > 0.030:

            findings.append(
                "Smile arc outside preferred aesthetic range."
            )

            recommendations.append(
                "Smile arc optimization may improve aesthetic harmony."
            )

        # ---------------------------------------------
        # Lip Opening
        # ---------------------------------------------

        if lip_opening < 0.020:

            findings.append(
                "Limited smile exposure observed."
            )

        elif lip_opening > 0.16:

            findings.append(
                "High smile opening detected."
            )

        # ---------------------------------------------
        # Severity-Based Planning
        # ---------------------------------------------

        if severity == "Severe":

            priority = "High"

            recommendations.append(
                "Comprehensive orthodontic treatment planning strongly recommended."
            )

            recommendations.append(
                "Detailed clinical evaluation and radiographic assessment advised."
            )

        elif severity == "Moderate":

            priority = "Medium"

            recommendations.append(
                "Orthodontic consultation recommended for smile correction planning."
            )

        elif severity == "Mild":

            priority = "Low-Medium"

            recommendations.append(
                "Minor orthodontic or cosmetic adjustments may improve smile balance."
            )

        elif severity == "Normal":

            priority = "Low"

            recommendations.append(
                "Smile aesthetics appear balanced with no major abnormalities detected."
            )

        # ---------------------------------------------
        # Confidence Awareness
        # ---------------------------------------------

        if confidence < 0.70:

            findings.append(
                "Prediction confidence is moderate. Clinical validation advised."
            )

        # ---------------------------------------------
        # Image Quality Warning
        # ---------------------------------------------

        if quality_score < 0.65:

            findings.append(
                "Low image quality may reduce reliability of assessment."
            )

        # ---------------------------------------------
        # Remove duplicates
        # ---------------------------------------------

        recommendations = list(
            dict.fromkeys(recommendations)
        )

        findings = list(
            dict.fromkeys(findings)
        )

        # ---------------------------------------------
        # Final Output
        # ---------------------------------------------

        return {

            "severity":
                severity,

            "confidence":
                round(float(confidence), 4),

            "treatment_priority":
                priority,

            "clinical_findings":
                findings,

            "recommendations":
                recommendations,
        }