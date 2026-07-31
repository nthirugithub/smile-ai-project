from __future__ import annotations

from typing import Any, Dict, Mapping


class SmileScoreEngine:
    """
    Long-term smile scoring engine.

    Design goals:
    - score the smile itself, not classifier certainty
    - use continuous, smooth scoring instead of abrupt if/elif jumps
    - reflect perceptual psychology: symmetry and midline matter most
    - stay stable, calibratable, and easy to extend later
    - keep the public API unchanged for the rest of the app
    """

    # Perceptual importance weights.
    # Higher = more influence on the final score.
    FEATURE_WEIGHTS = {
        "smile_symmetry": 1.00,
        "midline_deviation": 0.95,
        "smile_arc": 0.85,
        "gingival_display": 0.75,
        "smile_width": 0.70,
        "buccal_corridor": 0.60,
        "lip_opening": 0.50,
        "face_ratio": 0.45,
    }

    CORE_FEATURES = (
        "smile_symmetry",
        "midline_deviation",
        "smile_arc",
        "gingival_display",
    )

    def __init__(self):
        pass

    # -----------------------------
    # Basic helpers
    # -----------------------------

    @staticmethod
    def _clamp(value: float, low: float = 0.0, high: float = 10.0) -> float:
        return max(low, min(high, value))

    def _get_feature(self, features: Mapping[str, Any], key: str, default: float = 0.0) -> float:
        try:
            value = features.get(key, default)
            if value is None:
                return float(default)
            return float(value)
        except (TypeError, ValueError):
            return float(default)

    @staticmethod
    def _weighted_average(scores: Dict[str, float], weights: Dict[str, float]) -> float:
        total_weight = 0.0
        weighted_sum = 0.0

        for name, score in scores.items():
            weight = float(weights.get(name, 0.0))
            total_weight += weight
            weighted_sum += score * weight

        if total_weight == 0:
            return 0.0

        return weighted_sum / total_weight

    @staticmethod
    def _score_band(
        value: float,
        ideal_min: float,
        ideal_max: float,
        hard_min: float,
        hard_max: float,
    ) -> float:
        """
        Ideal range gets 10.
        Score falls smoothly to 0 as value approaches hard limits.
        """
        if value is None:
            return 0.0

        if ideal_min <= value <= ideal_max:
            return 10.0

        if value < ideal_min:
            if value <= hard_min:
                return 0.0
            return 10.0 * (value - hard_min) / (ideal_min - hard_min)

        if value >= hard_max:
            return 0.0

        return 10.0 * (hard_max - value) / (hard_max - ideal_max)

    @staticmethod
    def _score_lower_better(
        value: float,
        ideal_max: float,
        hard_max: float,
    ) -> float:
        """
        Lower is better.
        10 if value <= ideal_max.
        Falls smoothly to 0 by hard_max.
        """
        if value is None:
            return 0.0

        if value <= ideal_max:
            return 10.0

        if value >= hard_max:
            return 0.0

        return 10.0 * (hard_max - value) / (hard_max - ideal_max)

    @staticmethod
    def _score_target(
        value: float,
        target: float,
        ideal_tolerance: float,
        hard_tolerance: float,
    ) -> float:
        """
        Best near a target value.
        10 inside ideal tolerance, falls smoothly toward 0 by hard tolerance.
        """
        if value is None:
            return 0.0

        distance = abs(value - target)

        if distance <= ideal_tolerance:
            return 10.0

        if distance >= hard_tolerance:
            return 0.0

        return 10.0 * (hard_tolerance - distance) / (hard_tolerance - ideal_tolerance)

    def _extract_quality_score(
        self,
        features: Mapping[str, Any],
        severity_analysis: Mapping[str, Any],
    ) -> float:
        """
        Returns a normalized quality score in [0, 1].
        Accepts 0..1 or 0..100 formats defensively.
        """
        candidates = []

        # Common places the quality score may exist
        candidates.append(features.get("quality_score"))
        candidates.append(severity_analysis.get("quality_score"))

        details = severity_analysis.get("details")
        if isinstance(details, Mapping):
            candidates.append(details.get("quality_score"))

        for raw in candidates:
            if raw is None:
                continue
            try:
                q = float(raw)
            except (TypeError, ValueError):
                continue

            if q > 1.5:
                q = q / 100.0

            return self._clamp(q, 0.0, 1.0)

        return 1.0

    # -----------------------------
    # Main scoring logic
    # -----------------------------

    def calculate_score(
        self,
        features,
        probabilities,
        severity_analysis,
    ):
        """
        Keep the signature unchanged for app.py.
        `probabilities` is accepted for compatibility but not used in scoring.
        """
        features = features or {}
        severity_analysis = severity_analysis or {}

        # Extract normalized features
        smile_width = self._get_feature(features, "smile_width")
        lip_opening = self._get_feature(features, "lip_opening")
        face_ratio = self._get_feature(features, "face_ratio")
        midline_deviation = self._get_feature(features, "midline_deviation")
        smile_symmetry = self._get_feature(features, "smile_symmetry")
        smile_arc = self._get_feature(features, "smile_arc")
        gingival_display = self._get_feature(features, "gingival_display")
        buccal_corridor = self._get_feature(features, "buccal_corridor")

        quality_score = self._extract_quality_score(features, severity_analysis)

        # 0–10 subscores, each based on literature-backed perceptual rules
        feature_scores = {
            "smile_width": self._score_band(
                smile_width,
                ideal_min=0.420,
                ideal_max=0.520,
                hard_min=0.300,
                hard_max=0.600,
            ),
            "lip_opening": self._score_band(
                lip_opening,
                ideal_min=0.040,
                ideal_max=0.085,
                hard_min=0.015,
                hard_max=0.160,
            ),
            "face_ratio": self._score_band(
                face_ratio,
                ideal_min=1.150,
                ideal_max=1.450,
                hard_min=0.850,
                hard_max=1.800,
            ),
            "midline_deviation": self._score_lower_better(
                midline_deviation,
                ideal_max=0.015,
                hard_max=0.045,
            ),
            "smile_symmetry": self._score_lower_better(
                smile_symmetry,
                ideal_max=0.015,
                hard_max=0.045,
            ),
            "smile_arc": self._score_band(
                smile_arc,
                ideal_min=0.250,
                ideal_max=0.400,
                hard_min=0.000,
                hard_max=0.450,
            ),
            "gingival_display": self._score_lower_better(
                gingival_display,
                ideal_max=0.020,
                hard_max=0.065,
            ),
            "buccal_corridor": self._score_band(
                buccal_corridor,
                ideal_min=0.100,
                ideal_max=0.180,
                hard_min=0.020,
                hard_max=0.350,
            ),
        }

        # Overall harmony score across all features
        overall_score = self._weighted_average(feature_scores, self.FEATURE_WEIGHTS)

        # Core perceptual features carry extra weight in human judgment
        core_weights = {
            "smile_symmetry": 0.34,
            "midline_deviation": 0.30,
            "smile_arc": 0.18,
            "gingival_display": 0.18,
        }
        core_scores = {k: feature_scores[k] for k in self.CORE_FEATURES}
        core_score = self._weighted_average(core_scores, core_weights)

        # Blend overall harmony with the core perceptual signal
        score = (0.65 * overall_score) + (0.35 * core_score)

        # Reliability adjustment: lower image quality reduces score proportionally
        score -= (1.0 - quality_score) * 0.5

        # Weakest-link penalty: if a core aesthetic feature is severely deficient, apply a proportionate penalty
        weakest_core = min(core_scores.values()) if core_scores else 10.0
        if weakest_core < 5.0:
            score -= (5.0 - weakest_core) * 0.25

        # Final clamp to 1.0–9.8 scale
        score = self._clamp(score, 1.0, 9.8)


        return {
            "smile_score": round(score, 2)
        }