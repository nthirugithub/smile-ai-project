import pandas as pd

# ==========================================
# LOAD DATASET
# ==========================================

df = pd.read_csv("dataset/smile_dataset_labeled.csv")

# ==========================================
# CLINICAL LABEL FUNCTION
# ==========================================

def assign_clinical_label(row):

    score = row["severity_score"]

    midline = row["midline_deviation"]
    symmetry = row["smile_symmetry"]
    gingival = row["gingival_display"]
    arc = abs(row["smile_arc"] - 0.015)

    issue_count = 0

    if midline > 0.040:
        issue_count += 1

    if symmetry > 0.020:
        issue_count += 1

    if gingival > 0.012:
        issue_count += 1

    if arc > 0.035:
        issue_count += 1

    # ======================================
    # NORMAL
    # ======================================

    if (
        score < 0.28
        and midline < 0.015
        and symmetry < 0.010
        and gingival < 0.012
    ):
        return 0

    # ======================================
    # SEVERE
    # ======================================

    if (
        score > 0.58
        and issue_count >= 2
    ):
        return 3

    # ======================================
    # MODERATE
    # ======================================

    if (
        score > 0.42
        or issue_count >= 2
    ):
        return 2

    # ======================================
    # MILD
    # ======================================

    return 1


# ==========================================
# GENERATE LABELS
# ==========================================

df["clinical_label"] = df.apply(
    assign_clinical_label,
    axis=1
)

# ==========================================
# SAVE
# ==========================================

output_file = "dataset/smile_dataset_clinical.csv"

df.to_csv(
    output_file,
    index=False
)

# ==========================================
# REPORT
# ==========================================

print("\n===================================")
print("CLINICAL LABEL GENERATION COMPLETE")
print("===================================\n")

print(
    df["clinical_label"]
    .value_counts()
    .sort_index()
)

print("\nSaved:")
print(output_file)