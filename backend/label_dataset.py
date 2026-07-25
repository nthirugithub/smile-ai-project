import os
import cv2
import pandas as pd

# ==========================================================
# PATHS
# ==========================================================

FEATURES_CSV = "dataset/doctor_features.csv"
OUTPUT_CSV = "dataset/doctor_dataset_labeled.csv"
IMAGE_FOLDER = "raw_dataset/doctor_images"

LABELS = {
    ord("1"): 0,   # Normal
    ord("2"): 1,   # Mild
    ord("3"): 2,   # Moderate
    ord("4"): 3    # Severe
}

LABEL_NAMES = {
    0: "Normal",
    1: "Mild",
    2: "Moderate",
    3: "Severe"
}

# ==========================================================
# LOAD DATA
# ==========================================================

df = pd.read_csv(FEATURES_CSV)

# Resume if already exists
if os.path.exists(OUTPUT_CSV) and os.path.getsize(OUTPUT_CSV) > 0:
    labeled_df = pd.read_csv(OUTPUT_CSV)
else:
    labeled_df = df.copy()

    if "clinical_label" not in labeled_df.columns:
        labeled_df["clinical_label"] = ""

# ==========================================================
# START LABELING
# ==========================================================

completed = labeled_df["clinical_label"].fillna("").astype(str).str.strip().ne("").sum()

print(f"\nCompleted: {completed}/{len(labeled_df)}")

for idx, row in labeled_df.iterrows():

    value = row["clinical_label"]

    if pd.notna(value) and str(value).strip() != "":
        continue

    image_path = os.path.join(
        IMAGE_FOLDER,
        row["image_name"]
    )

    image = cv2.imread(image_path)

    if image is None:
        print(f"Cannot open: {image_path}")
        continue

    display = image.copy()

    max_width = 900
    max_height = 700

    h, w = display.shape[:2]

    scale = min(max_width / w, max_height / h, 1.0)

    display = cv2.resize(
        display,
        (
            int(w * scale),
            int(h * scale)
        )
    )

    cv2.putText(
        display,
        f"Image {idx+1}/{len(labeled_df)}",
        (20,30),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.7,
        (0,255,0),
        2
    )

    cv2.putText(
        display,
        "1=N  2=M  3=Mod  Q=Exit",
        (20,60),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.6,
        (255,255,0),
        2
    )

    cv2.imshow("SmileSync Labeling Tool", display)

    print("\n======================================")
    print(f"Image : {row['image_name']}")
    print("======================================")

    print(f"Smile Width      : {row['smile_width']}")
    print(f"Lip Opening      : {row['lip_opening']}")
    print(f"Face Ratio       : {row['face_ratio']}")
    print(f"Midline          : {row['midline_deviation']}")
    print(f"Smile Symmetry   : {row['smile_symmetry']}")
    print(f"Smile Arc        : {row['smile_arc']}")
    print(f"Gingival Display : {row['gingival_display']}")
    print(f"Buccal Corridor  : {row['buccal_corridor']}")
    print(f"Quality Score    : {row['quality_score']}")

    print("\n1 = Normal")
    print("2 = Mild")
    print("3 = Moderate")
    print("4 = Severe")
    print("S = Skip")
    print("Q = Save & Exit")

    while True:

        key = cv2.waitKey(0)

        if key in LABELS:

            label = LABELS[key]

            print(f"\nSaved: {LABEL_NAMES[label]}")

            labeled_df.at[idx, "clinical_label"] = label

            labeled_df.to_csv(
                OUTPUT_CSV,
                index=False
            )

            cv2.destroyAllWindows()

            break

        elif key in [ord("s"), ord("S")]:

            break

        elif key in [ord("q"), ord("Q")]:

            labeled_df.to_csv(
                OUTPUT_CSV,
                index=False
            )

            cv2.destroyAllWindows()

            print("\nProgress Saved.")

            raise SystemExit

cv2.destroyAllWindows()

labeled_df.to_csv(
    OUTPUT_CSV,
    index=False
)

print("\n======================================")
print("Labeling Completed")
print("======================================")