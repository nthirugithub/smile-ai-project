"""
Clinical Knowledge Base (CKB) for Smile AI Medical Decision Support System.

Phase 4 Component:
Separates declarative clinical knowledge, orthodontic reference literature,
terminology, interaction definitions, explanation templates, uncertainty concepts,
and management objective mappings from reasoning and inference logic.

STRICT DESIGN RULES:
- Does NOT perform reasoning or inference.
- Does NOT modify measurements or raw input data.
- Does NOT dynamically classify severity or calculate scores.
- Does NOT prescribe specific medical treatments or diagnoses.
- Serves as a centralized, reusable knowledge repository for Phase 4 (Clinical Reasoning)
  and Phase 5 (Treatment Recommendation Engine).
"""

from __future__ import annotations
from typing import Any, Dict, List, Optional


class ClinicalKnowledgeBase:
    """
    Centralized, declarative Clinical Knowledge Base (CKB) for orthodontic decision support.
    """

    # =========================================================================
    # 1. CLINICAL FEATURE TERMINOLOGY & DEFINITIONS
    # =========================================================================
    CLINICAL_TERMINOLOGY: Dict[str, Dict[str, Any]] = {
        "smile_width": {
            "display_name": "Smile Width (W_s)",
            "definition": "Ratio of visible inter-commissural width relative to inter-zygomatic facial width.",
            "unit": "ratio (CW / ZW)",
            "normal_range_description": "0.42 to 0.52 (narrow <0.38, wide >0.55)",
            "primary_references": ["Ackerman et al. (2004)", "Sarver (2001)"],
            "orthodontic_significance": "Evaluates transverse arch display and facial integration."
        },
        "smile_symmetry": {
            "display_name": "Smile Symmetry (S_s)",
            "definition": "Vertical height differential between left and right commissures normalized by facial height.",
            "unit": "ratio (vert diff / MorphH)",
            "normal_range_description": "<0.012 (<1.2% MorphH vertical discrepancy)",
            "primary_references": ["Hulsey (1970)", "Naini (2011)"],
            "orthodontic_significance": "Measures cant, soft-tissue asymmetry, or unilateral muscle elevation."
        },
        "midline_deviation": {
            "display_name": "Midline Deviation (D_m)",
            "definition": "Horizontal distance between facial midline and dental/labial frenum midline.",
            "unit": "ratio (dev / ZW)",
            "normal_range_description": "<0.015 (<1.5% ZW horizontal offset)",
            "primary_references": ["Kokich et al. (1999)", "Thomas et al. (2003)"],
            "orthodontic_significance": "Key determinant of facial harmony; deviations >2-3mm noticeable to laypeople."
        },
        "smile_arc": {
            "display_name": "Smile Arc (A_s)",
            "definition": "Curvature of maxillary incisal edges relative to the inner curvature of the lower lip.",
            "unit": "quadratic curvature coefficient (a * CW)",
            "normal_range_description": "0.015 to 0.045 (ideal parallel arc; flat <=0.004, reverse <0.000)",
            "primary_references": ["Sarver (2001)", "Ackerman & Ackerman (2002)"],
            "orthodontic_significance": "Curvature parallelism creates youthful, harmonious aesthetics."
        },
        "gingival_display": {
            "display_name": "Gingival Display (G_d)",
            "definition": "Vertical maxillary gingival tissue exposure superior to incisal crown margins during smile.",
            "unit": "ratio (lip elevation / MorphH)",
            "normal_range_description": "0.000 to 0.020 (0-2mm normal; gummy smile >0.030)",
            "primary_references": ["Tjan et al. (1984)", "Robbins (1999)"],
            "orthodontic_significance": "Differentiates normal lip elevation from vertical maxillary excess or hyperfunctional lip."
        },
        "buccal_corridor": {
            "display_name": "Buccal Corridor Ratio (BCR)",
            "definition": "Bilateral negative space between posterior teeth and cheek oral mucosa.",
            "unit": "ratio (negative space / CW)",
            "normal_range_description": "0.100 to 0.180 (excessive negative space >0.190, excessive broad fullness <0.060)",
            "primary_references": ["Martin et al. (2007)", "Moore et al. (2005)"],
            "orthodontic_significance": "Evaluates transverse arch width and posterior dark space balance."
        },
        "lip_opening": {
            "display_name": "Lip Opening (O_l)",
            "definition": "Vertical inter-labial distance between upper and lower stomion landmarks during smile.",
            "unit": "ratio (opening / MorphH)",
            "normal_range_description": "0.080 to 0.180",
            "primary_references": ["Farkas (1994)", "Dong et al. (1993)"],
            "orthodontic_significance": "Validates dynamic smile expansion versus resting lip posture."
        },
        "face_ratio": {
            "display_name": "Facial Height-to-Width Ratio (R_f)",
            "definition": "Ratio of morphological facial height (Nasion-Gnathion) to inter-zygomatic width.",
            "unit": "ratio (MorphH / ZW)",
            "normal_range_description": "1.250 to 1.450 (Mesofacial norm)",
            "primary_references": ["Farkas (1994)", "Bishara (2001)"],
            "orthodontic_significance": "Establishes facial biotype context (Brachyfacial vs Mesofacial vs Dolichofacial)."
        }
    }

    # =========================================================================
    # 2. SEVERITY TERMINOLOGY
    # =========================================================================
    SEVERITY_TERMINOLOGY: Dict[str, Dict[str, Any]] = {
        "Normal": {
            "level": 0,
            "display_name": "Normal / Harmonious",
            "description": "Measurement sits well within ideal clinical aesthetic and anatomical reference norms.",
            "clinical_action_needed": False,
            "color_code": "GREEN"
        },
        "Borderline": {
            "level": 1,
            "display_name": "Borderline Variant",
            "description": "Minor deviation near anatomical boundary; usually aesthetic variant requiring observation.",
            "clinical_action_needed": False,
            "color_code": "BLUE"
        },
        "Mild Concern": {
            "level": 2,
            "display_name": "Mild Aesthetic Concern",
            "description": "Slight aesthetic or structural asymmetry; visible on close clinical inspection.",
            "clinical_action_needed": False,
            "color_code": "YELLOW"
        },
        "Moderate Concern": {
            "level": 3,
            "display_name": "Moderate Aesthetic Concern",
            "description": "Noticeable deviation impacting smile harmony or transverse/vertical balance.",
            "clinical_action_needed": True,
            "color_code": "ORANGE"
        },
        "Significant Concern": {
            "level": 4,
            "display_name": "Significant / Severe Concern",
            "description": "Pronounced structural or aesthetic discrepancy requiring formal clinical evaluation.",
            "clinical_action_needed": True,
            "color_code": "RED"
        }
    }

    # =========================================================================
    # 3. CLINICAL EXPLANATION TEMPLATES
    # =========================================================================
    EXPLANATION_TEMPLATES: Dict[str, Dict[str, str]] = {
        "smile_width": {
            "narrow": {
                "observation": "Narrow smile width relative to inter-zygomatic facial frame (W_s = {value:.3f}).",
                "clinical_interpretation": "Sub-optimal transverse arch expansion or constricted archform.",
                "possible_significance": "May accentuate posterior negative space and reduce smile fullness.",
                "limitations": "Subject to camera distance and 2D perspective projection."
            },
            "wide": {
                "observation": "Broad smile width extending near lateral facial boundaries (W_s = {value:.3f}).",
                "clinical_interpretation": "Extensive transverse display with minimal buccal corridor presence.",
                "possible_significance": "May create crowded broad appearance if uncoordinated with arch curvature.",
                "limitations": "Requires verification against maxillary molar arch width."
            }
        },
        "smile_symmetry": {
            "asymmetric": {
                "observation": "Vertical commissural height discrepancy detected (S_s = {value:.3f}).",
                "clinical_interpretation": "Soft-tissue commissural cant or asymmetrical lip elevator muscle activation.",
                "possible_significance": "Can distract from incisal plane parallelism and dental aesthetic center.",
                "limitations": "Cannot distinguish structural skeletal cant from transient facial expression asymmetry without 3D CBCT."
            }
        },
        "midline_deviation": {
            "deviated": {
                "observation": "Dental/labial frenum midline offset from facial midline (D_m = {value:.3f}).",
                "clinical_interpretation": "Lateral displacement of maxillary dental midline relative to inter-pupillary center.",
                "possible_significance": "Midline shifts >2mm are aesthetically noticeable and affect facial symmetry.",
                "limitations": "Dental midline relative to inter-incisal contact requires intra-oral inspection."
            }
        },
        "smile_arc": {
            "flat": {
                "observation": "Flat smile arc curvature detected (A_s = {value:.3f}).",
                "clinical_interpretation": "Incisal line lacks parallel relationship to lower lip curvature.",
                "possible_significance": "Creates premature aging appearance or flattened anterior guidance aesthetic.",
                "limitations": "Head pitch variation (chin down/up) alters apparent 2D arc curvature."
            },
            "reverse": {
                "observation": "Reverse smile arc curvature detected (A_s = {value:.3f}).",
                "clinical_interpretation": "Central incisors positioned superior to lateral/canine incisal plane relative to lip.",
                "possible_significance": "Aesthetically disharmonious inverted smile line.",
                "limitations": "Must be evaluated alongside lower lip posture during full animation."
            }
        },
        "gingival_display": {
            "excessive": {
                "observation": "Excessive maxillary gingival exposure during smile (G_d = {value:.3f}).",
                "clinical_interpretation": "High smile line / gummy smile presentation.",
                "possible_significance": "Attributable to vertical maxillary excess, short upper lip, or hyperfunctional lip elevator.",
                "limitations": "Clinical differentiation of gingival hyperplasia vs skeletal excess requires intra-oral exam."
            }
        },
        "buccal_corridor": {
            "excessive_dark_space": {
                "observation": "Large buccal corridor negative space ratio (BCR = {value:.3f}).",
                "clinical_interpretation": "Inadequate posterior arch width display during smile animation.",
                "possible_significance": "Creates dark lateral spaces ('black voids') during smiling.",
                "limitations": "Influenced by illumination quality and mouth corner shadow."
            }
        }
    }

    # =========================================================================
    # 4. INTERACTION DEFINITIONS
    # =========================================================================
    INTERACTION_DEFINITIONS: Dict[str, Dict[str, Any]] = {
        "width_buccal": {
            "title": "Smile Width & Buccal Corridor Synergy",
            "features": ["smile_width", "buccal_corridor"],
            "clinical_purpose": "Evaluates transverse arch filling and lateral dark space balance.",
            "supporting_evidence": "Ackerman et al. (2004), Martin et al. (2007).",
            "clinical_meaning": "Narrow smile width combined with high buccal corridor ratio indicates a constricted transverse archform with prominent lateral negative space.",
            "limitations": "Dependent on posterior dentoalveolar width and lighting."
        },
        "arc_lip": {
            "title": "Smile Arc & Lip Opening Coordination",
            "features": ["smile_arc", "lip_opening"],
            "clinical_purpose": "Evaluates incisal curve adaptation during vertical dynamic smile opening.",
            "supporting_evidence": "Sarver (2001), Hulsey (1970).",
            "clinical_meaning": "Flat or reverse smile arc occurring with adequate lip opening confirms intrinsic incisal plane flattening rather than restricted lip movement.",
            "limitations": "Dynamic animation speed can affect snapshot lip opening measurement."
        },
        "midline_symmetry": {
            "title": "Dental Midline & Commissural Symmetry Interplay",
            "features": ["midline_deviation", "smile_symmetry"],
            "clinical_purpose": "Distinguishes true dental midline shift from soft-tissue smile canting.",
            "supporting_evidence": "Kokich et al. (1999), Naini (2011).",
            "clinical_meaning": "Combined midline deviation and commissural asymmetry indicates compound facial canting and dental displacement.",
            "limitations": "Requires differential diagnosis between mandibular posture and maxillary skeletal cant."
        },
        "arc_gingival": {
            "title": "Smile Arc & Gingival Display Interaction",
            "features": ["smile_arc", "gingival_display"],
            "clinical_purpose": "Assesses vertical incisal plane exposure and curvature relationship.",
            "supporting_evidence": "Tjan et al. (1984), Sarver (2001).",
            "clinical_meaning": "Excessive gingival display combined with reverse smile arc accentuates anterior vertical disharmony.",
            "limitations": "Lip mobility and incisor crown height influence combined perception."
        },
        "face_width": {
            "title": "Facial Ratio & Smile Width Proportion",
            "features": ["face_ratio", "smile_width"],
            "clinical_purpose": "Integrates smile width within overall dolicho-, meso-, or brachy-facial morphology.",
            "supporting_evidence": "Farkas (1994), Bishara (2001).",
            "clinical_meaning": "Narrow smile width in a broad (brachyfacial) face creates heightened aesthetic mismatch compared to a long narrow (dolichofacial) face.",
            "limitations": "Facial biotype classification relies on 2D vertical/transverse landmark approximations."
        }
    }

    # =========================================================================
    # 5. CONFIDENCE TERMINOLOGY
    # =========================================================================
    CONFIDENCE_TERMINOLOGY: Dict[str, Dict[str, Any]] = {
        "Very High": {"min_score": 0.90, "description": "Robust multi-source agreement with pristine image quality."},
        "High": {"min_score": 0.80, "description": "Strong landmark accuracy and consistent feature measurements."},
        "Moderate": {"min_score": 0.65, "description": "Acceptable clinical confidence; slight feature variance or mild lighting defect."},
        "Low": {"min_score": 0.50, "description": "Reduced confidence due to borderline landmark stability or pose tilt."},
        "Very Low": {"min_score": 0.00, "description": "High uncertainty; low image quality, extreme head rotation, or evidence conflict."}
    }

    # =========================================================================
    # 6. UNCERTAINTY TERMINOLOGY & CATEGORIES
    # =========================================================================
    UNCERTAINTY_REASONS: Dict[str, Dict[str, str]] = {
        "LOW_IMAGE_QUALITY": {
            "category": "Image Acquisition Defect",
            "description": "Image blur, sub-optimal illumination, or low resolution reduces landmark precision.",
            "mitigation_recommendation": "Re-acquire front-facing facial photo with direct ring-light illumination."
        },
        "HIGH_HEAD_POSE": {
            "category": "Positional Discrepancy",
            "description": "Head pitch (tilt up/down), yaw (rotation), or roll affects 2D projection accuracy.",
            "mitigation_recommendation": "Align natural head position (NHP) parallel to horizontal camera axis."
        },
        "LANDMARK_INSTABILITY": {
            "category": "Anatomical Detection Boundary",
            "description": "Soft-tissue occlusion (hair, lip gloss, facial hair) causes boundary tracking jitter.",
            "mitigation_recommendation": "Ensure unoccluded view of oral commissures and incisal edges."
        },
        "LOW_ML_CONFIDENCE": {
            "category": "Statistical Model Uncertainty",
            "description": "Machine learning prediction probability distribution exhibits high entropy across severity classes.",
            "mitigation_recommendation": "Rely primarily on Phase 2 deterministic clinical rule thresholds."
        },
        "CONFLICTING_EVIDENCE": {
            "category": "Multi-Source Discrepancy",
            "description": "Disagreements detected between Phase 2 rule severity and Phase 3 ML classification.",
            "mitigation_recommendation": "Review individual feature measurements and evidence weighting breakdown."
        },
        "INSUFFICIENT_SUPPORTING_EVIDENCE": {
            "category": "Data Limitation",
            "description": "Isolated finding lacking corroborating feature interaction or structural support.",
            "mitigation_recommendation": "Perform direct intra-oral clinical measurement."
        }
    }

    # =========================================================================
    # 7. CLINICAL SUMMARY TEMPLATES
    # =========================================================================
    SUMMARY_TEMPLATES: Dict[str, Dict[str, str]] = {
        "Normal Smile": {
            "summary_title": "Harmonious Aesthetic Smile Presentation",
            "overview_template": "The evaluated facial photograph demonstrates a well-balanced smile with all 8 primary aesthetic features remaining within established orthodontic reference ranges. Dental midline alignment, commissural symmetry, and smile arc exhibit harmonious integration.",
            "clinical_significance": "Favorable aesthetic balance; no structural orthodontic or restorative intervention indicated based on 2D visual metrics."
        },
        "Mild Concern": {
            "summary_title": "Mild Aesthetic Variance Detected",
            "overview_template": "The clinical assessment reveals mild localized aesthetic variance in {primary_feature}. Key facial proportions and smile symmetry remain generally preserved.",
            "clinical_significance": "Elective aesthetic optimization or minor monitoring may be considered based on patient desire."
        },
        "Moderate Concern": {
            "summary_title": "Moderate Aesthetic & Structural Concern",
            "overview_template": "Moderate aesthetic discrepancy identified, characterized by {primary_feature} alongside secondary features {secondary_features}. Feature interaction analysis reveals noticeable impact on overall smile harmony.",
            "clinical_significance": "Formal orthodontic or interdisciplinary consultation recommended to evaluate archform expansion, midline correction, or smile arc enhancement."
        },
        "Complex Case": {
            "summary_title": "Complex Multi-Factor Orthodontic Concern",
            "overview_template": "Multi-factorial smile disharmony detected with compounding issues across {primary_feature}, {secondary_features}, and significant feature interaction penalties.",
            "clinical_significance": "Comprehensive interdisciplinary evaluation (Orthodontics, Periodontics, Prosthodontics) recommended."
        },
        "High Uncertainty": {
            "summary_title": "Assessment Under Elevated Uncertainty",
            "overview_template": "Clinical decision support findings generated with reduced confidence due to {uncertainty_reasons}. Interpret findings as preliminary.",
            "clinical_significance": "Re-imaging under standardized clinical conditions required prior to treatment planning."
        }
    }

    # =========================================================================
    # 8. GENERALIZED TREATMENT MANAGEMENT OBJECTIVES (FOR PHASE 5 CONSUMPTION)
    # =========================================================================
    # Note: These are high-level management objectives, NOT specific treatment prescriptions.
    MANAGEMENT_OBJECTIVES_MAPPING: Dict[str, List[Dict[str, str]]] = {
        "smile_width": [
            {
                "condition": "narrow",
                "objective_code": "OBJ_TRANSVERSE_EXPANSION",
                "management_objective": "Evaluate archform for transverse maxillary expansion or arch widening.",
                "discipline": "Orthodontics"
            },
            {
                "condition": "wide",
                "objective_code": "OBJ_ARCH_HARMONIZATION",
                "management_objective": "Harmonize posterior tooth position with incisal curvature.",
                "discipline": "Orthodontics / Esthetic Dentistry"
            }
        ],
        "smile_symmetry": [
            {
                "condition": "asymmetric",
                "objective_code": "OBJ_SYMMETRY_CORRECTION",
                "management_objective": "Assess commissural cant and evaluate unilateral levator muscle or incisal plane correction.",
                "discipline": "Orthodontics / Facial Aesthetics"
            }
        ],
        "midline_deviation": [
            {
                "condition": "deviated",
                "objective_code": "OBJ_MIDLINE_REALIGNMENT",
                "management_objective": "Evaluate dental arch midline translation and inter-incisal contact point alignment.",
                "discipline": "Orthodontics"
            }
        ],
        "smile_arc": [
            {
                "condition": "flat",
                "objective_code": "OBJ_ARC_ENHANCEMENT",
                "management_objective": "Re-establish anterior incisal curvature parallelism relative to lower lip arc.",
                "discipline": "Orthodontics / Restorative Dentistry"
            },
            {
                "condition": "reverse",
                "objective_code": "OBJ_ARC_RECONSTRUCTION",
                "management_objective": "Correct anterior vertical incisal position to eliminate inverted smile line.",
                "discipline": "Orthodontics / Prosthodontics"
            }
        ],
        "gingival_display": [
            {
                "condition": "excessive",
                "objective_code": "OBJ_GINGIVAL_MANAGEMENT",
                "management_objective": "Evaluate lip mobility, crown height, and maxillary vertical height for gingival margin or lip positioning.",
                "discipline": "Periodontics / Orthodontics / Oral Surgery"
            }
        ],
        "buccal_corridor": [
            {
                "condition": "excessive_dark_space",
                "objective_code": "OBJ_CORRIDOR_REDUCTION",
                "management_objective": "Optimize posterior premolar display to fill excessive lateral negative space.",
                "discipline": "Orthodontics / Prosthodontics"
            }
        ]
    }

    # =========================================================================
    # 9. PHASE 5 PATIENT TERMINOLOGY MAPPING
    # =========================================================================
    PATIENT_TERMINOLOGY_MAPPING: Dict[str, str] = {
        "smile_width": "Smile Width & Display",
        "smile_symmetry": "Smile Balance & Symmetry",
        "midline_deviation": "Center Dental Line",
        "smile_arc": "Upper Tooth Curve (Smile Arc)",
        "gingival_display": "Visible Gum Line",
        "buccal_corridor": "Side Corner Space (Buccal Corridor)",
        "lip_opening": "Lip Movement & Opening",
        "face_ratio": "Facial Proportions"
    }

    # =========================================================================
    # 10. PHASE 5 RELEVANT CLINICAL DISCIPLINES
    # =========================================================================
    RELEVANT_DISCIPLINES_MAPPING: Dict[str, Dict[str, List[str]]] = {
        "smile_width": {
            "narrow": ["Orthodontics", "General Dentistry"],
            "wide": ["Orthodontics", "Restorative Dentistry"]
        },
        "smile_symmetry": {
            "asymmetric": ["Orthodontics", "General Dentistry"]
        },
        "midline_deviation": {
            "deviated": ["Orthodontics", "General Dentistry"]
        },
        "smile_arc": {
            "flat": ["Orthodontics", "Restorative Dentistry"],
            "reverse": ["Orthodontics", "Prosthodontics"]
        },
        "gingival_display": {
            "excessive": ["Periodontics", "Orthodontics", "General Dentistry"]
        },
        "buccal_corridor": {
            "excessive_dark_space": ["Orthodontics", "Prosthodontics"]
        }
    }

    # =========================================================================
    # 11. PHASE 5 PATIENT EDUCATION TOPICS (NON-PATHOLOGICAL CONTEXT)
    # =========================================================================
    PATIENT_EDUCATION_TOPICS: Dict[str, Dict[str, str]] = {
        "smile_width": {
            "topic": "Smile Width & Facial Frame",
            "explanation": "Smile width measures how broadly your teeth fill your smile from side to side relative to your face.",
            "variation_note": "Natural variations are very common. Some smiles feature a wider display, while others appear narrower naturally.",
            "clinical_relevance": "A dentist or orthodontist can evaluate whether your smile width aligns comfortably with your jaw shape."
        },
        "smile_symmetry": {
            "topic": "Smile Symmetry & Balance",
            "explanation": "Smile symmetry evaluates how level the corners of your mouth appear relative to horizontal facial lines.",
            "variation_note": "Perfect facial symmetry is rare in nature; subtle differences between left and right sides are normal and unique.",
            "clinical_relevance": "A clinical examination can determine if any symmetry differences relate to lip movement or dental alignment."
        },
        "midline_deviation": {
            "topic": "Dental Center Line (Midline)",
            "explanation": "Midline position measures whether the center point between your front teeth aligns with the center of your face.",
            "variation_note": "Slight midline shifts are extremely common and frequently unnoticed during casual conversation.",
            "clinical_relevance": "Only a dentist can evaluate whether a center line shift involves tooth position or jaw alignment."
        },
        "smile_arc": {
            "topic": "Smile Arc Curvature",
            "explanation": "Smile arc refers to the gentle curve formed by the lower edges of your upper front teeth relative to your lower lip.",
            "variation_note": "Smile arcs naturally range from parallel curves to flatter lines depending on facial movement and tooth shape.",
            "clinical_relevance": "An evaluation can explore options if you desire a different curvature contour."
        },
        "gingival_display": {
            "topic": "Gum Line Visibility",
            "explanation": "Gingival display measures how much gum tissue shows above your upper teeth when you smile broadly.",
            "variation_note": "Showing more or less gum tissue is a natural characteristic with multiple harmless causes (such as lip flexibility).",
            "clinical_relevance": "A dental examination can explain your specific gum display characteristics."
        },
        "buccal_corridor": {
            "topic": "Side Space (Buccal Corridors)",
            "explanation": "Buccal corridors are the small dark spaces visible between the outer sides of your teeth and the corners of your mouth.",
            "variation_note": "Varying amounts of side space are natural and depend on arch width and facial lighting.",
            "clinical_relevance": "A practitioner can discuss how arch expansion or tooth position relates to side corridor space."
        },
        "lip_opening": {
            "topic": "Lip Opening & Motion",
            "explanation": "Lip opening measures vertical space between your upper and lower lips during a smile.",
            "variation_note": "Dynamic lip mobility varies naturally depending on facial expression and emotion.",
            "clinical_relevance": "Helps practitioners observe full dynamic smile animation."
        },
        "face_ratio": {
            "topic": "Facial Height-to-Width Proportions",
            "explanation": "Facial ratio provides contextual measurement of overall facial length relative to width.",
            "variation_note": "Facial shapes naturally range across round, oval, long, and square biotypes.",
            "clinical_relevance": "Helps contextualize smile aesthetics within your overall facial frame."
        }
    }

    # =========================================================================
    # 12. RESTRICTED WORD REPLACEMENTS FOR PATIENT COMMUNICATION
    # =========================================================================
    RESTRICTED_WORD_REPLACEMENTS: Dict[str, str] = {
        "abnormal": "characteristic variation",
        "defective": "unique finding",
        "bad": "sub-optimal",
        "ugly": "aesthetic concern",
        "deformed": "structural variation",
        "pathology": "observation",
        "refer to": "clinical discipline of interest:"
    }

    # =========================================================================
    # QUERY METHODS (READ-ONLY LOOKUPS)
    # =========================================================================
    @classmethod
    def get_feature_info(cls, feature_name: str, default: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Retrieve clinical terminology and references for a feature."""
        info = cls.CLINICAL_TERMINOLOGY.get(feature_name)
        return info if info is not None else (default if default is not None else {})

    @classmethod
    def get_severity_info(cls, severity_name: str, default: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Retrieve severity terminology details."""
        info = cls.SEVERITY_TERMINOLOGY.get(severity_name)
        return info if info is not None else (default if default is not None else {})

    @classmethod
    def get_explanation_template(cls, feature_name: str, condition_key: str) -> Optional[Dict[str, str]]:
        """Retrieve explanation template for a given feature and condition."""
        feature_templates = cls.EXPLANATION_TEMPLATES.get(feature_name, {})
        return feature_templates.get(condition_key)

    @classmethod
    def get_interaction_definition(cls, interaction_key: str) -> Optional[Dict[str, Any]]:
        """Retrieve interaction definition metadata."""
        return cls.INTERACTION_DEFINITIONS.get(interaction_key)

    @classmethod
    def get_confidence_label(cls, confidence_score: float) -> str:
        """Map a numeric confidence score (0.0 to 1.0) to standardized confidence terminology."""
        score = max(0.0, min(1.0, float(confidence_score)))
        for label, info in cls.CONFIDENCE_TERMINOLOGY.items():
            if score >= info["min_score"]:
                return label
        return "Very Low"

    @classmethod
    def get_uncertainty_info(cls, reason_code: str) -> Optional[Dict[str, str]]:
        """Retrieve uncertainty details by code."""
        return cls.UNCERTAINTY_REASONS.get(reason_code)

    @classmethod
    def get_summary_template(cls, template_key: str) -> Optional[Dict[str, str]]:
        """Retrieve summary template by key."""
        return cls.SUMMARY_TEMPLATES.get(template_key)

    @classmethod
    def get_management_objectives(cls, feature_name: str, condition: str) -> List[Dict[str, str]]:
        """Retrieve generalized management objectives for Phase 5 consumption."""
        objs = cls.MANAGEMENT_OBJECTIVES_MAPPING.get(feature_name, [])
        return [o for o in objs if o.get("condition") == condition]

    @classmethod
    def get_patient_term(cls, feature_name: str) -> str:
        """Retrieve plain-language patient terminology for a feature."""
        return cls.PATIENT_TERMINOLOGY_MAPPING.get(feature_name, feature_name.replace("_", " ").title())

    @classmethod
    def get_relevant_disciplines(cls, feature_name: str, condition: str) -> List[str]:
        """Retrieve relevant clinical disciplines without ordering direct referrals."""
        feature_disc = cls.RELEVANT_DISCIPLINES_MAPPING.get(feature_name, {})
        return feature_disc.get(condition, ["General Dentistry"])

    @classmethod
    def get_patient_education(cls, feature_name: str) -> Optional[Dict[str, str]]:
        """Retrieve educational topics explaining natural variation and context."""
        return cls.PATIENT_EDUCATION_TOPICS.get(feature_name)

    @classmethod
    def sanitize_patient_text(cls, text: str) -> str:
        """Replace alarming or directive terms with supportive, non-pathological alternatives."""
        sanitized = text
        for word, replacement in cls.RESTRICTED_WORD_REPLACEMENTS.items():
            # Replace case-insensitively
            import re
            pattern = re.compile(re.escape(word), re.IGNORECASE)
            sanitized = pattern.sub(replacement, sanitized)
        return sanitized

