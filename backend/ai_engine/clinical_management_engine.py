"""
Clinical Management Recommendation Engine for Smile AI Decision Support System.

Phase 5 Core Module:
Transforms the explainable clinical assessment produced by Phase 4 into structured,
evidence-based management guidance presented from dual perspectives:
- Clinician Perspective (technical, evidence-backed, relevant clinical disciplines)
- Patient Perspective (supportive, educational, plain-language, non-pathological)

STRICT DESIGN RULES:
- Does NOT diagnose medical conditions or prescribe specific treatments/procedures.
- Uses conservative CDSS language ("may benefit from", "consider clinical evaluation").
- Indicates Relevant Clinical Disciplines rather than ordering direct referrals.
- Consumes ONLY the structured assessment produced by Phase 4.
- Reuses `ClinicalKnowledgeBase` for declarative terminology, education topics, and sanitization.
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional
from ai_engine.clinical_knowledge_base import ClinicalKnowledgeBase


class ClinicalManagementRecommendationEngine:
    """
    Explainable Clinical Management Recommendation Engine for Smile AI.
    Executes Phases 5A through 5I to produce decision-support guidance.
    """

    def __init__(self, phase4_assessment: Optional[Dict[str, Any]] = None):
        """
        Initialize management engine with Phase 4 structured assessment.
        """
        self.p4_data = phase4_assessment or {}
        self.ckb = ClinicalKnowledgeBase

    # =========================================================================
    # PHASE 5A: CLINICAL MANAGEMENT PLANNER
    # =========================================================================
    def plan_management_priorities(self, p4: Dict[str, Any]) -> Dict[str, Any]:
        """
        Phase 5A: Establishes overall management priorities using conservative CDSS categories.
        """
        summary = p4.get("clinical_summary", {})
        uncertainty = p4.get("uncertainty_analysis", {})
        sev = summary.get("overall_severity", "Normal")
        unc_level = uncertainty.get("uncertainty_level", "High")
        quality_score = p4.get("evidence_summary", {}).get("image_quality_score", 1.0)

        # Determine Conservative CDSS Category
        if quality_score < 0.60 or unc_level in ["Very Low", "Low"]:
            priority_category = "Higher-Quality Imaging Recommended"
            priority_description = "Image quality or lighting limits measurement certainty; re-imaging under standardized conditions is recommended before clinical planning."
            risk_level = "Elevated Uncertainty"
        elif sev in ["Severe", "Significant Concern"]:
            priority_category = "Further Clinical Evaluation May Be Appropriate"
            priority_description = "Noticeable structural or aesthetic features identified; direct clinical evaluation can determine potential management options."
            risk_level = "Moderate Aesthetic Discrepancy"
        elif sev in ["Moderate", "Moderate Concern"]:
            priority_category = "Clinical Consultation May Be Beneficial"
            priority_description = "Interacting aesthetic features observed; elective clinical consultation may provide useful guidance."
            risk_level = "Mild-to-Moderate Aesthetic Variant"
        else:
            priority_category = "Routine Observation"
            priority_description = "Evaluated features remain within standard reference norms; routine observation during regular dental check-ups is appropriate."
            risk_level = "Low / Standard Anatomical Norm"

        return {
            "management_priority_category": priority_category,
            "priority_description": priority_description,
            "risk_level": risk_level,
            "overall_severity_context": sev,
            "overall_confidence_context": summary.get("overall_confidence", {}).get("label", "Moderate")
        }

    # =========================================================================
    # PHASE 5B: CLINICIAN PERSPECTIVE GENERATOR
    # =========================================================================
    def generate_clinician_summary(self, p4: Dict[str, Any], priorities: Dict[str, Any]) -> Dict[str, Any]:
        """
        Phase 5B: Formulates professional, concise summaries for dental practitioners.
        """
        findings = p4.get("clinical_findings", {})
        confidence_info = p4.get("confidence_analysis", {})
        uncertainty_info = p4.get("uncertainty_analysis", {})
        conflicts = p4.get("conflict_resolution", [])

        # Collect Relevant Clinical Disciplines
        relevant_disciplines = set()
        for wf in findings.get("weighed_findings", []):
            feat = wf.get("feature")
            sev = wf.get("severity")
            if sev not in ["Normal"]:
                val = wf.get("value", 0.0)
                cond = "narrow" if val < 0.40 else ("wide" if val > 0.53 else "asymmetric" if feat == "smile_symmetry" else "deviated")
                if feat == "smile_arc":
                    cond = "reverse" if val < 0.000 else "flat"
                elif feat == "gingival_display":
                    cond = "excessive"
                elif feat == "buccal_corridor":
                    cond = "excessive_dark_space"

                discs = self.ckb.get_relevant_disciplines(feat, cond)
                relevant_disciplines.update(discs)

        if not relevant_disciplines:
            relevant_disciplines.add("General Dentistry")

        # Differential Clinical Considerations
        considerations = []
        for wf in findings.get("weighed_findings", []):
            if wf.get("severity") not in ["Normal"]:
                feat_display = self.ckb.get_feature_info(wf.get("feature")).get("display_name", wf.get("feature"))
                considerations.append(
                    f"Evaluate {feat_display} ({wf.get('severity')}) for potential dentoalveolar vs skeletal contribution."
                )

        if conflicts:
            for c in conflicts:
                considerations.append(f"Clinical Note on Conflict: {c.get('conflict_type')} - {c.get('explanation')}")

        return {
            "professional_overview": f"Clinical decision support summary indicating '{priorities['management_priority_category']}' context based on 2D facial visual analysis.",
            "primary_findings": findings.get("primary_findings", []),
            "secondary_findings": findings.get("secondary_findings", []),
            "evidence_strength": confidence_info.get("evidence_quality", "Moderate"),
            "confidence_assessment": confidence_info.get("overall_confidence", {}),
            "uncertainty_assessment": {
                "overall_uncertainty_score": uncertainty_info.get("overall_uncertainty_score", 0.15),
                "uncertainty_level": uncertainty_info.get("uncertainty_level", "Moderate"),
                "mitigation": uncertainty_info.get("mitigation_notes", "")
            },
            "relevant_clinical_disciplines": sorted(list(relevant_disciplines)),
            "differential_clinical_considerations": considerations if considerations else ["All features sit within standard reference ranges."],
            "suggested_diagnostic_examinations": [
                "Direct intra-oral examination and incisal plane evaluation.",
                "Standardized extra-oral clinical photography.",
                "Comprehensive dental & orthodontic record review if intervention is contemplated."
            ]
        }

    # =========================================================================
    # PHASE 5C: PATIENT PERSPECTIVE GENERATOR
    # =========================================================================
    def generate_patient_summary(self, p4: Dict[str, Any], priorities: Dict[str, Any]) -> Dict[str, Any]:
        """
        Phase 5C: Formulates accessible, empathetic explanations for patients.
        """
        summary = p4.get("clinical_summary", {})
        quality_score = p4.get("evidence_summary", {}).get("image_quality_score", 1.0)
        findings = p4.get("clinical_findings", {})

        # What was observed
        observed_items = []
        for wf in findings.get("weighed_findings", []):
            feat = wf.get("feature")
            sev = wf.get("severity")
            patient_term = self.ckb.get_patient_term(feat)
            if sev in ["Normal"]:
                observed_items.append(f"Your {patient_term.lower()} shows well-balanced harmony.")
            else:
                observed_items.append(f"Your {patient_term.lower()} exhibits a noticeable natural characteristic ({sev.lower()}).")

        # What it may mean
        meaning = (
            "Your smile exhibits natural variations that make your appearance unique. "
            "These findings highlight aesthetic proportions across your smile width, gum line, and dental symmetry."
        )

        # Why confidence may be reduced
        confidence_note = ""
        if quality_score < 0.60:
            confidence_note = "Please note: The photo quality or lighting was lower than ideal, which limits how precisely measurements can be read."
        else:
            confidence_note = "The photo quality allowed for clear measurement analysis of visible facial features."

        # Next steps
        if priorities["management_priority_category"] == "Higher-Quality Imaging Recommended":
            next_step = "Taking a new photograph with brighter, direct lighting will help provide a more clear assessment."
        elif priorities["management_priority_category"] == "Routine Observation":
            next_step = "No specific action is needed. Discussing your smile during your regular dental check-up is always a great habit."
        else:
            next_step = "If you have aesthetic goals or questions about your smile, scheduling a friendly consultation with a qualified dentist or orthodontist can help explore your options."

        return {
            "headline": "Your Smile Analysis Overview",
            "what_was_observed": observed_items[:4],
            "what_it_may_mean": meaning,
            "confidence_explanation": confidence_note,
            "recommended_next_step": next_step
        }

    # =========================================================================
    # PHASE 5D: PATIENT COMMUNICATION & EDUCATION LAYER
    # =========================================================================
    def apply_patient_communication_layer(self, raw_patient_summary: Dict[str, Any]) -> Dict[str, Any]:
        """
        Phase 5D: Transforms clinician-oriented text into supportive, non-alarmist communication
        while preserving clinical accuracy, confidence, and uncertainty context.
        """
        sanitized_summary = {}
        for key, val in raw_patient_summary.items():
            if isinstance(val, str):
                sanitized_summary[key] = self.ckb.sanitize_patient_text(val)
            elif isinstance(val, list):
                sanitized_summary[key] = [self.ckb.sanitize_patient_text(item) if isinstance(item, str) else item for item in val]
            else:
                sanitized_summary[key] = val

        return sanitized_summary

    # =========================================================================
    # PHASE 5E: CLINICAL MANAGEMENT SUGGESTIONS
    # =========================================================================
    def generate_management_suggestions(self, p4: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Phase 5E: Generates generalized possible clinical objectives without recommending
        specific dental procedures, surgeries, medications, cost estimates, or timelines.
        """
        suggestions = []
        findings = p4.get("clinical_findings", {})

        for wf in findings.get("weighed_findings", []):
            feat = wf.get("feature")
            sev = wf.get("severity")
            val = wf.get("value", 0.0)

            if sev not in ["Normal"]:
                cond = "narrow" if val < 0.40 else ("wide" if val > 0.53 else "asymmetric" if feat == "smile_symmetry" else "deviated")
                if feat == "smile_arc":
                    cond = "reverse" if val < 0.000 else "flat"
                elif feat == "gingival_display":
                    cond = "excessive"
                elif feat == "buccal_corridor":
                    cond = "excessive_dark_space"

                objs = self.ckb.get_management_objectives(feat, cond)
                for obj in objs:
                    cautious_obj = {
                        "feature": feat,
                        "observed_severity": sev,
                        "possible_objective_code": obj.get("objective_code"),
                        "possible_clinical_objective": f"Consider clinical evaluation: {obj.get('management_objective')}",
                        "relevant_disciplines": [obj.get("discipline", "General Dentistry")]
                    }
                    if cautious_obj not in suggestions:
                        suggestions.append(cautious_obj)

        if not suggestions:
            suggestions.append({
                "feature": "all_features",
                "observed_severity": "Normal",
                "possible_objective_code": "OBJ_ROUTINE_OBSERVATION",
                "possible_clinical_objective": "Routine observation during regular dental maintenance.",
                "relevant_disciplines": ["General Dentistry"]
            })

        return suggestions

    # =========================================================================
    # PHASE 5F: EXPLAINABILITY ENGINE FOR RECOMMENDATIONS
    # =========================================================================
    def explain_recommendations(
        self,
        p4: Dict[str, Any],
        suggestions: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """
        Phase 5F: Maintains explicit 1-to-1 evidence traceability for every management suggestion:
        Finding -> Phase 4 Evidence -> Reasoning -> Why Objective Suggested.
        """
        explainability_chains = []
        reasoning_chains = {rc["feature"]: rc for rc in p4.get("reasoning_chain", [])}

        for sug in suggestions:
            feat = sug.get("feature")
            if feat == "all_features":
                explainability_chains.append({
                    "target_finding": "Normal Harmonious Smile",
                    "phase4_evidence": "All 8 measurements sitting within ideal clinical reference ranges.",
                    "clinical_reasoning": "No significant aesthetic penalties or feature interaction issues identified.",
                    "why_objective_suggested": "Routine dental observation maintains long-term oral health and aesthetic stability."
                })
                continue

            rc = reasoning_chains.get(feat, {})
            explainability_chains.append({
                "target_finding": f"{self.ckb.get_feature_info(feat).get('display_name', feat)}: {sug.get('observed_severity')}",
                "phase4_evidence": rc.get("supporting_evidence", f"Severity: {sug.get('observed_severity')}"),
                "clinical_reasoning": rc.get("clinical_interpretation", "Identified aesthetic variance."),
                "why_objective_suggested": f"Objective '{sug.get('possible_clinical_objective')}' provides non-prescriptive decision support for relevant practitioners."
            })

        return explainability_chains

    # =========================================================================
    # PHASE 5G: SAFETY & DISCLAIMER LAYER
    # =========================================================================
    def build_safety_notice(self) -> Dict[str, str]:
        """
        Phase 5G: Returns standard CDSS disclaimers emphasizing clinical decision support boundaries.
        """
        return {
            "disclaimer_title": "Clinical Decision Support System Notice",
            "primary_notice": (
                "This assessment is intended to support, not replace, professional clinical evaluation. "
                "All suggestions are based solely on 2D visual facial photo analysis."
            ),
            "clinical_requirement": (
                "Direct clinical examination, intra-oral inspection, and professional diagnostic records "
                "remain necessary before making any treatment decisions."
            ),
            "non_prescriptive_confirmation": (
                "Smile AI does not diagnose disease, prescribe dental procedures, or guarantee aesthetic outcomes."
            )
        }

    # =========================================================================
    # PHASE 5I: PATIENT EDUCATION MODULE
    # =========================================================================
    def generate_patient_education(self, p4: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Phase 5I: Generates non-prescriptive, educational context explaining what findings represent,
        highlighting natural population variations, and noting why clinical examination is helpful.
        """
        education_topics = []
        evaluated_features = p4.get("evidence_summary", {}).get("measurements_evaluated", 8)
        weighed = p4.get("clinical_findings", {}).get("weighed_findings", [])

        # Collect features of interest or provide baseline education
        target_features = [wf.get("feature") for wf in weighed if wf.get("severity") not in ["Normal"]]
        if not target_features:
            target_features = ["smile_width", "smile_symmetry", "midline_deviation", "smile_arc"]

        for feat in target_features:
            edu_info = self.ckb.get_patient_education(feat)
            if edu_info:
                education_topics.append({
                    "feature": feat,
                    "educational_title": edu_info.get("topic"),
                    "what_it_represents": edu_info.get("explanation"),
                    "natural_variation_context": edu_info.get("variation_note"),
                    "why_clinical_evaluation_helps": edu_info.get("clinical_relevance")
                })

        return education_topics

    # =========================================================================
    # PHASE 5H: STRUCTURED OUTPUT ASSEMBLY
    # =========================================================================
    def generate_structured_recommendations(
        self,
        phase4_assessment: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Main entry point for Phase 5.
        Executes sub-stages 5A to 5I and outputs the structured CDSS management guidance.
        """
        p4 = phase4_assessment if phase4_assessment is not None else self.p4_data

        # Phase 5A: Management Priorities
        priorities = self.plan_management_priorities(p4)

        # Phase 5B: Clinician Summary
        clinician_summary = self.generate_clinician_summary(p4, priorities)

        # Phase 5C & 5D: Patient Summary & Communication Filter
        raw_patient_summary = self.generate_patient_summary(p4, priorities)
        patient_summary = self.apply_patient_communication_layer(raw_patient_summary)

        # Phase 5E: Generalized Management Objectives
        management_suggestions = self.generate_management_suggestions(p4)

        # Phase 5F: Explainability Engine
        explainability = self.explain_recommendations(p4, management_suggestions)

        # Phase 5G: Safety Notice
        safety_notice = self.build_safety_notice()

        # Phase 5I: Patient Education Module
        patient_education = self.generate_patient_education(p4)

        # Follow-up considerations
        quality_score = p4.get("evidence_summary", {}).get("image_quality_score", 1.0)
        follow_up = []
        if quality_score < 0.60:
            follow_up.append("Re-acquire high-resolution photo with direct lighting.")
        follow_up.append("Discuss observations during next routine dental visit.")
        if priorities["risk_level"] == "Moderate Aesthetic Discrepancy":
            follow_up.append("Schedule elective clinical consultation if aesthetic modification is desired.")

        # Build Standardized Output Dictionary
        return {
            "phase": "Phase 5 - Clinical Management Recommendation Engine",
            "management_priorities": priorities,
            "clinician_summary": clinician_summary,
            "patient_summary": patient_summary,
            "patient_education": patient_education,
            "possible_management_objectives": management_suggestions,
            "recommendation_explainability": explainability,
            "follow_up_considerations": follow_up,
            "confidence_summary": {
                "overall_confidence": p4.get("confidence_analysis", {}).get("overall_confidence", {}),
                "uncertainty_level": p4.get("uncertainty_analysis", {}).get("uncertainty_level", "Moderate")
            },
            "communication_notes": {
                "philosophy": (
                    "Transforms clinician-oriented findings into clear, supportive, educational, "
                    "patient-friendly communication while preserving original clinical meaning, confidence, and uncertainty."
                ),
                "restricted_words_filtered": True
            },
            "safety_notice": safety_notice
        }
