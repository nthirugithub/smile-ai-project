import csv
import json
from pathlib import Path

from ai_engine.face_mesh_3d import FaceMesh3D
from ai_engine.feature_extractor import FeatureExtractor


# =====================================================
# PATHS
# =====================================================

IMAGE_FOLDER = Path("raw_dataset/images")
CSV_FILE = Path("dataset/smile_dataset.csv")
REPORT_FILE = Path("reports/dataset_generation_report.json")
FAILED_FILE = Path("reports/dataset_generation_failed.txt")


# =====================================================
# SETTINGS
# =====================================================

VALID_EXTENSIONS = {".jpg", ".jpeg", ".png", ".JPG", ".JPEG", ".PNG"}

FEATURE_COLUMNS = [
    "image_name",
    "smile_width",
    "lip_opening",
    "face_ratio",
    "midline_deviation",
    "smile_symmetry",
    "smile_arc",
    "gingival_display",
    "buccal_corridor",
    "quality_score",
]


# =====================================================
# FOLDER CHECKS
# =====================================================

if not IMAGE_FOLDER.exists():
    raise FileNotFoundError(f"Image folder not found: {IMAGE_FOLDER}")

CSV_FILE.parent.mkdir(parents=True, exist_ok=True)
REPORT_FILE.parent.mkdir(parents=True, exist_ok=True)


# =====================================================
# INIT DETECTOR
# =====================================================

mesh_detector = FaceMesh3D()


# =====================================================
# STATS
# =====================================================

total_files = 0
processed_images = 0
skipped_non_images = 0
no_face_detected = 0
failed_images = 0
failed_list = []


# =====================================================
# GENERATE DATASET
# =====================================================

with CSV_FILE.open(mode="w", newline="", encoding="utf-8") as file:
    writer = csv.writer(file)
    writer.writerow(FEATURE_COLUMNS)

    for image_path in sorted(IMAGE_FOLDER.iterdir()):
        total_files += 1

        if not image_path.is_file():
            continue

        if image_path.suffix not in VALID_EXTENSIONS:
            skipped_non_images += 1
            continue

        try:
            result = mesh_detector.process_image(str(image_path))

            if result is None:
                no_face_detected += 1
                failed_list.append(f"{image_path.name} -> No face detected")
                continue

            landmarks = result["landmarks"]
            extractor = FeatureExtractor(landmarks)
            features = extractor.extract_all_features()

            row = [
                image_path.name,
                round(float(features["smile_width"]), 4),
                round(float(features["lip_opening"]), 4),
                round(float(features["face_ratio"]), 4),
                round(float(features["midline_deviation"]), 4),
                round(float(features["smile_symmetry"]), 4),
                round(float(features["smile_arc"]), 4),
                round(float(features["gingival_display"]), 4),
                round(float(features["buccal_corridor"]), 4),
                round(float(features.get("quality_score", 0.0)), 4),
            ]

            writer.writerow(row)
            processed_images += 1

            print(f"Processed: {image_path.name}")

        except Exception as e:
            failed_images += 1
            failed_list.append(f"{image_path.name} -> {str(e)}")
            print(f"Error processing {image_path.name}: {e}")


# =====================================================
# SAVE FAILURE LOG
# =====================================================

with FAILED_FILE.open("w", encoding="utf-8") as f:
    for item in failed_list:
        f.write(item + "\n")


# =====================================================
# SAVE SUMMARY REPORT
# =====================================================

report = {
    "image_folder": str(IMAGE_FOLDER),
    "csv_file": str(CSV_FILE),
    "total_files_seen": total_files,
    "processed_images": processed_images,
    "skipped_non_images": skipped_non_images,
    "no_face_detected": no_face_detected,
    "failed_images": failed_images,
    "failed_log_file": str(FAILED_FILE),
}

with REPORT_FILE.open("w", encoding="utf-8") as f:
    json.dump(report, f, indent=4)


# =====================================================
# DONE
# =====================================================

print("\n======================================")
print("Dataset generation completed")
print("======================================")
print(f"Total files seen: {total_files}")
print(f"Processed images: {processed_images}")
print(f"Skipped non-images: {skipped_non_images}")
print(f"No face detected: {no_face_detected}")
print(f"Failed images: {failed_images}")
print(f"CSV saved to: {CSV_FILE}")
print(f"Summary report saved to: {REPORT_FILE}")
print(f"Failure log saved to: {FAILED_FILE}")