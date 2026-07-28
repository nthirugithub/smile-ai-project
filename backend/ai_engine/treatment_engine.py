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
        prediction: Dict[str, Any],
        severity_analysis: Dict[str, Any],
    ):

        self.features = features or {}
        self.prediction = prediction or {}
        self.severity_analysis = severity_analysis or {}

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

        interpretation: List[Dict[str, str]] = []

        # ---------------------------------------------
        # Extract Features
        # ---------------------------------------------

        quality_score = self._get_feature(
            "quality_score",
            1.0
        )

        severity = self.severity_analysis.get(
            "severity",
            "Unknown"
        )

        confidence = self.severity_analysis.get(
            "confidence",
            0.0
        )

        clinical_findings = self.severity_analysis.get(
            "clinical_findings",
            []
        )

        assessment = self.severity_analysis.get(
            "assessment",
            {}
        )
        midline_assessment = assessment.get("midline", {})
        symmetry_assessment = assessment.get("symmetry", {})
        gingival_assessment = assessment.get("gingival_display", {})
        smile_arc_assessment = assessment.get("smile_arc", {})

        findings.extend(clinical_findings)

        def add_interpretation(
            title: str,
            description: str,
            status: str,
        ):
            interpretation.append({
                "title": title,
                "description": description,
                "status": status,
            })

        # ---------------------------------------------
        # Midline Analysis
        # ---------------------------------------------

        if midline_assessment.get("issue", False):

            recommendations.append(
                "Clinical evaluation of dental midline alignment is recommended to determine whether orthodontic correction could improve smile symmetry and facial balance."
            )

            add_interpretation(
                "Midline Alignment",
                (
                    "The dental midline deviates beyond the preferred reference range, "
                    "which may influence overall smile symmetry and facial harmony.\n\n"
                    f"Measured value: {midline_assessment.get('value')}\n"
                    f"Preferred threshold: {midline_assessment.get('threshold')}"
                ),
                "warning",
            )

        else:

            add_interpretation(
                "Midline Alignment",
                (
                    "The dental midline is within the preferred reference range and "
                    "demonstrates good alignment with the facial midline, supporting "
                    "balanced smile aesthetics."
                ),
                "good",
            )
        # ---------------------------------------------
        # Smile Symmetry
        # ---------------------------------------------

        if symmetry_assessment.get("issue", False):

            recommendations.append(
                "Clinical evaluation of smile symmetry is recommended to determine whether orthodontic or restorative treatment could improve overall facial balance."
            )

            add_interpretation(
                "Smile Symmetry",
                (
                    "Noticeable smile asymmetry was identified, which may affect overall "
                    "smile balance and facial harmony.\n\n"
                    f"Measured value: {symmetry_assessment.get('value')}\n"
                    f"Preferred threshold: {symmetry_assessment.get('threshold')}"
                ),
                "warning",
            )

        else:

            add_interpretation(
                "Smile Symmetry",
                (
                    "Smile symmetry is within the preferred reference range, with balanced "
                    "left and right smile proportions contributing to natural facial harmony."
                ),
                "good",
            )
                
        # ---------------------------------------------
        # Gingival Display
        # ---------------------------------------------

        if gingival_assessment.get("issue", False):

            recommendations.append(
                "Clinical evaluation by an orthodontist or periodontist is recommended to determine the underlying cause of the increased gingival display and the most appropriate management approach."
            )

            add_interpretation(
                "Gingival Display",
                (
                    "Increased gingival display was observed during smiling, which may "
                    "influence overall smile aesthetics.\n\n"
                    f"Measured value: {gingival_assessment.get('value')}\n"
                    f"Preferred threshold: {gingival_assessment.get('threshold')}"
                ),
                "warning",
            )

        else:

            add_interpretation(
                "Gingival Display",
                (
                    "Gingival display is within the preferred reference range, with an "
                    "appropriate amount of gum tissue visible during smiling."
                ),
                "good",
            )

        # ---------------------------------------------
        # Smile Arc
        # ---------------------------------------------

        if smile_arc_assessment.get("issue", False):

            recommendations.append(
                "Clinical evaluation of the smile arc is recommended to determine whether orthodontic treatment could improve the relationship between the upper teeth and the lower lip during smiling."
            )

            add_interpretation(
                "Smile Arc",
                (
                    "The smile arc differs from the preferred reference range, which may "
                    "affect the overall harmony and aesthetic appearance of the smile.\n\n"
                    f"Measured value: {smile_arc_assessment.get('value')}\n"
                    f"Preferred threshold: {smile_arc_assessment.get('threshold')}"
                ),
                "warning",
            )

        else:

            add_interpretation(
                "Smile Arc",
                (
                    "The smile arc is within the preferred reference range, showing a "
                    "harmonious relationship between the curvature of the upper teeth "
                    "and the lower lip during smiling."
                ),
                "good",
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

            "severity": severity,

            "confidence": round(float(confidence), 4),

            "treatment_priority": priority,

            "clinical_findings": findings,

            "recommendations": recommendations,

            "clinical_interpretation": interpretation,
        }