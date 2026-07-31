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
        # Feature-Specific Clinical Decision Support Suggestions
        # ---------------------------------------------

        # Midline Analysis
        if midline_assessment.get("issue", False) and midline_assessment.get("severity") in ["Mild Concern", "Moderate Concern", "Significant Concern"]:
            recommendations.append(
                "Clinical evaluation of dental midline alignment is suggested to determine whether orthodontic correction could improve facial symmetry."
            )
            add_interpretation(
                "Midline Alignment",
                f"Dental midline shift identified ({midline_assessment.get('value'):.3f} vs reference {midline_assessment.get('threshold')}). Clinical evaluation advised.",
                "warning"
            )
        else:
            add_interpretation(
                "Midline Alignment",
                "The dental midline is within preferred reference alignment, supporting balanced facial symmetry.",
                "good"
            )

        # Smile Symmetry
        if symmetry_assessment.get("issue", False) and symmetry_assessment.get("severity") in ["Mild Concern", "Moderate Concern", "Significant Concern"]:
            recommendations.append(
                "Clinical evaluation of smile symmetry is suggested to assess bilateral commissure height alignment."
            )
            add_interpretation(
                "Smile Symmetry",
                f"Smile asymmetry identified ({symmetry_assessment.get('value'):.3f} vs reference {symmetry_assessment.get('threshold')}). Clinical review advised.",
                "warning"
            )
        else:
            add_interpretation(
                "Smile Symmetry",
                "Smile symmetry is within preferred reference limits with balanced commissure height alignment.",
                "good"
            )

        # Gingival Display
        if gingival_assessment.get("issue", False) and gingival_assessment.get("severity") in ["Mild Concern", "Moderate Concern", "Significant Concern"]:
            recommendations.append(
                "Clinical evaluation of gingival display is suggested to determine whether lip elevation or gingival proportions warrant aesthetic management."
            )
            add_interpretation(
                "Gingival Display",
                f"Increased gingival display observed ({gingival_assessment.get('value'):.3f} vs reference {gingival_assessment.get('threshold')}). Clinical evaluation advised.",
                "warning"
            )
        else:
            add_interpretation(
                "Gingival Display",
                "Gingival display is within preferred reference limits with appropriate gingival exposure during smiling.",
                "good"
            )

        # Smile Arc
        if smile_arc_assessment.get("issue", False) and smile_arc_assessment.get("severity") in ["Mild Concern", "Moderate Concern", "Significant Concern"]:
            recommendations.append(
                "Clinical evaluation of smile arc curvature is suggested to assess anterior incisal curvature relative to lower lip contour."
            )
            add_interpretation(
                "Smile Arc",
                f"Smile arc curvature variance observed ({smile_arc_assessment.get('value'):.3f} vs reference {smile_arc_assessment.get('threshold')}). Clinical review advised.",
                "warning"
            )
        else:
            add_interpretation(
                "Smile Arc",
                "Smile arc is consonant and demonstrates ideal parabolic curvature relative to lower lip contour.",
                "good"
            )

        # ---------------------------------------------
        # Overall Severity & Doctor-Assisting Guidance
        # ---------------------------------------------

        if severity == "Severe":
            priority = "High"
            recommendations.append("Comprehensive orthodontic clinical evaluation and diagnostic imaging are recommended.")
        elif severity == "Moderate":
            priority = "Medium"
            recommendations.append("Elective orthodontic consultation is suggested for comprehensive smile planning.")
        elif severity == "Mild":
            priority = "Low-Medium"
            recommendations.append("Minor aesthetic variation observed; elective clinical consultation may be considered based on patient preferences.")
        else:  # Normal
            priority = "Routine Observation"
            recommendations.append("Evaluated smile features sit within standard clinical reference norms. Routine observation during regular dental check-ups is recommended.")

        # Always include doctor-assisting decision support disclaimer note
        recommendations.append(
            "Note for Clinicians: AI decision support findings are provided to assist in-person clinical evaluation. Diagnostic conclusions and treatment decisions remain solely under the discretion of the attending doctor."
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