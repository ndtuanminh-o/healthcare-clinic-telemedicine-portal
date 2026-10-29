import mysql.connector
from flask import Blueprint, current_app, jsonify, render_template

from db import close_quietly, get_connection

dashboard_bp = Blueprint("dashboard", __name__)


def fetch_all(sql, params=None):
    """Connect to MySQL, execute a SQL query and return a list of dicts."""
    connection = None
    cursor = None
    try:
        connection = get_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute(sql, params or ())
        return cursor.fetchall()
    finally:
        close_quietly(cursor, connection)


def json_report(sql, params=None):
    """Run a report query and return it as JSON, hiding database details on failure."""
    try:
        return jsonify(fetch_all(sql, params))
    except mysql.connector.Error:
        current_app.logger.exception("dashboard report failed")
        return jsonify({"error": "Could not load the report."}), 500


@dashboard_bp.route("/dashboard")
def dashboard():
    """Route for the Admin Dashboard interface."""
    return render_template("dashboard.html")


# ========================================================================
#  1. Q01. Telemedicine ratio for every doctor in the latest data month
# ========================================================================
@dashboard_bp.route("/api/dashboard/telemedicine")
def telemedicine_report():
    sql = """
        WITH report_period AS (
            SELECT
                DATE_FORMAT(MAX(appointment_date), '%Y-%m-01') AS start_date,
                DATE_ADD(DATE_FORMAT(MAX(appointment_date), '%Y-%m-01'), INTERVAL 1 MONTH) AS end_date
            FROM appointment
            WHERE deleted_at IS NULL
        ),
        month_stats AS (
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
            CROSS JOIN report_period rp
            WHERE a.status <> 'Cancelled'
              AND a.deleted_at IS NULL
              AND a.appointment_date >= rp.start_date
              AND a.appointment_date < rp.end_date
            GROUP BY a.doctor_id
        )
        SELECT
            d.full_name AS doctor_name,
            COALESCE(m.total_appointments, 0) AS total_appointments,
            COALESCE(m.telemedicine_appointments, 0) AS telemedicine_appointments,
            ROUND(
                100 * COALESCE(m.telemedicine_appointments, 0)
                / NULLIF(m.total_appointments, 0),
                2
            ) AS telemedicine_percentage
        FROM doctor d
        LEFT JOIN month_stats m
            ON m.doctor_id = d.doctor_id
        WHERE d.deleted_at IS NULL
        ORDER BY telemedicine_percentage DESC, d.full_name
    """
    return json_report(sql)


# ========================================================================
# 2. Q06. Medicines with monthly revenue above the average medicine revenue
# ========================================================================
@dashboard_bp.route("/api/dashboard/medicine-revenue")
def medicine_revenue_report():
    sql = """
        WITH report_period AS (
            SELECT
                DATE_FORMAT(MAX(appointment_date), '%Y-%m-01') AS start_date,
                DATE_ADD(DATE_FORMAT(MAX(appointment_date), '%Y-%m-01'), INTERVAL 1 MONTH) AS end_date
            FROM appointment
            WHERE deleted_at IS NULL
        ),
        medicine_monthly_revenue AS (
            SELECT
                m.medicine_id,
                m.medicine_name,
                SUM(pi.quantity * pi.unit_price_at_prescription) AS total_medicine_revenue
            FROM medicine m
            JOIN prescription_item pi ON pi.medicine_id = m.medicine_id
            JOIN digital_prescription dp ON dp.prescription_id = pi.prescription_id
            CROSS JOIN report_period rp
            WHERE dp.status IN ('Issued', 'Dispensed')
              AND dp.deleted_at IS NULL
              AND dp.issue_date >= rp.start_date
              AND dp.issue_date < rp.end_date
            GROUP BY m.medicine_id, m.medicine_name
        ),
        average_revenue AS (
            SELECT AVG(total_medicine_revenue) AS average_revenue_per_medicine
            FROM medicine_monthly_revenue
        )
        SELECT
            r.medicine_id,
            r.medicine_name,
            r.total_medicine_revenue,
            ROUND(a.average_revenue_per_medicine, 2) AS average_revenue_per_medicine
        FROM medicine_monthly_revenue r
        CROSS JOIN average_revenue a
        WHERE r.total_medicine_revenue > a.average_revenue_per_medicine
        ORDER BY r.total_medicine_revenue DESC
    """
    return json_report(sql)


