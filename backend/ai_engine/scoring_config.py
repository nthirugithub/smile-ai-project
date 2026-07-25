"""
==========================================================
SmileSync Clinical Scoring Configuration
==========================================================

This file contains all configurable clinical parameters
used by the Clinical Scoring Engine.

Changing values here automatically updates the scoring
logic throughout the application.

Author: SmileSync AI
"""

# ==========================================================
# IDEAL FEATURE RANGES
# (Approximate clinical smile aesthetics)
# ==========================================================

IDEAL_RANGES = {

    # Broad natural smile
    "smile_width": {
        "ideal_min": 0.46,
        "ideal_max": 0.55,
        "absolute_min": 0.35,
        "absolute_max": 0.65
    },

    # Comfortable tooth display
    "lip_opening": {
        "ideal_min": 0.06,
        "ideal_max": 0.11,
        "absolute_min": 0.02,
        "absolute_max": 0.18
    },

    # Face proportion
    "face_ratio": {
        "ideal_min": 0.82,
        "ideal_max": 0.92,
        "absolute_min": 0.70,
        "absolute_max": 1.00
    },

    # Smaller is better
    "midline_deviation": {
        "ideal_max": 0.003,
        "absolute_max": 0.020
    },

    # Smaller is better
    "smile_symmetry": {
        "ideal_max": 0.010,
        "absolute_max": 0.050
    },

    # Gentle positive smile arc
    "smile_arc": {
        "ideal_min": 0.00,
        "ideal_max": 0.02,
        "absolute_min": -0.06,
        "absolute_max": 0.08
    },

    # Minimal gingival display
    "gingival_display": {
        "ideal_max": 0.010,
        "absolute_max": 0.050
    },

    # Medium buccal corridor
    "buccal_corridor": {
        "ideal_min": 0.25,
        "ideal_max": 0.35,
        "absolute_min": 0.10,
        "absolute_max": 0.60
    }

}

# ==========================================================
# FEATURE WEIGHTS
# Total = 100
# ==========================================================

FEATURE_WEIGHTS = {

    "smile_width": 15,

    "lip_opening": 5,

    "face_ratio": 5,

    "midline_deviation": 20,

    "smile_symmetry": 20,

    "smile_arc": 15,

    "gingival_display": 10,

    "buccal_corridor": 10

}

# ==========================================================
# SCORE INTERPRETATION
# ==========================================================

SCORE_GRADES = {

    (9.0, 10.0): {
        "grade": "Excellent",
        "color": "#2ECC71",
        "recommendation":
            "Excellent smile aesthetics. Maintain oral hygiene and routine dental care."
    },

    (7.5, 8.99): {
        "grade": "Very Good",
        "color": "#27AE60",
        "recommendation":
            "Overall smile aesthetics are very good. Minor cosmetic improvements may be considered."
    },

    (6.0, 7.49): {
        "grade": "Good",
        "color": "#F1C40F",
        "recommendation":
            "Smile is generally pleasing. Some orthodontic improvements could enhance aesthetics."
    },

    (4.5, 5.99): {
        "grade": "Fair",
        "color": "#E67E22",
        "recommendation":
            "Orthodontic consultation is recommended to improve smile harmony."
    },

    (0.0, 4.49): {
        "grade": "Needs Improvement",
        "color": "#E74C3C",
        "recommendation":
            "Comprehensive orthodontic evaluation is recommended."
    }

}

# ==========================================================
# CLINICAL FINDINGS THRESHOLDS
# ==========================================================

FINDING_THRESHOLDS = {

    "midline_deviation": 0.006,

    "smile_symmetry": 0.018,

    "gingival_display": 0.015,

    "buccal_corridor": 0.40,

    "smile_arc_low": -0.02,

    "smile_arc_high": 0.04,

    "smile_width_low": 0.42

}