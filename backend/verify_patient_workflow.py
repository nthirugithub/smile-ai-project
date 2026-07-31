import os
import sys
import unittest
import json

# Ensure backend folder is in path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import app, db, Patient, SmileReport, User

class TestPatientWorkflow(unittest.TestCase):
    def setUp(self):
        app.config['TESTING'] = True
        app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
        self.client = app.test_client()
        with app.app_context():
            db.create_all()
            # Create dummy user
            user = User(
                name="Dr. Smith",
                email="doctor@smileai.com",
                password="hashedpassword"
            )
            db.session.add(user)
            db.session.commit()
            self.user_id = user.id

            # Create auth token for dummy user
            from flask_jwt_extended import create_access_token
            self.token = create_access_token(identity=str(user.id))
            self.headers = {"Authorization": f"Bearer {self.token}"}

    def tearDown(self):
        with app.app_context():
            db.session.remove()
            db.drop_all()

    def test_patient_crud_and_duplicate_detection(self):
        with app.app_context():
            # 1. Validation test: Missing required fields
            res = self.client.post("/patients", json={
                "first_name": "",
                "last_name": "Doe",
                "gender": "Male"
            }, headers=self.headers)
            self.assertEqual(res.status_code, 400)
            self.assertIn("First Name is required", res.get_json()["error"])

            # 2. Successful creation
            res = self.client.post("/patients", json={
                "first_name": "John",
                "last_name": "Smith",
                "gender": "Male",
                "phone_number": "9876543210",
                "qualification": "Software Engineer",
                "age": 30,
                "notes": "Initial consultation"
            }, headers=self.headers)
            self.assertEqual(res.status_code, 201)
            data = res.get_json()
            self.assertTrue(data["success"])
            self.assertEqual(data["is_duplicate"], False)
            p_data = data["patient"]
            self.assertEqual(p_data["patient_code"], "P-000001")
            patient_id = p_data["id"]

            # 3. Duplicate check trigger
            res_dup = self.client.post("/patients", json={
                "first_name": "John",
                "last_name": "Smith",
                "gender": "Male",
                "phone_number": "9876543210"
            }, headers=self.headers)
            self.assertEqual(res_dup.status_code, 200)
            dup_data = res_dup.get_json()
            self.assertTrue(dup_data["is_duplicate"])
            self.assertEqual(dup_data["existing_patient"]["id"], patient_id)

            # 4. Force create duplicate
            res_force = self.client.post("/patients", json={
                "first_name": "John",
                "last_name": "Smith",
                "gender": "Male",
                "phone_number": "9876543210",
                "force_create": True
            }, headers=self.headers)
            self.assertEqual(res_force.status_code, 201)
            self.assertEqual(res_force.get_json()["patient"]["patient_code"], "P-000002")

            # 5. Patient Search by Code and Name
            res_search = self.client.get("/patients?q=P-000001", headers=self.headers)
            self.assertEqual(res_search.status_code, 200)
            self.assertEqual(len(res_search.get_json()["patients"]), 1)

            res_search_name = self.client.get("/patients?q=Smith", headers=self.headers)
            self.assertEqual(res_search_name.status_code, 200)
            self.assertEqual(len(res_search_name.get_json()["patients"]), 2)

            # 6. Update patient
            res_up = self.client.put(f"/patients/{patient_id}", json={
                "phone_number": "1112223333",
                "qualification": "Senior Engineer"
            }, headers=self.headers)
            self.assertEqual(res_up.status_code, 200)
            self.assertEqual(res_up.get_json()["patient"]["phone_number"], "1112223333")

            # 7. Soft Delete patient
            res_del = self.client.delete(f"/patients/{patient_id}", headers=self.headers)
            self.assertEqual(res_del.status_code, 200)

            # Confirm deleted patient is excluded from list
            res_list = self.client.get("/patients", headers=self.headers)
            self.assertEqual(len(res_list.get_json()["patients"]), 1)
            self.assertEqual(res_list.get_json()["patients"][0]["patient_code"], "P-000002")

    def test_legacy_report_backward_compatibility(self):
        with app.app_context():
            # Create a legacy report without patient_id
            legacy_report = SmileReport(
                patient_name="Patient 1",
                smile_symmetry=0.92,
                smile_width=0.45,
                smile_arc=0.28,
                midline_deviation=0.01,
                lip_opening=0.10,
                gingival_display=0.02,
                buccal_corridor=0.12,
                face_ratio=1.30,
                severity="Normal",
                confidence=0.95,
                user_id=self.user_id
            )
            db.session.add(legacy_report)
            db.session.commit()

            # Test GET /reports
            res = self.client.get("/reports", headers=self.headers)
            self.assertEqual(res.status_code, 200)
            reports = res.get_json()["reports"]
            self.assertEqual(len(reports), 1)
            self.assertEqual(reports[0]["patient_name"], "Patient 1")
            self.assertEqual(reports[0]["patient_code"], f"P-{legacy_report.id:06d}")

            # Test GET /reports/<id>
            res_single = self.client.get(f"/reports/{legacy_report.id}", headers=self.headers)
            self.assertEqual(res_single.status_code, 200)
            rep = res_single.get_json()["report"]
            self.assertEqual(rep["patient_name"], "Patient 1")
            self.assertEqual(rep["patient_code"], f"P-{legacy_report.id:06d}")

if __name__ == "__main__":
    unittest.main()