# ========================================================================
# 3. Q09. Months where Telemedicine exceeds the configured share (20%) of realised revenue
# ========================================================================
@dashboard_bp.route("/api/dashboard/telemedicine-revenue")
def telemedicine_revenue_report():
    sql = """
        WITH monthly_revenue AS (
            SELECT
                YEAR(a.appointment_date) AS revenue_year,
                MONTH(a.appointment_date) AS revenue_month,
                SUM(i.total_amount) AS total_monthly_revenue,
                SUM(
                    CASE
                        WHEN a.consultation_type = 'Telemedicine'
                        THEN i.total_amount
                        ELSE 0
                    END
                ) AS telemedicine_revenue
            FROM appointment a
            JOIN invoice i ON i.appointment_id = a.appointment_id
            WHERE a.status = 'Completed'
              AND a.deleted_at IS NULL
              AND i.payment_status = 'Paid'
            GROUP BY YEAR(a.appointment_date), MONTH(a.appointment_date)
        )
        SELECT
            revenue_year,
            revenue_month,
            total_monthly_revenue,
            telemedicine_revenue,
            ROUND(100.0 * telemedicine_revenue / NULLIF(total_monthly_revenue, 0), 2)
                AS telemedicine_revenue_percentage
        FROM monthly_revenue
        WHERE telemedicine_revenue / NULLIF(total_monthly_revenue, 0) > %s
        ORDER BY revenue_year, revenue_month
    """
    threshold = current_app.config["TELEMEDICINE_SHARE_THRESHOLD"]
    return json_report(sql, (threshold,))


# ========================================================================
# 4. Q10. VIP patients above the 80th percentile of total medical spending
# ========================================================================
@dashboard_bp.route("/api/dashboard/vip-patients")
def vip_patients_report():
    sql = """
        WITH doctor_fee AS (
            SELECT
                d.doctor_id,
                d.full_name,
                COALESCE(gp.consultation_fee, sp.consultation_fee, 0) AS fee
            FROM doctor d
            LEFT JOIN general_practitioner gp ON gp.doctor_id = d.doctor_id
            LEFT JOIN specialist sp ON sp.doctor_id = d.doctor_id
        ), patient_doctor AS (
            SELECT
                a.patient_id,
                a.doctor_id,
                COUNT(*) AS visits,
                MAX(a.appointment_date) AS last_visit
            FROM appointment a
            WHERE a.status = 'Completed'
              AND a.deleted_at IS NULL
            GROUP BY a.patient_id, a.doctor_id
        ), consultation_spend AS (
            SELECT
                pd.patient_id,
                SUM(pd.visits * df.fee) AS consultation_total
            FROM patient_doctor pd
            JOIN doctor_fee df ON df.doctor_id = pd.doctor_id
            GROUP BY pd.patient_id
        ), ranked_doctors AS (
            SELECT
                pd.patient_id,
                df.full_name AS doctor_name,
                ROW_NUMBER() OVER (
                    PARTITION BY pd.patient_id
                    ORDER BY pd.visits DESC, pd.last_visit DESC, df.full_name
                ) AS doctor_rank
            FROM patient_doctor pd
            JOIN doctor_fee df ON df.doctor_id = pd.doctor_id
        ), medicine_spend AS (
            SELECT
                mr.patient_id,
                SUM(pi.quantity * pi.unit_price_at_prescription) AS medicine_total
            FROM medical_record mr
            JOIN appointment a
                ON a.appointment_id = mr.appointment_id
               AND a.status = 'Completed'
               AND a.deleted_at IS NULL
            JOIN digital_prescription dp ON dp.record_id = mr.record_id
            JOIN prescription_item pi ON pi.prescription_id = dp.prescription_id
            WHERE dp.status IN ('Issued', 'Dispensed')
              AND dp.deleted_at IS NULL
              AND mr.deleted_at IS NULL
            GROUP BY mr.patient_id
        ), patient_spending AS (
            SELECT
                p.patient_id,
                p.full_name AS patient_name,
                COALESCE(cs.consultation_total, 0) AS consultation_total,
                COALESCE(ms.medicine_total, 0) AS medicine_total,
                COALESCE(cs.consultation_total, 0)
                    + COALESCE(ms.medicine_total, 0) AS total_medical_spending
            FROM patient p
            LEFT JOIN consultation_spend cs ON cs.patient_id = p.patient_id
            LEFT JOIN medicine_spend ms ON ms.patient_id = p.patient_id
            WHERE p.deleted_at IS NULL
              AND (cs.patient_id IS NOT NULL OR ms.patient_id IS NOT NULL)
        ), percentile_spending AS (
            SELECT
                s.*,
                PERCENT_RANK() OVER (ORDER BY s.total_medical_spending) AS spending_percent_rank
            FROM patient_spending s
        )
        SELECT
            ps.patient_id,
            ps.patient_name,
            rd.doctor_name AS primary_treating_doctor,
            ps.consultation_total,
            ps.medicine_total,
            ps.total_medical_spending,
            ROUND(100.0 * ps.spending_percent_rank, 2) AS spending_percentile_rank
        FROM percentile_spending ps
        LEFT JOIN ranked_doctors rd
            ON rd.patient_id = ps.patient_id
           AND rd.doctor_rank = 1
        WHERE ps.spending_percent_rank >= 0.80
        ORDER BY ps.total_medical_spending DESC
    """
    return json_report(sql)
