from flask import Blueprint, render_template, jsonify
from db import get_connection

dashboard_bp = Blueprint("dashboard", __name__)

def fetch_all(sql):
    connection = get_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(sql)
        return cursor.fetchall()
    finally:
        cursor.close()
        connection.close()

@dashboard_bp.route("/dashboard")
def dashboard():
    return render_template("dashboard.html")

@dashboard_bp.route("/api/dashboard/telemedicine")
def telemedicine_report():
    sql = """
        WITH month_stats AS (
            SELECT
                a.doctor_id,
                COUNT(*) AS total_appointments,
                SUM(
                    CASE
                        WHEN a.consultation_type = 'Telemedicine'
                        THEN 1 ELSE 0
                    END
                ) AS telemedicine_appointments
            FROM appointment a
            WHERE a.status <> 'Cancelled'
              AND a.deleted_at IS NULL
            GROUP BY a.doctor_id
        )
        SELECT
            d.full_name AS doctor_name,
            COALESCE(m.total_appointments, 0) AS total_appointments,
            COALESCE(m.telemedicine_appointments, 0)
                AS telemedicine_appointments,
            ROUND(
                100 * COALESCE(m.telemedicine_appointments, 0)
                / NULLIF(m.total_appointments, 0),
                2
            ) AS telemedicine_percentage
        FROM doctor d
        LEFT JOIN month_stats m
            ON m.doctor_id = d.doctor_id
        WHERE d.deleted_at IS NULL
        ORDER BY telemedicine_percentage DESC
    """

    return jsonify(fetch_all(sql))
