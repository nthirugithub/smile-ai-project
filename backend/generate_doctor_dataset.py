import argparse
import csv
import json
from pathlib import Path

from ai_engine.face_mesh_3d import FaceMesh3D
from ai_engine.feature_extractor import FeatureExtractor


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
    "clinical_label"
]


VALID_EXTENSIONS = {".jpg", ".jpeg", ".png", ".JPG", ".JPEG", ".PNG"}


def parse_args():
    parser = argparse.ArgumentParser(description="Generate smile feature dataset.")
    parser.add_argument(
        "--image-folder",
        type=str,
        default="raw_dataset/doctor_images",
        help="Folder containing input images",
    )
    parser.add_argument(
        "--output-csv",
        type=str,
        default="dataset/doctor_features.csv",
        help="Output CSV file path",
    )
    parser.add_argument(
        "--report-file",
        type=str,
        default="reports/doctor_dataset_report.json",
        help="Summary report file path",
    )
    parser.add_argument(
        "--failed-file",
        type=str,
        default="reports/doctor_dataset_failed.txt",
        help="Failed images log file path",
    )
    parser.add_argument(
        "--min-quality",
        type=float,
        default=0.35,
        help="Minimum quality score to keep an image",
    )
    return parser.parse_args()


def main():
    args = parse_args()

    image_folder = Path(args.image_folder)
    csv_file = Path(args.output_csv)
    report_file = Path(args.report_file)
    failed_file = Path(args.failed_file)
    min_quality = float(args.min_quality)

    if not image_folder.exists():
        raise FileNotFoundError(f"Image folder not found: {image_folder}")

    csv_file.parent.mkdir(parents=True, exist_ok=True)
    report_file.parent.mkdir(parents=True, exist_ok=True)
    failed_file.parent.mkdir(parents=True, exist_ok=True)

    mesh_detector = FaceMesh3D()

    total_files = 0
    processed_images = 0
    skipped_non_images = 0
    no_face_detected = 0
    low_quality_skipped = 0
    failed_images = 0
    failed_list = []

    with csv_file.open(mode="w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow(FEATURE_COLUMNS)

        for image_path in sorted(image_folder.iterdir()):
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

                quality_score = float(result.get("quality_score", 0.0) or 0.0)
                if quality_score < min_quality:
                    low_quality_skipped += 1
                    failed_list.append(
                        f"{image_path.name} -> Low quality ({quality_score:.4f})"
                    )
                    continue

                landmarks = result["landmarks"]
                extractor = FeatureExtractor(landmarks)
                features = extractor.extract_all_features()
                features["quality_score"] = quality_score

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
                     "",
                ]

                writer.writerow(row)
                processed_images += 1
                print(f"Processed: {image_path.name}")

            except Exception as e:
                failed_images += 1
                failed_list.append(f"{image_path.name} -> {str(e)}")
                print(f"Error processing {image_path.name}: {e}")

    with failed_file.open("w", encoding="utf-8") as f:
        for item in failed_list:
            f.write(item + "\n")

    report = {
        "image_folder": str(image_folder),
        "csv_file": str(csv_file),
        "total_files_seen": total_files,
        "processed_images": processed_images,
        "skipped_non_images": skipped_non_images,
        "no_face_detected": no_face_detected,
        "low_quality_skipped": low_quality_skipped,
        "failed_images": failed_images,
        "min_quality": min_quality,
        "failed_log_file": str(failed_file),
    }

    with report_file.open("w", encoding="utf-8") as f:
        json.dump(report, f, indent=4)

    print("\n======================================")
    print("Dataset generation completed")
    print("======================================")
    print(f"Image folder: {image_folder}")
    print(f"Total files seen: {total_files}")
    print(f"Processed images: {processed_images}")
    print(f"Skipped non-images: {skipped_non_images}")
    print(f"No face detected: {no_face_detected}")
    print(f"Low quality skipped: {low_quality_skipped}")
    print(f"Failed images: {failed_images}")
    print(f"CSV saved to: {csv_file}")
    print(f"Summary report saved to: {report_file}")
    print(f"Failure log saved to: {failed_file}")


if __name__ == "__main__":
    main()