class SmileReasoning:

    def analyze(self, features, severity_analysis):

        strengths = []
        improvements = []
        assessment = severity_analysis.get("assessment", {})

        midline_assessment = assessment.get("midline", {})
        symmetry_assessment = assessment.get("symmetry", {})
        gingival_assessment = assessment.get("gingival", {})
        smile_arc_assessment = assessment.get("smile_arc", {})
        smile_width_assessment = assessment.get("smile_width", {})
        buccal_assessment = assessment.get("buccal_corridor", {})
        face_ratio_assessment = assessment.get("face_ratio", {})
        lip_opening_assessment = assessment.get("lip_opening", {})

        # -------------------------
        # Smile Width
        # -------------------------

        if smile_width_assessment.get("issue", False):
            improvements.append("Smile width could be improved")
        else:
            strengths.append("Balanced smile width")

        # -------------------------
        # Symmetry
        # -------------------------

        if symmetry_assessment.get("issue", False):
            improvements.append("Improve smile symmetry")
        else:
            strengths.append("Good smile symmetry")

        # -------------------------
        # Midline
        # -------------------------

        if midline_assessment.get("issue", False):
            improvements.append("Correct dental midline alignment")
        else:
            strengths.append("Well aligned dental midline")

        # -------------------------
        # Smile Arc
        # -------------------------

        if smile_arc_assessment.get("issue", False):
            improvements.append("Smile arc can be enhanced")
        else:
            strengths.append("Natural smile arc")

        # -------------------------
        # Gingival Display
        # -------------------------

        if gingival_assessment.get("issue", False):
            improvements.append("Reduce excessive gingival display")
        else:
            strengths.append("Minimal gingival display")

        # -------------------------
        # Buccal Corridor
        # -------------------------

        if buccal_assessment.get("issue", False):
            improvements.append("Improve buccal corridor balance")
        else:
            strengths.append("Balanced buccal corridor")

        # -------------------------
        # Lip Opening
        # -------------------------

        if lip_opening_assessment.get("issue", False):
            improvements.append("Optimize lip opening during smiling")
        else:
            strengths.append("Appropriate lip opening")

    

        # -------------------------
        # Face Ratio
        # -------------------------

        if not face_ratio_assessment.get("issue", False):
            strengths.append("Pleasant facial proportion")

        # -------------------------
        # Priority
        # -------------------------

        if len(improvements) == 0:
            priority = "Very Low"

        elif len(improvements) <= 2:
            priority = "Low"

        elif len(improvements) <= 4:
            priority = "Medium"

        else:
            priority = "High"

        return {
            "strengths": strengths,
            "improvements": improvements,
            "priority": priority
        }