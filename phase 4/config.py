import os

class Config:
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_USER = os.getenv("DB_USER", "root")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "")
    DB_NAME = os.getenv("DB_NAME", "healthcare_portal")
    DB_PORT = int(os.getenv("DB_PORT", 3306))
    SECRET_KEY = os.getenv("SECRET_KEY", "clinic_secret_key_2026")
    TELEMEDICINE_SHARE_THRESHOLD = float(os.getenv("TELEMEDICINE_SHARE_THRESHOLD", 0.20))
