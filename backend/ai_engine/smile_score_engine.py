

class SmileScoreEngine:

    def __init__(self):
        pass

    def calculate_score(
        self,
        features,
        probabilities,
        severity_analysis,
    ):

        normal = float(probabilities[0])
        mild = float(probabilities[1])
        moderate = float(probabilities[2])

        assessment = severity_analysis["assessment"]

        score = 5.0

        # -----------------------------
        # AI Prediction Contribution
        # -----------------------------

        score += normal * 4.1
        score += mild * 2.8
        score += moderate * 1.2

        # -----------------------------
        # Smile Width
        # -----------------------------

        width_penalty = assessment["smile_width"]["penalty"]

        if width_penalty == 0:
            score += 0.35
        elif width_penalty <= 5:
            score += 0.15
        else:
            score -= 0.30

        # -----------------------------
        # Symmetry
        # -----------------------------

        symmetry_penalty = assessment["symmetry"]["penalty"]

        if symmetry_penalty == 0:
            score += 0.45
        elif symmetry_penalty <= 5:
            score += 0.20
        else:
            score -= 0.35

        # -----------------------------
        # Midline
        # -----------------------------

        midline_penalty = assessment["midline"]["penalty"]

        if midline_penalty == 0:
            score += 0.35
        elif midline_penalty <= 5:
            score += 0.15
        else:
            score -= 0.30

        # -----------------------------
        # Smile Arc
        # -----------------------------

        arc_penalty = assessment["smile_arc"]["penalty"]

        if arc_penalty == 0:
            score += 0.30
        elif arc_penalty <= 5:
            score += 0.15
        else:
            score -= 0.20

        # -----------------------------
        # Gingival Display
        # -----------------------------
        

        gingival_penalty = assessment["gingival_display"]["penalty"]

        if gingival_penalty == 0:
            score += 0.25
        elif gingival_penalty <= 5:
            score += 0.10
        else:
            score -= 0.20

        # -----------------------------
        # Buccal Corridor
        # -----------------------------

        corridor_penalty = assessment["buccal_corridor"]["penalty"]

        if corridor_penalty == 0:
            score += 0.30
        elif corridor_penalty <= 5:
            score += 0.15
        else:
            score -= 0.25

        # -----------------------------
        # Face Ratio
        # -----------------------------

        face_ratio_penalty = assessment["face_ratio"]["penalty"]

        if face_ratio_penalty == 0:
            score += 0.20
        elif face_ratio_penalty <= 5:
            score += 0.10
        else:
            score -= 0.20

        # -----------------------------
        # Clamp
        # -----------------------------

        score = max(4.0, min(score, 9.4))

        return {
            "smile_score": round(score, 2)
        }