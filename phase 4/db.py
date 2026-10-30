import mysql.connector
from config import Config

def get_db_connection():
    return mysql.connector.connect(
        host=Config.DB_HOST,
        user=Config.DB_USER,
        password=Config.DB_PASSWORD,
        database=Config.DB_NAME,
        port=Config.DB_PORT,
        charset="utf8mb4",
        use_unicode=True
    )

def get_connection():
    return get_db_connection()

def close_quietly(cursor=None, connection=None):
    if cursor:
        try:
            cursor.close()
        except Exception:
            pass
    if connection and connection.is_connected():
        try:
            connection.close()
        except Exception:
            pass
