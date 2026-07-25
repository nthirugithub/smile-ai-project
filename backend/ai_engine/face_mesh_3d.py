import os
import cv2
import math
import mediapipe as mp
import numpy as np


class FaceMesh3D:

    def __init__(self):

        self.mp_face_mesh = mp.solutions.face_mesh

        self.face_mesh = self.mp_face_mesh.FaceMesh(
            static_image_mode=True,
            max_num_faces=1,
            refine_landmarks=True,
            min_detection_confidence=0.7,
            min_tracking_confidence=0.7
        )

        self.mp_drawing = mp.solutions.drawing_utils

        self.drawing_spec = self.mp_drawing.DrawingSpec(
            thickness=1,
            circle_radius=1
        )

    # =================================================
    # IMAGE QUALITY CHECKS
    # =================================================

    def calculate_blur_score(self, image):

        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

        return cv2.Laplacian(
            gray,
            cv2.CV_64F
        ).var()

    def calculate_brightness(self, image):

        hsv = cv2.cvtColor(
            image,
            cv2.COLOR_BGR2HSV
        )

        brightness = hsv[..., 2].mean()

        return brightness

    # =================================================
    # FACE SIZE ESTIMATION
    # =================================================

    def estimate_face_size(
        self,
        landmarks,
        width,
        height
    ):

        xs = [
            int(lm.x * width)
            for lm in landmarks.landmark
        ]

        ys = [
            int(lm.y * height)
            for lm in landmarks.landmark
        ]

        face_width = max(xs) - min(xs)

        face_height = max(ys) - min(ys)

        return face_width * face_height

    # =================================================
    # HEAD TILT ESTIMATION
    # =================================================

    def estimate_head_tilt(
        self,
        landmark_points
    ):

        left_eye = landmark_points[33]
        right_eye = landmark_points[263]

        dx = right_eye[0] - left_eye[0]
        dy = right_eye[1] - left_eye[1]

        angle = math.degrees(
            math.atan2(dy, dx)
        )

        return round(angle, 2)

    # =================================================
    # MAIN PROCESSING
    # =================================================

    def process_image(self, image_path):

        if not os.path.exists(image_path):

            print("Image path not found")

            return None

        image = cv2.imread(image_path)

        if image is None:

            print("Failed to load image")

            return None

        h, w, c = image.shape

        # ---------------------------------------------
        # IMAGE QUALITY CHECKS
        # ---------------------------------------------

        blur_score = self.calculate_blur_score(
            image
        )

        brightness = self.calculate_brightness(
            image
        )

        # ---------------------------------------------
        # RGB CONVERSION
        # ---------------------------------------------

        rgb_image = cv2.cvtColor(
            image,
            cv2.COLOR_BGR2RGB
        )

        # ---------------------------------------------
        # MEDIAPIPE PROCESSING
        # ---------------------------------------------

        results = self.face_mesh.process(
            rgb_image
        )

        if not results.multi_face_landmarks:

            print("No face detected")

            return None

        # ---------------------------------------------
        # MULTI-FACE HANDLING
        # ---------------------------------------------

        if len(results.multi_face_landmarks) > 1:

            print(
                "Multiple faces detected. "
                "Selecting largest face."
            )

        # Choose largest face

        largest_face = None
        largest_size = 0

        for face_landmarks in results.multi_face_landmarks:

            size = self.estimate_face_size(
                face_landmarks,
                w,
                h
            )

            if size > largest_size:

                largest_size = size

                largest_face = face_landmarks

        face_landmarks = largest_face

        # ---------------------------------------------
        # LANDMARK EXTRACTION
        # ---------------------------------------------

        landmark_points = []

        for landmark in face_landmarks.landmark:

            x = int(landmark.x * w)
            y = int(landmark.y * h)
            z = landmark.z

            landmark_points.append(
                (x, y, z)
            )

        # ---------------------------------------------
        # HEAD TILT
        # ---------------------------------------------

        head_tilt = self.estimate_head_tilt(
            landmark_points
        )
        if abs(head_tilt) > 15:
            print("Head tilt too large")
            return None

        # ---------------------------------------------
        # FACE SIZE VALIDATION
        # ---------------------------------------------

        if largest_size < 60000:

            print(
                "Face too small for reliable analysis"
            )

            return None

        # ---------------------------------------------
        # QUALITY SCORE
        # ---------------------------------------------

        blur_quality = min(
            blur_score / 180,
            1.0
        )

        brightness_quality = 1.0

        if brightness < 40:

            brightness_quality = 0.4

        elif brightness < 70:

            brightness_quality = 0.7

        quality_score = (
            blur_quality * 0.6 +
            brightness_quality * 0.4
        )

        quality_score = round(
            float(
                min(max(quality_score, 0), 1)
            ),
            4
        )

        # ---------------------------------------------
        # DRAW LANDMARKS
        # ---------------------------------------------

        mesh_image = image.copy()

        self.mp_drawing.draw_landmarks(
            image=mesh_image,
            landmark_list=face_landmarks,
            connections=self.mp_face_mesh.FACEMESH_TESSELATION,
            landmark_drawing_spec=None,
            connection_drawing_spec=self.drawing_spec
        )

        # ---------------------------------------------
        # OVERLAY INFO
        # ---------------------------------------------

        cv2.putText(
            mesh_image,
            f"Quality: {quality_score:.2f}",
            (20, 40),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.8,
            (0, 255, 0),
            2
        )

        cv2.putText(
            mesh_image,
            f"Tilt: {head_tilt:.1f} deg",
            (20, 80),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.8,
            (255, 255, 0),
            2
        )

        # ---------------------------------------------
        # SAVE OUTPUT
        # ---------------------------------------------

        output_path = f"reports/mesh_output_{os.getpid()}.jpg"

        os.makedirs(
            "reports",
            exist_ok=True
        )

        cv2.imwrite(
            output_path,
            mesh_image
        )

        print(
            f"3D face mesh saved: {output_path}"
        )

        # ---------------------------------------------
        # RETURN
        # ---------------------------------------------

        return {

            "image":
                image,

            "mesh_image":
                mesh_image,

            "landmarks":
                landmark_points,

            "output_path":
                output_path,

            "quality_score":
                quality_score,

            "blur_score":
                round(float(blur_score), 2),

            "brightness":
                round(float(brightness), 2),

            "head_tilt":
                head_tilt,

            "face_area":
                int(largest_size)
        }