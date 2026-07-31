import os
import sys
import unittest
import json
import base64
import numpy as np
import cv2

# Ensure backend directory is in sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import app, db, User, Patient, SmileReport, Notification, UserSettings

class FullSystemIntegrationAudit(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        app.config['TESTING'] = True
        app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
        cls.client = app.test_client()

        with app.app_context():
            db.create_all()

    def setUp(self):
        with app.app_context():
            # Clear tables for isolation
            SmileReport.query.delete()
            Patient.query.delete()
            Notification.query.delete()
            UserSettings.query.delete()
            User.query.delete()
            db.session.commit()

    # ----------------------------------------------------
    # Phase 1: Authentication & User Management
    # ----------------------------------------------------
    def test_phase_1_authentication_flow(self):
        # 1. Registration
        reg_payload = {
            "name": "Dr. Sarah Connor",
            "email": "sarah.connor@smilesync.ai",
            "password": "SecurePassword123!",
            "clinic": "SmileSync Dental",
            "specialization": "Orthodontist"
        }
        res = self.client.post("/register", json=reg_payload)
        self.assertEqual(res.status_code, 200)
        data = res.get_json()
        self.assertTrue(data["success"])

        # Login to get user_id & token
        res_login_init = self.client.post("/login", json={"email": "sarah.connor@smilesync.ai", "password": "SecurePassword123!"})
        user_id = res_login_init.get_json()["user_id"]

        # Verify User & UserSettings created
        with app.app_context():
            u = User.query.get(user_id)
            self.assertIsNotNone(u)
            self.assertEqual(u.email, "sarah.connor@smilesync.ai")
            s = UserSettings.query.filter_by(user_id=user_id).first()
            self.assertIsNotNone(s)

        # 2. Invalid Login
        res_invalid = self.client.post("/login", json={"email": "sarah.connor@smilesync.ai", "password": "WrongPassword"})
        self.assertEqual(res_invalid.status_code, 401)

        # 3. Successful Login
        res_login = self.client.post("/login", json={"email": "sarah.connor@smilesync.ai", "password": "SecurePassword123!"})
        self.assertEqual(res_login.status_code, 200)
        login_data = res_login.get_json()
        self.assertTrue(login_data["success"])
        token = login_data["access_token"]
        self.assertIsNotNone(token)

        # 4. Unauthorized API Request (No token)
        res_unauth = self.client.get("/dashboard-stats")
        self.assertIn(res_unauth.status_code, [401, 422])

        # 5. Authorized Request
        headers = {"Authorization": f"Bearer {token}"}
        res_auth = self.client.get("/dashboard-stats", headers=headers)
        self.assertEqual(res_auth.status_code, 200)

    # ----------------------------------------------------
    # Phase 3 & 7: Patient Registration & Database Integrity
    # ----------------------------------------------------
    def test_phase_3_and_7_patient_management_and_integrity(self):
        # Register user & login
        self.client.post("/register", json={"name": "Dr. Alex", "email": "alex@smilesync.ai", "password": "Pass123!Password"})
        res_login = self.client.post("/login", json={"email": "alex@smilesync.ai", "password": "Pass123!Password"})
        token = res_login.get_json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 1. Validation error
        res_err = self.client.post("/patients", json={"first_name": "", "last_name": "Doe", "gender": "Male"}, headers=headers)
        self.assertEqual(res_err.status_code, 400)

        # 2. Successful Patient Creation
        patient_payload = {
            "first_name": "Michael",
            "last_name": "Brown",
            "gender": "Male",
            "phone_number": "+1 555-0199",
            "qualification": "Architect",
            "age": 34,
            "notes": "Patient reports mild crowding."
        }
        res_create = self.client.post("/patients", json=patient_payload, headers=headers)
        self.assertEqual(res_create.status_code, 201)
        p1 = res_create.get_json()["patient"]
        self.assertEqual(p1["patient_code"], "P-000001")
        self.assertEqual(p1["full_name"], "Michael Brown")
        patient_id = p1["id"]

        # 3. Duplicate Detection
        res_dup = self.client.post("/patients", json={"first_name": "Michael", "last_name": "Brown", "gender": "Male", "phone_number": "+1 555-0199"}, headers=headers)
        self.assertEqual(res_dup.status_code, 200)
        self.assertTrue(res_dup.get_json()["is_duplicate"])

        # 4. Search Patients
        res_search = self.client.get("/patients?q=P-000001", headers=headers)
        self.assertEqual(res_search.status_code, 200)
        self.assertEqual(len(res_search.get_json()["patients"]), 1)

        # 5. Soft Delete
        res_del = self.client.delete(f"/patients/{patient_id}", headers=headers)
        self.assertEqual(res_del.status_code, 200)
        
        with app.app_context():
            p_db = Patient.query.get(patient_id)
            self.assertTrue(p_db.is_deleted)

    # ----------------------------------------------------
    # Phase 4 & 5: AI Diagnostic Pipeline & Prediction
    # ----------------------------------------------------
    def test_phase_4_and_5_ai_diagnostic_pipeline(self):
        # Register user & patient
        self.client.post("/register", json={"name": "Dr. John", "email": "john@smilesync.ai", "password": "Pass123!Password"})
        res_login = self.client.post("/login", json={"email": "john@smilesync.ai", "password": "Pass123!Password"})
        token = res_login.get_json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        user_id = res_login.get_json()["user_id"]

        # Create Patient
        res_p = self.client.post("/patients", json={
            "first_name": "Emma",
            "last_name": "Watson",
            "gender": "Female",
            "phone_number": "+1 555-0244",
            "qualification": "Actress",
            "age": 28
        }, headers=headers)
        patient_id = res_p.get_json()["patient"]["id"]

        # Generate test synthetic image (300x300 RGB)
        img = np.ones((300, 300, 3), dtype=np.uint8) * 200
        # Draw a synthetic face/mouth for landmark detection test
        cv2.circle(img, (150, 150), 100, (180, 180, 180), -1)
        cv2.ellipse(img, (150, 180), (40, 20), 0, 0, 180, (50, 50, 220), -1)
        _, img_encoded = cv2.imencode('.jpg', img)
        img_bytes = img_encoded.tobytes()

        # Execute AI Diagnostic Request
        data = {
            'user_id': str(user_id),
            'patient_id': str(patient_id),
            'file': (json.dumps({'dummy': 'file'}), 'test_smile.jpg') # fallback image stream
        }
        # Real multipart form with image
        import io
        data = {
            'user_id': str(user_id),
            'patient_id': str(patient_id),
            'image': (io.BytesIO(img_bytes), 'test_smile.jpg', 'image/jpeg')
        }
        # Mock MediaPipe landmark output with standard facial landmarks
        fake_landmarks = np.zeros((478, 3), dtype=np.float32)
        fake_landmarks[61] = [100, 180, 0]
        fake_landmarks[291] = [200, 180, 0]
        fake_landmarks[0] = [150, 170, 0]
        fake_landmarks[13] = [150, 175, 0]
        fake_landmarks[14] = [150, 185, 0]
        fake_landmarks[17] = [150, 190, 0]
        fake_landmarks[10] = [150, 50, 0]
        fake_landmarks[152] = [150, 250, 0]
        fake_landmarks[234] = [50, 150, 0]
        fake_landmarks[454] = [250, 150, 0]

        mock_result = {
            "landmarks": fake_landmarks,
            "raw_landmarks": fake_landmarks,
            "quality_score": 0.95,
            "head_tilt": 0.0
        }

        import unittest.mock
        with unittest.mock.patch("app.mesh_detector.process_image", return_value=mock_result):
            res_pred = self.client.post(
                '/predict',
                data=data,
                content_type='multipart/form-data',
                headers=headers
            )

        if res_pred.status_code != 200:
            print("PREDICT ERROR RESPONSE:", res_pred.status_code, res_pred.get_json())
        self.assertEqual(res_pred.status_code, 200)
        pred_json = res_pred.get_json()
        report = pred_json
        self.assertIn("features", report)
        self.assertIn("smile_symmetry", report["features"])
        self.assertIn("smile_width", report["features"])
        self.assertIn("smile_arc", report["features"])
        self.assertIn("severity", report)
        self.assertIn("smile_score", report)
        self.assertIn("recommendations", report)
        self.assertIn("clinical_interpretation", report)

        # Confirm historical immutable snapshot saved in database
        report_id = report["id"]
        with app.app_context():
            rep_db = SmileReport.query.get(report_id)
            self.assertEqual(rep_db.patient_id, patient_id)
            self.assertEqual(rep_db.patient_first_name, "Emma")
            self.assertEqual(rep_db.patient_last_name, "Watson")
            self.assertEqual(rep_db.patient_gender, "Female")

        # Test updating live patient profile does NOT change historical report snapshot
        self.client.put(f"/patients/{patient_id}", json={"last_name": "Watson-Smith", "phone_number": "+1 999-0000"}, headers=headers)

        with app.app_context():
            rep_db_after = SmileReport.query.get(report_id)
            # Historical report retains "Watson"
            self.assertEqual(rep_db_after.patient_last_name, "Watson")
            # Live patient is now "Watson-Smith"
            p_live = Patient.query.get(patient_id)
            self.assertEqual(p_live.last_name, "Watson-Smith")

    # ----------------------------------------------------
    # Phase 6 & 12: Backend API Audit & Settings
    # ----------------------------------------------------
    def test_phase_6_api_audit_and_settings(self):
        # Register user
        self.client.post("/register", json={"name": "Dr. Bob", "email": "bob@smilesync.ai", "password": "Pass123!Password"})
        res_login = self.client.post("/login", json={"email": "bob@smilesync.ai", "password": "Pass123!Password"})
        token = res_login.get_json()["access_token"]
        user_id = res_login.get_json()["user_id"]
        headers = {"Authorization": f"Bearer {token}"}

        # 1. GET /settings
        res_set = self.client.get(f"/settings/{user_id}", headers=headers)
        self.assertEqual(res_set.status_code, 200)

        # 2. PUT /settings
        res_set_up = self.client.put(f"/settings/{user_id}", json={"email_notifications": False, "theme": "Dark"}, headers=headers)
        self.assertEqual(res_set_up.status_code, 200)

        # 3. GET /profile
        res_prof = self.client.get(f"/profile/{user_id}", headers=headers)
        self.assertEqual(res_prof.status_code, 200)

        # 4. GET /notifications
        res_notif = self.client.get(f"/notifications?user_id={user_id}", headers=headers)
        self.assertEqual(res_notif.status_code, 200)

if __name__ == "__main__":
    unittest.main()
