import os
from dotenv import load_dotenv
from datetime import timedelta

load_dotenv()


class Config:

    SECRET_KEY = os.getenv(
        "SECRET_KEY",
        "change-this-secret-key"
    )

    JWT_SECRET_KEY = os.getenv(
        "JWT_SECRET_KEY",
        "change-this-jwt-secret"
    )

    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=8)

    SQLALCHEMY_DATABASE_URI = os.getenv(
        "DATABASE_URL",
        "sqlite:///smile_analysis.db"
    )

    SQLALCHEMY_TRACK_MODIFICATIONS = False

    MODEL_PATH = "models/smile_ai_model.pkl"
    SCALER_PATH = "models/scaler.pkl"

    UPLOAD_FOLDER = "uploads"
    REPORT_FOLDER = "reports"

    MAX_CONTENT_LENGTH = 10 * 1024 * 1024

    FRONTEND_URL = os.getenv(
        "FRONTEND_URL",
        "http://localhost:3000"
    )