"""
Clinical Interpretation Engine for Smile AI Decision Support System.

Refactored from severity_classifier.py.
Converts raw 3D computer vision measurements into structured clinical decision support findings
grounded in established orthodontic literature (Ackerman, Hulsey, Kokich, Sarver, Tjan, Martin, Dong, Farkas).

Features Evaluated (Inputs):
1. Smile Width (W_s)
2. Smile Symmetry (S_s)
3. Midline Deviation (D_m)
4. Smile Arc (A_s)
5. Gingival Display (G_d)
6. Buccal Corridor (BCR)
7. Lip Opening (O_l)
8. Face Ratio (R_f)

Outputs:
- Structured Clinical Findings & Observations
- Measurement Validation & Quality Confidence
- 5-Way Feature Interaction Analysis
- Smile & Facial Harmony Engine Indices
- Overall Severity & Decision Support Summary
"""

from __future__ import annotations

import math
from typing import Any, Dict, List, Optional


class ClinicalInterpretationEngine:
    """
    Medical-grade Clinical Interpretation Engine for Smile AI.
    Prepares structured information for ML models, clinical reasoning, and decision support.
    """

    # ---------------------------------------------------------
    # CLINICAL THRESHOLDS & MEDICAL REFERENCE MATRICES
    # ---------------------------------------------------------
    # Based on orthodontic and facial aesthetic literature:
    # Ackerman et al. (2004), Hulsey (1970), Kokich et al. (1999), Sarver (2001),
    # Tjan et al. (1984), Martin et al. (2007), Dong et al. (1993), Farkas (1994).

    THRESHOLDS = {
        "smile_width": {
            "normal": (0.420, 0.520),
            "borderline": [(0.380, 0.419), (0.521, 0.550)],
            "mild": [(0.340, 0.379), (0.551, 0.580)],
            "moderate": [(0.300, 0.339)],
            "severe_low": 0.300,
            "severe_high": 0.580,
            "unit": "ratio (CW/ZW)",
            "ref": "Ackerman et al. (2004)"
        },
        "smile_symmetry": {
            "normal": (0.000, 0.015),
            "borderline": (0.016, 0.025),
            "mild": (0.026, 0.035),
            "moderate": (0.036, 0.050),
            "severe": 0.050,
            "unit": "ratio (vert diff / MorphH)",
            "ref": "Hulsey (1970), Naini (2011)"
        },
        "midline_deviation": {
            "normal": (0.000, 0.015),
            "borderline": (0.016, 0.025),
            "mild": (0.026, 0.035),
            "moderate": (0.036, 0.050),
            "severe": 0.050,
            "unit": "ratio (dev / ZW)",
            "ref": "Kokich et al. (1999)"
        },
        "smile_arc": {
            "ideal_consonant": (0.250, 0.400),
            "borderline": (0.100, 0.249),
            "mild": (0.050, 0.099),
            "moderate": (0.000, 0.049),
            "severe_reverse": 0.000,
            "unit": "chord-height ratio (h/CW)",
            "ref": "Sarver & Ackerman (2003)"
        },
        "gingival_display": {
            "normal": (0.000, 0.020),
            "borderline": (0.021, 0.030),
            "mild": (0.031, 0.045),
            "moderate": (0.046, 0.065),
            "severe": 0.065,
            "unit": "ratio (lip elevation / MorphH)",
            "ref": "Tjan et al. (1984), Robbins (1999)"
        },
        "buccal_corridor": {
            "normal": (0.100, 0.180),
            "borderline": [(0.060, 0.099), (0.181, 0.230)],
            "mild": [(0.030, 0.059), (0.231, 0.280)],
            "moderate": [(0.010, 0.029), (0.281, 0.350)],
            "severe_high": 0.350,
            "unit": "ratio (negative space / CW)",
            "ref": "Martin et al. (2007), Moore et al. (2005)"
        },
        "lip_opening": {
            "normal": (0.060, 0.160),
            "borderline": [(0.040, 0.059), (0.161, 0.200)],
            "mild": [(0.025, 0.039), (0.201, 0.240)],
            "moderate": [(0.010, 0.024), (0.241, 0.300)],
            "severe_high": 0.300,
            "unit": "ratio (gap / MorphH)",
            "ref": "Dong et al. (1993) - smile position adjusted"
        },
        "face_ratio": {
            "mesoprosopic_normal": (1.150, 1.450),
            "borderline": [(1.050, 1.149), (1.451, 1.550)],
            "mild": [(0.950, 1.049), (1.551, 1.650)],
            "moderate": [(0.850, 0.949), (1.651, 1.800)],
            "severe_high": 1.800,
            "unit": "ratio (ZW / MorphH)",
            "ref": "Farkas Morphometric Index (1994)"
        }
    }


    def __init__(self, features: Dict[str, float]):
        self.features = features or {}

    # ---------------------------------------------------------
    # BASIC HELPERS
    # ---------------------------------------------------------

    @staticmethod
    def _clamp(value: float, low: float = 0.0, high: float = 1.0) -> float:
        return max(low, min(high, value))

    def _get(self, key: str, default: float = 0.0) -> float:
        try:
            val = self.features.get(key, default)
            if val is None or math.isnan(float(val)):
                return float(default)
            return float(val)
        except (TypeError, ValueError):
            return float(default)

    # ---------------------------------------------------------
    # INDIVIDUAL FEATURE INTERPRETATION GENERATORS
    # ---------------------------------------------------------

    def _interpret_smile_width(self, val: float) -> Dict[str, Any]:
        ref = self.THRESHOLDS["smile_width"]
        if 0.42 <= val <= 0.52:
            sev = "Normal"
            pen = 0.0
            obs = "Normal Smile Width"
            interp = "Harmonious transverse inter-commissural smile width ratio (Ackerman et al. 2004)."
        elif 0.38 <= val < 0.42 or 0.52 < val <= 0.55:
            sev = "Borderline"
            pen = 2.0
            obs = "Borderline Smile Width"
            interp = "Slight transverse deviation; smile width span is near clinical reference boundary."
        elif 0.34 <= val < 0.38 or 0.55 < val <= 0.58:
            sev = "Mild Concern"
            pen = 4.5
            obs = "Narrow Transverse Smile Band" if val < 0.38 else "Slightly Broad Smile Span"
            interp = "Transverse narrowing observed. Potential candidate for arch expansion evaluation."
        elif 0.30 <= val < 0.34:
            sev = "Moderate Concern"
            pen = 7.0
            obs = "Moderately Constricted Smile Arch"
            interp = "Moderate transverse maxillary arch constriction. Correlates with enlarged buccal corridors."
        else:
            sev = "Significant Concern"
            pen = 8.0
            obs = "Severe Transverse Maxillary Constriction" if val < 0.30 else "Excessive Transverse Width"
            interp = "Significant transverse arch mismatch requiring comprehensive orthodontic evaluation."

        return {
            "value": round(val, 4),
            "threshold": "0.42 - 0.52",
            "issue": sev not in ("Normal", "Borderline"),
            "penalty": round(pen, 2),
            "finding": obs,
            "clinical_interpretation": interp,
            "severity": sev,
            "confidence": 0.95,
            "evidence": f"Measured CW/ZW ratio: {val:.4f}",
            "limitations": "2D projection plane; requires 3D dental model verification."
        }

    def _interpret_smile_symmetry(self, val: float) -> Dict[str, Any]:
        if val <= 0.012:
            sev = "Normal"
            pen = 0.0
            obs = "Symmetric Smile Alignment"
            interp = "Bilateral commissure height alignment is clinically symmetric relative to interpupillary line (Hulsey 1970)."
        elif val <= 0.020:
            sev = "Borderline"
            pen = 5.0
            obs = "Mild Sub-clinical Asymmetry"
            interp = "Minor vertical commissure differential (< 2mm); clinically imperceptible to laypeople."
        elif val <= 0.035:
            sev = "Mild Concern"
            pen = 11.0
            obs = "Noticeable Occlusal / Commissure Cant"
            interp = "Noticeable vertical asymmetry. Suggests potential occlusal cant or unilateral muscle activation."
        elif val <= 0.050:
            sev = "Moderate Concern"
            pen = 18.0
            obs = "Moderate Facial & Smile Asymmetry"
            interp = "Moderate asymmetric cant of mouth commissures relative to horizontal facial baseline."
        else:
            sev = "Significant Concern"
            pen = 22.0
            obs = "Severe Facial Asymmetric Cant"
            interp = "Significant bilateral vertical discrepancy (> 5% facial height). Indicates potential skeletal cant or facial nerve asymmetry."

        return {
            "value": round(val, 4),
            "threshold": "< 0.012",
            "issue": sev not in ("Normal", "Borderline"),
            "penalty": round(pen, 2),
            "finding": obs,
            "clinical_interpretation": interp,
            "severity": sev,
            "confidence": 0.94,
            "evidence": f"Measured vertical cant ratio: {val:.4f}",
            "limitations": "Sensitive to uncorrected head roll tilt."
        }

    def _interpret_midline_deviation(self, val: float) -> Dict[str, Any]:
        # 2D X-axis lateral deviation, normalized by bizygomatic width.
        # Literature: < 0.015 = normal (Kokich et al. 1999)
        if val <= 0.015:
            sev = "Normal"
            pen = 0.0
            obs = "Coincident Facial Midline"
            interp = "Labial frenum / upper lip midline is coincident with Subnasale-Nasion facial midline (Kokich et al. 1999)."
        elif val <= 0.025:
            sev = "Borderline"
            pen = 4.0
            obs = "Minor Midline Shift"
            interp = "Slight lateral midline shift (< 2.5mm); clinically acceptable in aesthetic evaluations."
        elif val <= 0.040:
            sev = "Mild Concern"
            pen = 10.0
            obs = "Noticeable Dental Midline Deviation"
            interp = "Noticeable lateral midline displacement. Indicates dental or soft-tissue shift."
        elif val <= 0.060:
            sev = "Moderate Concern"
            pen = 17.0
            obs = "Moderate Midline Deviation"
            interp = "Moderate lateral midline shift. Potential dental arch asymmetry or mandibular shift."
        else:
            sev = "Significant Concern"
            pen = 22.0
            obs = "Severe Facial / Dental Midline Cant"
            interp = "Significant dental midline deviation. Requires diagnostic intra-oral tracing."

        return {
            "value": round(val, 4),
            "threshold": "< 0.015",
            "issue": sev not in ("Normal", "Borderline"),
            "penalty": round(pen, 2),
            "finding": obs,
            "clinical_interpretation": interp,
            "severity": sev,
            "confidence": 0.93,
            "evidence": f"Measured 2D lateral midline shift ratio: {val:.4f}",
            "limitations": "Evaluates soft-tissue labial frenum X-axis deviation from nasion-subnasale midline."
        }

    def _interpret_smile_arc(self, val: float) -> Dict[str, Any]:
        """
        Smile arc thresholds calibrated for chord-height curvature ratio (Sarver & Ackerman 2003).
        The chord-height ratio h/CW for smiling faces:
          Ideal consonant arc:  0.25 - 0.40
          Acceptable flat arc:  0.10 - 0.25
          Borderline flat:      0.05 - 0.10
          Reversed / flat:      0.00 - 0.05
          Significant reverse: < 0.00
        """
        if 0.25 <= val <= 0.40:
            sev = "Normal"
            pen = 0.0
            obs = "Ideal Consonant Smile Arc"
            interp = (
                "Ideal harmonious smile arc; lower lip midpoint curves upward relative to "
                "commissures, paralleling the curvature of maxillary incisal edges (Sarver & Ackerman 2003)."
            )
        elif 0.10 <= val < 0.25 or 0.40 < val <= 0.40:
            sev = "Borderline"
            pen = 3.0
            obs = "Mildly Flat Smile Arc"
            interp = (
                "Mildly reduced lip curvature; slight flattening of the consonant smile arc. "
                "Within acceptable esthetic variation for older or natural smile patterns."
            )
        elif 0.05 <= val < 0.10:
            sev = "Mild Concern"
            pen = 6.0
            obs = "Flat Smile Arc"
            interp = (
                "Flat horizontal smile line. Loss of natural parabolic lower lip curvature "
                "during full smile. May benefit from esthetic anterior tooth reshaping."
            )
        elif 0.00 <= val < 0.05:
            sev = "Moderate Concern"
            pen = 8.5
            obs = "Severely Flat / Borderline Reversed Smile Arc"
            interp = (
                "Near-absent or inverted lip curve relative to commissures. Indicates potential "
                "reverse smile arc tendency; incisal edges may slope away from the lower lip line."
            )
        else:
            sev = "Significant Concern"
            pen = 10.0
            obs = "Reverse / Inverted Smile Arc"
            interp = (
                "Significant reverse smile arc; lower lip bows downward relative to commissure chord. "
                "Maxillary anterior teeth slope upward relative to commissures. "
                "Comprehensive orthodontic and esthetic evaluation recommended."
            )

        return {
            "value": round(val, 4),
            "threshold": "0.25 - 0.40",
            "issue": sev not in ("Normal", "Borderline"),
            "penalty": round(pen, 2),
            "finding": obs,
            "clinical_interpretation": interp,
            "severity": sev,
            "confidence": 0.91,
            "evidence": f"Chord-height curvature ratio (h/CW): {val:.4f}",
            "limitations": (
                "Chord-height ratio measured from lower lip midpoint (LM17) to commissure chord. "
                "Accuracy depends on accurate commissure and lip landmark localization."
            )
        }

    def _interpret_gingival_display(self, val: float) -> Dict[str, Any]:
        # 2D Y-axis vertical elevation ratio. Recalibrated baseline = 0.12 (smile position).
        if val <= 0.020:
            sev = "Normal"
            pen = 0.0
            obs = "Normal Smile Line / Ideal Exposure"
            interp = "Ideal smile line; lip elevation displays 75-100% of maxillary teeth with < 2mm gingival exposure (Tjan et al. 1984)."
        elif val <= 0.035:
            sev = "Borderline"
            pen = 3.0
            obs = "Slight Gingival Display"
            interp = "Slight gingival exposure (2-3mm); within normal esthetic variation for active smile."
        elif val <= 0.055:
            sev = "Mild Concern"
            pen = 7.0
            obs = "Moderate Gummy Smile Line"
            interp = "Moderate gingival display (3-4mm). Indicates hypermobile lip or mild vertical maxillary excess."
        elif val <= 0.080:
            sev = "Moderate Concern"
            pen = 12.0
            obs = "High Gummy Smile Line (VME)"
            interp = "High gingival display (4-6mm). Suggests Vertical Maxillary Excess (VME) or short upper lip."
        else:
            sev = "Significant Concern"
            pen = 16.0
            obs = "Excessive Gummy Smile Line"
            interp = "Excessive gingival exposure (> 6mm). Comprehensive periodontic/orthognathic evaluation recommended."

        return {
            "value": round(val, 4),
            "threshold": "< 0.020",
            "issue": sev not in ("Normal", "Borderline"),
            "penalty": round(pen, 2),
            "finding": obs,
            "clinical_interpretation": interp,
            "severity": sev,
            "confidence": 0.94,
            "evidence": f"2D vertical gingival elevation ratio: {val:.4f}",
            "limitations": "Soft-tissue vertical proxy based on Y-axis distance between upper stomion and subnasale."
        }

    def _interpret_buccal_corridor(self, val: float) -> Dict[str, Any]:
        if 0.100 <= val <= 0.180:
            sev = "Normal"
            pen = 0.0
            obs = "Esthetic Buccal Corridor"
            interp = "Ideal lateral negative space (10%-18%) between dental arch and commissures (Martin et al. 2007)."
        elif 0.060 <= val < 0.100 or 0.180 < val <= 0.230:
            sev = "Borderline"
            pen = 3.0
            obs = "Borderline Buccal Corridor"
            interp = "Slight variation in lateral vestibule negative space."
        elif 0.030 <= val < 0.060 or 0.230 < val <= 0.280:
            sev = "Mild Concern"
            pen = 6.0
            obs = "Narrow Corridor (Broad Arch)" if val < 0.060 else "Enlarged Dark Buccal Corridor"
            interp = "Prominent negative space; suggests transverse arch narrowing or palatal collapse."
        elif val < 0.030 or 0.280 < val <= 0.350:
            sev = "Moderate Concern"
            pen = 8.5
            obs = "Severely Enlarged Dark Corridor"
            interp = "Excessive dark buccal corridors (> 28%). Correlates with constricted maxillary arch."
        else:
            sev = "Significant Concern"
            pen = 10.0
            obs = "Collapsed Arch / Extreme Corridor Space"
            interp = "Severe lateral negative space discrepancy (> 35%). Indicates significant maxillary constriction."

        return {
            "value": round(val, 4),
            "threshold": "0.100 - 0.180",
            "issue": sev not in ("Normal", "Borderline"),
            "penalty": round(pen, 2),
            "finding": obs,
            "clinical_interpretation": interp,
            "severity": sev,
            "confidence": 0.92,
            "evidence": f"Buccal corridor ratio: {val:.4f}",
            "limitations": "Depends on intra-oral illumination and cheek soft-tissue thickness."
        }

    def _interpret_lip_opening(self, val: float) -> Dict[str, Any]:
        # Recalibrated for smile-position: during active smiling, lip gap of
        # 0.06-0.16 MorphH (roughly 8-22mm) is normal and expected.
        if 0.060 <= val <= 0.160:
            sev = "Normal"
            pen = 0.0
            obs = "Normal Inter-labial Gap"
            interp = "Normal incisal display and lip opening during smile (Dong et al. 1993)."
        elif 0.040 <= val < 0.060 or 0.161 <= val <= 0.200:
            sev = "Borderline"
            pen = 2.5
            obs = "Minor Lip Opening Variation"
            interp = "Slight deviation in inter-labial gap; clinically within esthetic tolerance."
        elif 0.025 <= val < 0.040 or 0.201 <= val <= 0.240:
            sev = "Mild Concern"
            pen = 6.0
            obs = "Narrow Inter-labial Gap" if val < 0.040 else "Wide Lip Opening"
            interp = "Narrow incisal display during smile may mask anterior dentition." if val < 0.040 else "Increased lip opening during smile."
        elif 0.010 <= val < 0.025 or 0.241 <= val <= 0.300:
            sev = "Moderate Concern"
            pen = 10.0
            obs = "Markedly Reduced Display" if val < 0.025 else "Excessive Lip Opening"
            interp = "Substantially reduced anterior dental exposure." if val < 0.025 else "Significantly increased inter-labial gap."
        else:
            sev = "Significant Concern"
            pen = 14.0
            obs = "Severely Restricted / Excessive Lip Opening"
            interp = "Extreme variation in lip opening; requires clinical assessment."

        return {
            "value": round(val, 4),
            "threshold": "0.060 - 0.160",
            "issue": sev not in ("Normal", "Borderline"),
            "penalty": round(pen, 2),
            "finding": obs,
            "clinical_interpretation": interp,
            "severity": sev,
            "confidence": 0.91,
            "evidence": f"Measured inter-labial gap ratio: {val:.4f}",
            "limitations": "Measured during smile expression; resting lip position requires separate clinical evaluation."
        }


    def _interpret_face_ratio(self, val: float) -> Dict[str, Any]:
        if 1.200 <= val <= 1.450:
            sev = "Normal"
            pen = 0.0
            obs = "Mesoprosopic Facial Morphology"
            interp = "Harmonious facial index (Farkas 1994). Balanced ratio of bizygomatic width to morphometric height."
        elif 1.100 <= val < 1.200 or 1.450 < val <= 1.550:
            sev = "Borderline"
            pen = 2.0
            obs = "Slight Leptoprosopic Tendency" if val < 1.200 else "Slight Euryprosopic Tendency"
            interp = "Facial morphology sits near standard morphometric limits."
        elif 1.000 <= val < 1.100 or 1.550 < val <= 1.650:
            sev = "Mild Concern"
            pen = 3.5
            obs = "Leptoprosopic (Long Face) Pattern" if val < 1.100 else "Euryprosopic (Broad Face) Pattern"
            interp = "Elongated facial morphology. Often associated with vertical maxillary excess."
        elif val < 1.000 or 1.650 < val <= 1.800:
            sev = "Moderate Concern"
            pen = 4.5
            obs = "Severe Long Face Pattern" if val < 1.000 else "Severe Broad Face Pattern"
            interp = "Significant morphometric index deviation. Correlates with craniofacial growth patterns."
        else:
            sev = "Significant Concern"
            pen = 5.0
            obs = "Extreme Craniofacial Morphometric Discrepancy"
            interp = "Severe facial height-to-width proportion mismatch."

        return {
            "value": round(val, 4),
            "threshold": "1.200 - 1.450",
            "issue": sev not in ("Normal", "Borderline"),
            "penalty": round(pen, 2),
            "finding": obs,
            "clinical_interpretation": interp,
            "severity": sev,
            "confidence": 0.95,
            "evidence": f"Morphometric index (ZW/MorphH): {val:.4f}",
            "limitations": "Soft-tissue morphometric proxy; uncorrected for skeletal bone thickness."
        }

    # ---------------------------------------------------------
    # PHASE 2E: FEATURE INTERACTION ANALYSIS ENGINE
    # ---------------------------------------------------------

    def analyze_feature_interactions(
        self,
        assessments: Dict[str, Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """
        Evaluates 5 clinical feature synergies:
        1. Transverse Arch Synergy (Smile Width + Buccal Corridor)
        2. Vertical Animated Display (Smile Arc + Lip Opening)
        3. Midline & Asymmetry Synergy (Midline + Symmetry)
        4. Craniofacial Proportionality (Face Ratio + Smile Width)
        5. Gingivo-Incisal Harmony (Smile Arc + Gingival Display)
        """
        interactions = []

        w = assessments["smile_width"]["value"]
        bc = assessments["buccal_corridor"]["value"]
        arc = assessments["smile_arc"]["value"]
        opening = assessments["lip_opening"]["value"]
        midline = assessments["midline"]["value"]
        sym = assessments["symmetry"]["value"]
        ratio = assessments["face_ratio"]["value"]
        gummy = assessments["gingival_display"]["value"]

        # 1. Transverse Arch Synergy
        if w < 0.38 and bc > 0.22:
            interactions.append({
                "synergy": "Transverse Maxillary Arch Constriction",
                "finding": "Narrow smile width combined with enlarged buccal corridors strongly confirms maxillary arch constriction.",
                "clinical_relevance": "High",
                "recommendation_trigger": "Palatal arch expansion / Orthodontic arch broadening"
            })
        elif w > 0.50 and bc < 0.08:
            interactions.append({
                "synergy": "Broad Transverse Arch Display",
                "finding": "Wide smile span combined with minimal buccal corridor space indicates a broad, full dental arch.",
                "clinical_relevance": "Positive Esthetic Marker",
                "recommendation_trigger": "Maintain current transverse arch width"
            })

        # 2. Vertical Animated Display
        if arc < 0.0 and opening > 0.09:
            interactions.append({
                "synergy": "Inverted Arc with High Lip Mobility",
                "finding": "Reverse smile arc combined with excessive lip opening amplifies negative incisal curvature visibility.",
                "clinical_relevance": "High",
                "recommendation_trigger": "Anterior incisal re-contouring / Smile line levelling"
            })

        # 3. Midline & Asymmetry Cant Synergy
        if midline > 0.025 and sym > 0.020:
            interactions.append({
                "synergy": "Combined Dental & Occlusal Cant Asymmetry",
                "finding": "Co-occurring midline deviation and commissure vertical cant suggests global occlusal plane tilt rather than isolated dental shift.",
                "clinical_relevance": "High",
                "recommendation_trigger": "Comprehensive occlusal plane cant & skeletal asymmetry tracing"
            })

        # 4. Craniofacial Proportionality
        if ratio < 1.10 and gummy > 0.030:
            interactions.append({
                "synergy": "Long Face Pattern with Gummy Smile",
                "finding": "Leptoprosopic facial morphology combined with increased gingival display points towards Vertical Maxillary Excess (VME).",
                "clinical_relevance": "High",
                "recommendation_trigger": "Orthognathic VME evaluation / Superior maxillary repositioning consideration"
            })

        # 5. Gingivo-Incisal Harmony
        if arc >= 0.015 and gummy <= 0.020 and 0.42 <= w <= 0.52:
            interactions.append({
                "synergy": "Harmonious Aesthetic Triad",
                "finding": "Ideal parallel smile arc, minimal gingival display, and balanced smile width form an esthetic smile triad.",
                "clinical_relevance": "Ideal Esthetic Triad",
                "recommendation_trigger": "Esthetic maintenance"
            })

        return interactions

    # ---------------------------------------------------------
    # PHASE 2F: SMILE & FACIAL HARMONY ENGINE (INTERNAL)
    # ---------------------------------------------------------

    def calculate_harmony_indices(
        self,
        assessments: Dict[str, Dict[str, Any]]
    ) -> Dict[str, float]:
        """
        Internal indices for overall facial & smile balance (not exposed on frontend).
        """
        ratio_val = assessments["face_ratio"]["value"]
        sym_val = assessments["symmetry"]["value"]
        midline_val = assessments["midline"]["value"]
        arc_val = assessments["smile_arc"]["value"]

        # Facial Proportionality Index (0-100)
        prop_score = max(0.0, 100.0 - (abs(ratio_val - 1.32) / 0.50) * 100.0)

        # Symmetry Balance Index (0-100)
        sym_score = max(0.0, 100.0 - ((sym_val / 0.040) * 50.0 + (midline_val / 0.040) * 50.0))

        # Smile Harmony Index (0-100)
        arc_score = 100.0 if arc_val >= 0.015 else max(0.0, 100.0 - (abs(arc_val - 0.015) / 0.035) * 100.0)

        overall_harmony = round(0.40 * sym_score + 0.35 * arc_score + 0.25 * prop_score, 2)

        return {
            "facial_proportionality_index": round(prop_score, 2),
            "symmetry_balance_index": round(sym_score, 2),
            "smile_harmony_index": round(arc_score, 2),
            "composite_harmony_score": overall_harmony
        }

    # ---------------------------------------------------------
    # MAIN EVALUATION ENGINE
    # ---------------------------------------------------------

    def evaluate_clinical_interpretation(self) -> Dict[str, Any]:
        # 1. Fetch normalized inputs
        smile_width = self._get("smile_width")
        smile_symmetry = self._get("smile_symmetry")
        midline_deviation = self._get("midline_deviation")
        smile_arc = self._get("smile_arc")
        gingival_display = self._get("gingival_display")
        buccal_corridor = self._get("buccal_corridor")
        lip_opening = self._get("lip_opening")
        face_ratio = self._get("face_ratio")
        quality_score = self._get("quality_score", 1.0)

        # 2. Individual Feature Interpretations
        w_eval = self._interpret_smile_width(smile_width)
        sym_eval = self._interpret_smile_symmetry(smile_symmetry)
        mid_eval = self._interpret_midline_deviation(midline_deviation)
        arc_eval = self._interpret_smile_arc(smile_arc)
        ging_eval = self._interpret_gingival_display(gingival_display)
        buc_eval = self._interpret_buccal_corridor(buccal_corridor)
        lip_eval = self._interpret_lip_opening(lip_opening)
        face_eval = self._interpret_face_ratio(face_ratio)

        assessment = {
            "midline": mid_eval,
            "symmetry": sym_eval,
            "gingival_display": ging_eval,
            "smile_arc": arc_eval,
            "buccal_corridor": buc_eval,
            "smile_width": w_eval,
            "face_ratio": face_eval,
            "lip_opening": lip_eval,
            "image_quality": {
                "value": round(quality_score, 4),
                "threshold": 0.60,
                "issue": quality_score < 0.60,
                "penalty": 0.0,
                "finding": "Image quality within acceptable limits" if quality_score >= 0.60 else "Low image quality detected",
                "clinical_interpretation": (
                    "Sufficient image quality for reliable measurement extraction."
                    if quality_score >= 0.60 else
                    "Low image quality may reduce landmark detection reliability."
                ),
                "severity": "Normal" if quality_score >= 0.60 else "Mild Concern",
                "confidence": round(quality_score, 4),
                "evidence": f"Quality score: {quality_score:.4f}",
                "limitations": "Calculated from blur and illumination uniformity."
            }
        }

        # 3. Penalty breakdown dictionary (Backward Compatible)
        details = {
            "smile_width_penalty": w_eval["penalty"],
            "lip_opening_penalty": lip_eval["penalty"],
            "face_ratio_penalty": face_eval["penalty"],
            "midline_penalty": mid_eval["penalty"],
            "smile_symmetry_penalty": sym_eval["penalty"],
            "smile_arc_penalty": arc_eval["penalty"],
            "gingival_display_penalty": ging_eval["penalty"],
            "buccal_corridor_penalty": buc_eval["penalty"],
            "quality_score": round(quality_score, 4),
        }

        # 4. Total weighted penalty score out of 100
        total_penalty = (
            mid_eval["penalty"] +
            sym_eval["penalty"] +
            ging_eval["penalty"] +
            arc_eval["penalty"] +
            buc_eval["penalty"] +
            w_eval["penalty"] +
            lip_eval["penalty"] +
            face_eval["penalty"]
        )

        # Quality penalty adjustment
        if quality_score < 0.60:
            total_penalty += 8.0 * (0.60 - quality_score) / 0.60

        weighted_score = round(self._clamp(total_penalty, 0.0, 100.0), 2)

        # 5. Overall Severity Mapping
        if weighted_score < 12.0:
            severity = "Normal"
        elif weighted_score < 22.0:
            severity = "Mild"
        elif weighted_score < 40.0:
            severity = "Moderate"
        else:
            severity = "Severe"

        # 6. Multi-Factor Explainable Confidence Engine
        confidence = 0.50 + 0.50 * self._clamp((100.0 - weighted_score) / 100.0, 0.0, 1.0)
        confidence *= self._clamp(quality_score * 1.05, 0.60, 1.0)
        calibrated_confidence = round(self._clamp(confidence, 0.50, 0.99), 4)

        # 7. Collect Clinical Findings & Detailed Interpretations
        findings = [
            item["finding"]
            for item in assessment.values()
            if item.get("issue", False)
        ]
        if not findings:
            findings.append("Smile proportions balanced")

        clinical_interpretations = [
            item["clinical_interpretation"]
            for item in assessment.values()
            if item.get("issue", False)
        ]
        if not clinical_interpretations:
            clinical_interpretations.append("All 8 smile features sit within standard orthodontic reference ranges.")

        # 8. Feature Interaction & Harmony Analysis
        interaction_findings = self.analyze_feature_interactions(assessment)
        harmony_indices = self.calculate_harmony_indices(assessment)

        return {
            "severity": severity,
            "score": weighted_score,
            "confidence": calibrated_confidence,
            "assessment": assessment,
            "details": details,
            "clinical_findings": findings,
            "clinical_interpretations": clinical_interpretations,
            "interaction_findings": interaction_findings,
            "harmony_analysis": harmony_indices,
            "overall_summary": {
                "assessment_rating": severity,
                "score_out_of_100": weighted_score,
                "confidence": calibrated_confidence,
                "total_issues_identified": len([item for item in assessment.values() if item.get("issue", False)]),
                "decision_support_note": (
                    "Structured decision-support findings generated. "
                    "Prepares evidence for treatment planning and ML prediction engines."
                )
            }
        }

    def classify(self) -> Dict[str, Any]:
        """Backward compatible wrapper for legacy calls to SeverityClassifier.classify()."""
        return self.evaluate_clinical_interpretation()


# Class alias for 100% backward compatibility with existing codebase callers
SeverityClassifier = ClinicalInterpretationEngine