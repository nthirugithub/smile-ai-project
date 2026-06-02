from ai_engine.face_mesh_3d import FaceMesh3D
from ai_engine.feature_extractor import FeatureExtractor
from ai_engine.severity_classifier import SeverityClassifier
from ai_engine.treatment_engine import TreatmentEngine

mesh = FaceMesh3D()

result = mesh.process_image("test.jpg")

if result:

    landmarks = result["landmarks"]

    extractor = FeatureExtractor(landmarks)

    features = extractor.extract_all_features()

    print("\n===== EXTRACTED FEATURES =====\n")

    for key, value in features.items():

        print(f"{key}: {value}")

    classifier = SeverityClassifier(features)

    prediction = classifier.classify()

    print("\n===== AI SEVERITY ANALYSIS =====\n")

    print("Severity:", prediction["severity"])
    print("AI Score:", prediction["score"])

    engine = TreatmentEngine(features, prediction)

    recommendations = engine.generate_recommendations()

    print("\n===== TREATMENT RECOMMENDATIONS =====\n")

    for item in recommendations:

        print("-", item)