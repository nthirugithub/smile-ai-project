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
        gingival_assessment = assessment.get("gingival", {})
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
                "Orthodontic midline correction evaluation recommended."
            )

            

            add_interpretation(
                "Midline Alignment",
                (
                    f"{midline_assessment.get('finding')} "
                    f"(Value: {midline_assessment.get('value')}, "
                    f"Threshold: {midline_assessment.get('threshold')})."
                ),
                "warning",
            )

        else:

            add_interpretation(
                "Midline Alignment",
                "The dental midline is well aligned with the facial midline, contributing to overall facial harmony.",
                "good",
            )

        # ---------------------------------------------
        # Smile Symmetry
        # ---------------------------------------------

        if symmetry_assessment.get("issue", False):

            recommendations.append(
                "Smile alignment and symmetry assessment suggested."
            )

            add_interpretation(
                "Smile Symmetry",
                (
                    f"{symmetry_assessment.get('finding')} "
                    f"(Value: {symmetry_assessment.get('value')}, "
                    f"Threshold: {symmetry_assessment.get('threshold')})."
                ),
                "warning",
            )

        else:

            add_interpretation(
                "Smile Symmetry",
                "Smile symmetry is within acceptable esthetic limits, with minimal left-right asymmetry observed.",
                "good",
            )
                
        # ---------------------------------------------
        # Gingival Display
        # ---------------------------------------------

        if gingival_assessment.get("issue", False):

            recommendations.append(
                "Periodontal or orthodontic evaluation may improve smile aesthetics."
            )

            add_interpretation(
                "Gingival Display",
                (
                    f"{gingival_assessment.get('finding')} "
                    f"(Value: {gingival_assessment.get('value')}, "
                    f"Threshold: {gingival_assessment.get('threshold')})."
                ),
                "warning",
            )

        else:

            add_interpretation(
                "Gingival Display",
                "Gingival exposure during smiling is within acceptable esthetic limits.",
                "good",
            )

        # ---------------------------------------------
        # Smile Arc
        # ---------------------------------------------

        if smile_arc_assessment.get("issue", False):


            recommendations.append(
                "Smile arc optimization may improve aesthetic harmony."
            )

            add_interpretation(
                "Smile Arc",
                (
                    f"{smile_arc_assessment.get('finding')} "
                    f"(Value: {smile_arc_assessment.get('value')}, "
                    f"Threshold: {smile_arc_assessment.get('threshold')})."
                ),
                "warning",
            )

        else:

            add_interpretation(
                "Smile Arc",
                "The smile arc demonstrates a harmonious relationship with the curvature of the lower lip.",
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
        # Overall Smile Quality
        # ---------------------------------------------

        if severity == "Normal":

            summary = (
                "Overall smile aesthetics are consistent with a normal clinical classification. "
                "No clinically significant abnormalities were identified, and treatment priority is Low."
            )

            status = "good"

        elif severity == "Mild":

            summary = (
                "Minor esthetic variations were detected. "
                "Small orthodontic or cosmetic improvements may further enhance smile harmony."
            )

            status = "warning"

        elif severity == "Moderate":

            summary = (
                "Moderate smile irregularities were identified that may benefit from orthodontic evaluation and treatment planning."
            )

            status = "warning"

        else:

            summary = (
                "Significant smile irregularities were detected. "
                "Comprehensive orthodontic assessment is recommended."
            )

            status = "critical"

        interpretation.insert(
            0,
            {
                "title": "Overall Smile Quality",
                "description": summary,
                "status": status,
            },
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