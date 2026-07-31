import cv2
import os
import numpy as np
from ai_engine.face_mesh_3d import FaceMesh3D
from app import draw_smile_overlay

mesh_detector = FaceMesh3D()

image_path = "raw_dataset/doctor_images/doc (1).jpeg"
if not os.path.exists(image_path):
    # Try any image in raw_dataset/doctor_images
    images = os.listdir("raw_dataset/doctor_images")
    if images:
        image_path = os.path.join("raw_dataset/doctor_images", images[0])

print(f"Testing overlay alignment on image: {image_path}")

result = mesh_detector.process_image(image_path)
if result is None:
    print("Failed to detect face")
else:
    raw_landmarks = result["raw_landmarks"]
    aligned_landmarks = result["landmarks"]
    img = result["image"].copy()

    # Draw overlay using raw_landmarks
    overlay_img = draw_smile_overlay(img, raw_landmarks)
    
    cv2.imwrite("reports/test_overlay_alignment.jpg", overlay_img)
    print("Saved test overlay image to reports/test_overlay_alignment.jpg")

    # Inspect coordinates of landmarks
    # Nose tip (1), Chin (152), Left Commissure (61), Right Commissure (291), Lower lip mid (17)
    print(f"Image shape: {img.shape}")
    print(f"Nose tip (1) pixel coords: {raw_landmarks[1]}")
    print(f"Chin (152) pixel coords: {raw_landmarks[152]}")
    print(f"Left commissure (61) pixel coords: {raw_landmarks[61]}")
    print(f"Right commissure (291) pixel coords: {raw_landmarks[291]}")
    print(f"Lower lip mid (17) pixel coords: {raw_landmarks[17]}")
