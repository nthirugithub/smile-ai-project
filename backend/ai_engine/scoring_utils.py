"""
==========================================================
SmileSync Clinical Scoring Utilities
==========================================================

Reusable mathematical scoring functions.

Each function returns a score between 0 and 10.

10 = Ideal
0 = Very Poor

Author: SmileSync AI
"""

from __future__ import annotations


# ==========================================================
# Clamp
# ==========================================================

def clamp(value: float,
          minimum: float = 0.0,
          maximum: float = 10.0) -> float:

    return max(minimum, min(maximum, value))


# ==========================================================
# Ideal Range Score
# Example:
# Smile Width
# Buccal Corridor
# Lip Opening
# ==========================================================

def score_range(
    value: float,
    ideal_min: float,
    ideal_max: float,
    absolute_min: float,
    absolute_max: float
) -> float:

    # Perfect
    if ideal_min <= value <= ideal_max:
        return 10.0

    # Too small
    if value < ideal_min:

        ratio = (
            value - absolute_min
        ) / (
            ideal_min - absolute_min
        )

        return round(clamp(ratio * 10), 2)

    # Too large
    ratio = (
        absolute_max - value
    ) / (
        absolute_max - ideal_max
    )

    return round(clamp(ratio * 10), 2)


# ==========================================================
# Lower Is Better
# Example:
# Midline Deviation
# Smile Symmetry
# Gingival Display
# ==========================================================

def score_upper_limit(
    value: float,
    ideal_max: float,
    absolute_max: float
) -> float:

    if value <= ideal_max:
        return 10.0

    ratio = (
        absolute_max - value
    ) / (
        absolute_max - ideal_max
    )

    return round(clamp(ratio * 10), 2)


# ==========================================================
# Target Score
# Best near target
# Example:
# Smile Arc
# ==========================================================

def score_target(
    value: float,
    target: float,
    tolerance: float
) -> float:

    difference = abs(
        value - target
    )

    score = 10 - (
        difference / tolerance
    ) * 10

    return round(
        clamp(score),
        2
    )


# ==========================================================
# Weighted Average
# ==========================================================

def weighted_average(
    scores: dict,
    weights: dict
) -> float:

    total_weight = 0.0
    weighted_sum = 0.0

    for feature, score in scores.items():

        weight = weights.get(
            feature,
            0
        )

        weighted_sum += score * weight

        total_weight += weight

    if total_weight == 0:
        return 0.0

    return round(
        weighted_sum / total_weight,
        2
    )


# ==========================================================
# Score → Grade
# ==========================================================

def score_to_grade(
    score: float
):

    if score >= 9:
        return "Excellent"

    if score >= 7.5:
        return "Very Good"

    if score >= 6:
        return "Good"

    if score >= 4.5:
        return "Fair"

    return "Needs Improvement"


# ==========================================================
# Confidence
# Higher score confidence when
# measurements stay close to ideal.
# ==========================================================

def estimate_confidence(
    feature_scores: dict
) -> float:

    average = sum(
        feature_scores.values()
    ) / len(feature_scores)

    confidence = 0.60 + (
        average / 10
    ) * 0.39

    return round(
        clamp(
            confidence,
            0.60,
            0.99
        ),
        3
    )