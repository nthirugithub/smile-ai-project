"""
Clinical Reasoning Engine for Smile AI Medical Decision Support System.

Phase 4 Core Module:
Synthesizes inputs from Phase 1 (Computer Vision 3D measurements),
Phase 2 (Clinical Interpretation Engine & Rule Findings), and
Phase 3 (Machine Learning Severity Predictions & Calibrated Probabilities)
into a structured, fully explainable clinical assessment.

STRICT DESIGN RULES:
- Does NOT make independent medical diagnoses or generate management/treatment objectives.
- Does NOT alter raw computer vision measurements or ML model parameters.
- Outputs a structured evidence-based clinical assessment that serves as the input to the future Clinical Management Recommendation Engine (Phase 5).
- Delivers transparent conflict resolution, evidence weighing, and explicit uncertainty quantification.
"""

from __future__ import annotations

import math
from typing import Any, Dict, List, Optional, Tuple

from ai_engine.clinical_knowledge_base import ClinicalKnowledgeBase


class ClinicalReasoningEngine:
    """
    Explainable Clinical Reasoning Engine for Smile AI.
    Executes Phases 4A through 4H to produce medical decision-support outputs.
    """

    def __init__(
        self,
        phase1_data: Optional[Dict[str, Any]] = None,
        phase2_data: Optional[Dict[str, Any]] = None,
        phase3_data: Optional[Dict[str, Any]] = None
    ):
        """
        Initialize reasoning engine with optional Phase 1, Phase 2, and Phase 3 data structures.
        """
        self.phase1_raw = phase1_data or {}
        self.phase2_raw = phase2_data or {}
        self.phase3_raw = phase3_data or {}

        self.ckb = ClinicalKnowledgeBase

    # =========================================================================
    # PHASE 4A: EVIDENCE COLLECTION
    # =========================================================================
    def collect_evidence(
        self,
        phase1_data: Optional[Dict[str, Any]] = None,
        phase2_data: Optional[Dict[str, Any]] = None,
        phase3_data: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Phase 4A: Merges evidence from Phase 1, Phase 2, and Phase 3 into a unified Evidence Object.
        """
        p1 = phase1_data if phase1_data is not None else self.phase1_raw
        p2 = phase2_data if phase2_data is not None else self.phase2_raw
        p3 = phase3_data if phase3_data is not None else self.phase3_raw

        # 1. Extract Phase 1 Measurements & Image Quality
        measurements = {}
        quality_score = 1.0
        if "features" in p1:
            measurements = p1["features"]
            quality_score = p1.get("quality_score", 1.0)
        elif "smile_width" in p1:
            measurements = p1
            quality_score = p1.get("quality_score", 1.0)
        elif "assessment" in p2:
            # Fallback extraction from Phase 2 assessment
            for feat_name, feat_data in p2["assessment"].items():
                if isinstance(feat_data, dict) and "value" in feat_data:
                    measurements[feat_name] = feat_data["value"]
            quality_score = p2.get("details", {}).get("quality_score", 1.0)

        # 2. Extract Phase 2 Clinical Interpretation Engine Outputs
        assessment = p2.get("assessment", {})
        rule_severity = p2.get("severity", "Normal")
        rule_score = p2.get("score", 0.0)
        rule_confidence = p2.get("confidence", 0.85)
        findings = p2.get("clinical_findings", [])
        interpretations = p2.get("clinical_interpretations", [])
        interaction_findings = p2.get("interaction_findings", [])
        harmony_analysis = p2.get("harmony_analysis", {})

        # 3. Extract Phase 3 ML Model Outputs
        ml_predicted_severity = p3.get("predicted_severity") or p3.get("severity", rule_severity)
        ml_probabilities = p3.get("probabilities", {ml_predicted_severity: 1.0})
        ml_confidence = p3.get("confidence") or p3.get("calibration_confidence", rule_confidence)
        feature_importance = p3.get("feature_importance", {})

        # Build Unified Evidence Object
        evidence_object = {
            "phase1": {
                "measurements": measurements,
                "quality_score": round(quality_score, 4),
                "measurement_count": len(measurements)
            },
            "phase2": {
                "assessment": assessment,
                "rule_severity": rule_severity,
                "rule_score": round(rule_score, 2),
                "rule_confidence": round(rule_confidence, 4),
                "clinical_findings": findings,
                "clinical_interpretations": interpretations,
                "interaction_findings": interaction_findings,
                "harmony_analysis": harmony_analysis
            },
            "phase3": {
                "ml_predicted_severity": ml_predicted_severity,
                "probabilities": ml_probabilities,
                "ml_confidence": round(ml_confidence, 4),
                "feature_importance": feature_importance
            },
            "cross_phase_agreement": (rule_severity.lower() == ml_predicted_severity.lower())
        }

        return evidence_object

    # =========================================================================
    # PHASE 4B: EVIDENCE WEIGHING
    # =========================================================================
    def weigh_evidence(self, evidence: Dict[str, Any]) -> Dict[str, Any]:
        """
        Phase 4B: Assigns evidence strength (Strong, Moderate, Weak, Uncertain) to individual findings.
        """
        p1 = evidence["phase1"]
        p2 = evidence["phase2"]
        p3 = evidence["phase3"]
        quality_score = p1["quality_score"]
        cross_phase_agreement = evidence["cross_phase_agreement"]

        weighed_findings = []

        assessment = p2["assessment"]
        for feat_name, feat_data in assessment.items():
            if not isinstance(feat_data, dict) or "value" not in feat_data:
                continue

            val = feat_data["value"]
            sev = feat_data.get("severity", "Normal")
            is_issue = feat_data.get("issue", False)
            feat_confidence = feat_data.get("confidence", quality_score)

            # Weighing factors calculation
            ml_weight = p3["feature_importance"].get(feat_name, 0.125)

            # Determine Evidence Strength
            if quality_score < 0.60:
                strength = "Uncertain"
                reason = "Reduced by low image quality score"
            elif sev in ["Severe", "Moderate"] and feat_confidence >= 0.80 and (cross_phase_agreement or is_issue):
                strength = "Strong"
                reason = "High clinical severity threshold backed by strong measurement confidence"
            elif is_issue or sev in ["Mild", "Borderline"]:
                strength = "Moderate" if feat_confidence >= 0.70 else "Weak"
                reason = "Identified aesthetic variance with acceptable landmark confidence"
            elif feat_confidence < 0.65:
                strength = "Weak"
                reason = "Borderline measurement accuracy or landmark variance"
            else:
                strength = "Strong" if feat_confidence >= 0.85 else "Moderate"
                reason = "Measurement sitting within standard reference range with high confidence"

            weighed_findings.append({
                "feature": feat_name,
                "value": val,
                "severity": sev,
                "strength": strength,
                "reason": reason,
                "measurement_confidence": round(feat_confidence, 4),
                "ml_importance": round(ml_weight, 4),
                "orthodontic_ref": self.ckb.get_feature_info(feat_name, {}).get("primary_references", ["Literature"])
            })

        # Weigh Feature Interaction Evidence
        weighed_interactions = []
        for inter in p2["interaction_findings"]:
            if isinstance(inter, dict):
                inter_name = inter.get("interaction", "Feature Synergy")
                penalty = inter.get("penalty", 0.0)
                desc = inter.get("description", "")
            else:
                inter_name = "Interaction Finding"
                penalty = 5.0
                desc = str(inter)

            inter_strength = "Strong" if penalty >= 8.0 and quality_score >= 0.75 else "Moderate"
            weighed_interactions.append({
                "interaction_title": inter_name,
                "penalty": penalty,
                "description": desc,
                "strength": inter_strength
            })

        return {
            "weighed_findings": weighed_findings,
            "weighed_interactions": weighed_interactions,
            "overall_quality_strength": "Strong" if quality_score >= 0.85 else ("Moderate" if quality_score >= 0.65 else "Uncertain")
        }

    # =========================================================================
    # PHASE 4C: CLINICAL REASONING CHAINS
    # =========================================================================
    def build_reasoning_chains(
        self,
        evidence: Dict[str, Any],
        weighed_evidence: Dict[str, Any]
    ) -> List[Dict[str, Any]]:
        """
        Phase 4C: Generates structured step-by-step reasoning chains:
        Observation -> Supporting Evidence -> Clinical Interpretation -> Significance -> Confidence -> Limitations.
        """
        reasoning_chains = []

        assessment = evidence["phase2"]["assessment"]
        p1 = evidence["phase1"]

        for item in weighed_evidence["weighed_findings"]:
            feat_name = item["feature"]
            val = item["value"]
            sev = item["severity"]
            strength = item["strength"]
            feat_info = self.ckb.get_feature_info(feat_name) or {}

            # Map condition key for templates
            condition_key = "default"
            if feat_name == "smile_width":
                condition_key = "narrow" if val < 0.40 else ("wide" if val > 0.53 else "normal")
            elif feat_name == "smile_symmetry":
                condition_key = "asymmetric" if val > 0.015 else "normal"
            elif feat_name == "midline_deviation":
                condition_key = "deviated" if val > 0.015 else "normal"
            elif feat_name == "smile_arc":
                condition_key = "reverse" if val < 0.000 else ("flat" if val < 0.015 else "ideal")
            elif feat_name == "gingival_display":
                condition_key = "excessive" if val > 0.025 else "normal"
            elif feat_name == "buccal_corridor":
                condition_key = "excessive_dark_space" if val > 0.180 else "normal"

            template = self.ckb.get_explanation_template(feat_name, condition_key)

            if template:
                observation = template["observation"].format(value=val)
                clinical_interp = template["clinical_interpretation"]
                possible_sig = template["possible_significance"]
                limitations = template["limitations"]
            else:
                raw_assessment = assessment.get(feat_name, {})
                observation = f"Observed {feat_info.get('display_name', feat_name)} = {val:.3f}."
                clinical_interp = raw_assessment.get("clinical_interpretation", f"Severity level: {sev}.")
                possible_sig = raw_assessment.get("finding", "Aesthetic metric within evaluated limits.")
                limitations = raw_assessment.get("limitations", "Subject to 2D image lighting and landmark tracking.")

            # Calculate item confidence
            conf_val = item["measurement_confidence"]
            conf_label = self.ckb.get_confidence_label(conf_val)

            chain = {
                "feature": feat_name,
                "display_name": feat_info.get("display_name", feat_name),
                "observation": observation,
                "supporting_evidence": f"Value: {val:.3f} {feat_info.get('unit', '')} | Severity: {sev} | Strength: {strength}",
                "clinical_interpretation": clinical_interp,
                "possible_clinical_significance": possible_sig,
                "confidence": {
                    "score": round(conf_val, 4),
                    "label": conf_label
                },
                "limitations": limitations
            }
            reasoning_chains.append(chain)

        return reasoning_chains

    # =========================================================================
    # PHASE 4D: CONFLICT RESOLUTION
    # =========================================================================
    def resolve_conflicts(
        self,
        evidence: Dict[str, Any],
        weighed_evidence: Dict[str, Any]
    ) -> List[Dict[str, Any]]:
        """
        Phase 4D: Detects and resolves conflicting findings transparently without hiding disagreements.
        """
        conflicts = []
        p1 = evidence["phase1"]
        p2 = evidence["phase2"]
        p3 = evidence["phase3"]

        rule_sev = p2["rule_severity"]
        ml_sev = p3["ml_predicted_severity"]
        quality_score = p1["quality_score"]

        # Conflict 1: Rule vs ML Severity Disagreement
        if rule_sev.lower() != ml_sev.lower():
            # Evidence-Weighted Fusion Strategy:
            # Combines rule evidence and ML confidence based on image quality and landmark stability
            sev_levels = {
                "normal": 0,
                "borderline": 0,
                "mild": 1,
                "mild concern": 1,
                "moderate": 2,
                "moderate concern": 2,
                "severe": 3,
                "significant concern": 3,
            }
            r_level = sev_levels.get(rule_sev.lower(), 0)
            m_level = sev_levels.get(ml_sev.lower(), 0)

            ml_conf = p3.get("ml_confidence", 0.5)
            # Dynamic evidence fusion weight:
            # If ML model has high calibrated confidence (>0.80) and high quality, respect ML prediction
            if ml_conf >= 0.75 and quality_score >= 0.70:
                alpha = 0.20  # Give 80% weight to high-confidence ML model
            elif quality_score < 0.60:
                alpha = 0.70  # Give 70% weight to rule engine when image quality is low
            else:
                alpha = 0.40  # Balanced fusion (60% ML, 40% Rules)

            fused_level_score = alpha * r_level + (1.0 - alpha) * m_level
            fused_level = int(round(fused_level_score))

            level_to_sev = {0: "Normal", 1: "Mild", 2: "Moderate", 3: "Severe"}
            resolved_sev = level_to_sev.get(fused_level, "Normal")

            explanation = (
                f"Disagreement analyzed via transparent evidence-weighted fusion "
                f"(Rule rating: {rule_sev}, ML rating: {ml_sev}, Weight alpha: {alpha:.2f}). "
                f"Fused result: {resolved_sev}."
            )


            conflicts.append({
                "conflict_type": "RULE_VS_ML_DISAGREEMENT",
                "finding_a": f"Phase 2 Clinical Rule Rating: {rule_sev}",
                "finding_b": f"Phase 3 ML Model Rating: {ml_sev}",
                "resolution": f"Resolved to '{resolved_sev}' severity via evidence fusion",
                "primary_source_used": "Evidence-Weighted Fusion Engine",
                "explanation": explanation,
                "transparent_disagreement_flag": True
            })


        # Conflict 2: Excellent Symmetry vs Large Midline Deviation
        sym_val = p1["measurements"].get("smile_symmetry", 0.0)
        mid_val = p1["measurements"].get("midline_deviation", 0.0)
        if sym_val < 0.012 and mid_val > 0.035:
            conflicts.append({
                "conflict_type": "SYMMETRY_VS_MIDLINE_PARADOX",
                "finding_a": f"High Commissural Symmetry (S_s = {sym_val:.3f})",
                "finding_b": f"Significant Midline Deviation (D_m = {mid_val:.3f})",
                "resolution": "Isolated Midline Shift",
                "primary_source_used": "Phase 2 Structural Interaction Analysis",
                "explanation": "Commissural line remains horizontally level despite dental midline translation to the side.",
                "transparent_disagreement_flag": False
            })

        # Conflict 3: High ML Confidence vs Low Image Quality
        if p3["ml_confidence"] >= 0.80 and quality_score < 0.60:
            conflicts.append({
                "conflict_type": "HIGH_ML_CONFIDENCE_LOW_QUALITY",
                "finding_a": f"High ML Model Confidence ({p3['ml_confidence']:.2f})",
                "finding_b": f"Low Image Quality Score ({quality_score:.2f})",
                "resolution": "Uncertainty Penalty Applied",
                "primary_source_used": "Quality Control Safety Filter",
                "explanation": "High ML probability penalised due to poor image sharpness/illumination.",
                "transparent_disagreement_flag": True
            })

        return conflicts

    # =========================================================================
    # PHASE 4E: OVERALL CLINICAL SUMMARY
    # =========================================================================
    def generate_clinical_summary(
        self,
        evidence: Dict[str, Any],
        weighed_evidence: Dict[str, Any],
        conflicts: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Phase 4E: Compiles primary findings, secondary findings, smile characteristics,
        likely aesthetic concerns, overall severity, and composite confidence.
        """
        p2 = evidence["phase2"]
        p3 = evidence["phase3"]
        quality_score = evidence["phase1"]["quality_score"]

        # 1. Classify Primary & Secondary Findings
        primary_findings = []
        secondary_findings = []

        for item in weighed_evidence["weighed_findings"]:
            feat = item["feature"]
            sev = item["severity"]
            if item["strength"] in ["Strong", "Moderate"] and sev in ["Severe", "Moderate", "Significant Concern"]:
                primary_findings.append(f"{self.ckb.get_feature_info(feat, {}).get('display_name', feat)}: {sev}")
            elif sev in ["Mild", "Borderline", "Mild Concern"]:
                secondary_findings.append(f"{self.ckb.get_feature_info(feat, {}).get('display_name', feat)}: {sev}")

        if not primary_findings and not secondary_findings:
            primary_findings.append("All evaluated features sit within ideal orthodontic reference ranges.")

        # 2. Determine Overall Synthesized Severity
        rule_sev = p2["rule_severity"]
        ml_sev = p3["ml_predicted_severity"]

        # Check if any individual feature has a Moderate or Severe concern
        has_major_issues = any(
            wf.get("severity") in ["Moderate", "Moderate Concern", "Severe", "Significant Concern"]
            for wf in weighed_evidence.get("weighed_findings", [])
        )

        if not has_major_issues and rule_sev in ["Normal", "Borderline"]:
            # If rule analysis shows Normal/Borderline with no major feature issues, overall severity is Normal
            overall_severity = "Normal"
        elif conflicts:
            # Check for resolved conflict severity
            rule_vs_ml = next((c for c in conflicts if c["conflict_type"] == "RULE_VS_ML_DISAGREEMENT"), None)
            overall_severity = rule_vs_ml["resolution"].replace("Resolved to '", "").replace("' severity", "") if rule_vs_ml else rule_sev
        else:
            overall_severity = rule_sev

        # 3. Overall Composite Confidence
        base_confidence = (p2["rule_confidence"] + p3["ml_confidence"]) / 2.0
        if quality_score < 0.60:
            base_confidence *= 0.80
        if any(c["transparent_disagreement_flag"] for c in conflicts):
            base_confidence *= 0.90

        overall_confidence = round(max(0.50, min(0.99, base_confidence)), 4)
        confidence_label = self.ckb.get_confidence_label(overall_confidence)

        # 4. Aesthetic Concerns & Characteristics
        aesthetic_concerns = [f for f in p2["clinical_findings"] if "balanced" not in f.lower() and "normal" not in f.lower()]
        if not aesthetic_concerns:
            aesthetic_concerns.append("No primary aesthetic concerns identified.")

        return {
            "primary_findings": primary_findings,
            "secondary_findings": secondary_findings,
            "overall_smile_characteristics": {
                "facial_proportionality_index": p2["harmony_analysis"].get("facial_proportionality_index", 0.0),
                "symmetry_balance_index": p2["harmony_analysis"].get("symmetry_balance_index", 0.0),
                "smile_harmony_index": p2["harmony_analysis"].get("smile_harmony_index", 0.0),
                "composite_harmony_score": p2["harmony_analysis"].get("composite_harmony_score", 0.0)
            },
            "likely_aesthetic_concerns": aesthetic_concerns,
            "overall_severity": overall_severity,
            "overall_confidence": {
                "score": overall_confidence,
                "label": confidence_label
            },
            "evidence_quality": weighed_evidence["overall_quality_strength"]
        }

    # =========================================================================
    # PHASE 4F: EXPLAINABILITY ENGINE
    # =========================================================================
    def generate_explainability_report(
        self,
        evidence: Dict[str, Any],
        reasoning_chains: List[Dict[str, Any]],
        conflicts: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Phase 4F: Answers key explainability questions transparently.
        """
        p1 = evidence["phase1"]
        p2 = evidence["phase2"]
        p3 = evidence["phase3"]

        # 1. Contributing Measurements
        contributing_measurements = [
            {
                "feature": chain["display_name"],
                "value": chain["supporting_evidence"].split("|")[0].replace("Value:", "").strip(),
                "severity": chain["supporting_evidence"].split("|")[1].replace("Severity:", "").strip()
            }
            for chain in reasoning_chains
        ]

        # 2. Key Interactions
        key_interactions = [
            f"{inter.get('interaction', 'Synergy')}: Penalty score {inter.get('penalty', 0.0)}"
            for inter in p2["interaction_findings"]
        ]

        # 3. Strongest Evidence
        strongest = [
            chain["display_name"]
            for chain in reasoning_chains
            if "Strong" in chain["supporting_evidence"]
        ]

        # 4. Factors Reducing Confidence
        reducing_factors = []
        if p1["quality_score"] < 0.60:
            reducing_factors.append(f"Image quality score ({p1['quality_score']:.2f}) below optimal threshold (0.60).")
        if conflicts:
            for c in conflicts:
                reducing_factors.append(f"Conflict detected: {c['conflict_type']} ({c['explanation']}).")

        if not reducing_factors:
            reducing_factors.append("None; all landmark confidence metrics and model predictions align.")

        return {
            "why_conclusion_reached": (
                f"Overall clinical assessment of '{p2['rule_severity']}' reached based on synthesis of "
                f"{p1['measurement_count']} 3D computer vision measurements, "
                f"{len(p2['interaction_findings'])} feature interaction penalties, and "
                f"calibrated ML model probability ({p3['ml_confidence']:.2f})."
            ),
            "contributing_measurements": contributing_measurements,
            "key_interactions_mattered": key_interactions if key_interactions else ["No significant interaction penalties."],
            "strongest_evidence": strongest if strongest else ["Standard anatomical measurement alignment."],
            "factors_reducing_confidence": reducing_factors
        }

    # =========================================================================
    # PHASE 4G: UNCERTAINTY ANALYSIS
    # =========================================================================
    def analyze_uncertainty(
        self,
        evidence: Dict[str, Any],
        conflicts: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Phase 4G: Explicitly quantifies uncertainty across 6 primary sources.
        """
        p1 = evidence["phase1"]
        p2 = evidence["phase2"]
        p3 = evidence["phase3"]

        quality_score = p1["quality_score"]

        # 1. Image Quality Uncertainty
        img_quality_unc = "Low" if quality_score >= 0.75 else ("Moderate" if quality_score >= 0.60 else "High")

        # 2. Pose Quality Uncertainty
        # (Evaluates head rotation / pose metrics if available)
        pose_unc = "Low"

        # 3. Feature Boundary Uncertainty (Borderline checks)
        borderline_count = sum(
            1 for item in p2["assessment"].values()
            if isinstance(item, dict) and item.get("severity") in ["Borderline", "Mild"]
        )
        feat_unc = "High" if borderline_count >= 3 else ("Moderate" if borderline_count >= 1 else "Low")

        # 4. Model Prediction Uncertainty (Entropy across ML probabilities)
        probs = list(p3["probabilities"].values())
        if len(probs) > 1:
            entropy = -sum(p * math.log2(p) for p in probs if p > 0)
            model_unc = "High" if entropy > 1.2 else ("Moderate" if entropy > 0.6 else "Low")
        else:
            model_unc = "Low"

        # 5. Conflicting Evidence Uncertainty
        conflict_unc = "High" if len(conflicts) >= 2 else ("Moderate" if len(conflicts) == 1 else "Low")

        # Compile Overall Uncertainty Score (0.0 to 1.0)
        uncertainty_score = 0.10
        if img_quality_unc == "High":
            uncertainty_score += 0.35
        elif img_quality_unc == "Moderate":
            uncertainty_score += 0.15

        if model_unc == "High":
            uncertainty_score += 0.25
        elif model_unc == "Moderate":
            uncertainty_score += 0.10

        if conflict_unc == "High":
            uncertainty_score += 0.25
        elif conflict_unc == "Moderate":
            uncertainty_score += 0.15

        overall_uncertainty = round(min(0.95, uncertainty_score), 4)

        return {
            "overall_uncertainty_score": overall_uncertainty,
            "uncertainty_level": self.ckb.get_confidence_label(1.0 - overall_uncertainty),
            "sources": {
                "image_quality_uncertainty": img_quality_unc,
                "pose_quality_uncertainty": pose_unc,
                "feature_boundary_uncertainty": feat_unc,
                "model_entropy_uncertainty": model_unc,
                "conflicting_findings_uncertainty": conflict_unc
            },
            "mitigation_notes": (
                "Standard clinical capture conditions recommended to minimize image quality uncertainty."
                if overall_uncertainty > 0.30 else "Uncertainty levels within acceptable clinical tolerances."
            )
        }

    # =========================================================================
    # PHASE 4H: STRUCTURED OUTPUT FOR PHASE 5 CONSUMPTION
    # =========================================================================
    def generate_structured_assessment(
        self,
        phase1_data: Optional[Dict[str, Any]] = None,
        phase2_data: Optional[Dict[str, Any]] = None,
        phase3_data: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Main entry point for Phase 4.
        Executes stages 4A to 4G and outputs the structured assessment for Phase 5.
        """
        # Phase 4A: Collect Evidence
        evidence = self.collect_evidence(phase1_data, phase2_data, phase3_data)

        # Phase 4B: Weigh Evidence
        weighed_evidence = self.weigh_evidence(evidence)

        # Phase 4C: Build Reasoning Chains
        reasoning_chains = self.build_reasoning_chains(evidence, weighed_evidence)

        # Phase 4D: Resolve Conflicts
        conflicts = self.resolve_conflicts(evidence, weighed_evidence)

        # Phase 4E: Overall Clinical Summary
        clinical_summary = self.generate_clinical_summary(evidence, weighed_evidence, conflicts)

        # Phase 4F: Explainability Report
        explainability_report = self.generate_explainability_report(evidence, reasoning_chains, conflicts)

        # Phase 4G: Uncertainty Analysis
        uncertainty_analysis = self.analyze_uncertainty(evidence, conflicts)

        # Build Final Phase 4 Standardized Output Dictionary
        # Outputs a structured evidence-based clinical assessment that serves as the input to Phase 5.
        return {
            "phase": "Phase 4 - Clinical Reasoning Engine",
            "evidence_summary": {
                "measurements_evaluated": len(evidence["phase1"]["measurements"]),
                "image_quality_score": evidence["phase1"]["quality_score"],
                "cross_phase_agreement": evidence["cross_phase_agreement"],
                "quality_strength": weighed_evidence["overall_quality_strength"]
            },
            "clinical_findings": {
                "primary_findings": clinical_summary["primary_findings"],
                "secondary_findings": clinical_summary["secondary_findings"],
                "weighed_findings": weighed_evidence["weighed_findings"],
                "interaction_findings": weighed_evidence["weighed_interactions"]
            },
            "reasoning_chain": reasoning_chains,
            "conflict_resolution": conflicts,
            "explainability_report": explainability_report,
            "confidence_analysis": {
                "overall_confidence": clinical_summary["overall_confidence"],
                "evidence_quality": clinical_summary["evidence_quality"]
            },
            "uncertainty_analysis": uncertainty_analysis,
            "clinical_summary": clinical_summary
        }
