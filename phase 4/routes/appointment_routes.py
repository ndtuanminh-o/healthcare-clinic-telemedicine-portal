import uuid
from flask import Blueprint, render_template, request, jsonify
import mysql.connector
from db import get_db_connection

appointment_bp = Blueprint("appointment", __name__)

@appointment_bp.route("/booking")
def booking_page():
    return render_template("booking.html")

@appointment_bp.route("/api/appointments/recent")
def recent_appointments():
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT a.appointment_id, p.full_name AS patient_name, p.phone_number,
                   d.full_name AS doctor_name,
                   DATE_FORMAT(a.appointment_date, '%Y-%m-%d') AS appointment_date,
                   TIME_FORMAT(a.start_time, '%H:%i') AS start_time,
                   TIME_FORMAT(a.end_time, '%H:%i') AS end_time,
                   a.consultation_type, a.status
            FROM APPOINTMENT a
            JOIN PATIENT p ON a.patient_id = p.patient_id
            JOIN DOCTOR d ON a.doctor_id = d.doctor_id
            WHERE a.deleted_at IS NULL
            ORDER BY a.booking_time DESC
            LIMIT 10
            """
        )
        rows = cursor.fetchall()
        return jsonify(rows)
    except Exception as e:
        return jsonify({"error": "Unable to retrieve recent appointments."}), 500
    finally:
        if conn and conn.is_connected():
            cursor.close()
            conn.close()

@appointment_bp.route("/api/appointments", methods=["POST"])
@appointment_bp.route("/booking", methods=["POST"])
def create_appointment():
    data = request.get_json(silent=True) or request.form
    full_name = data.get("full_name", "").strip()
    phone_number = data.get("phone_number", "").strip()
    date_of_birth = data.get("date_of_birth", "").strip()
    gender = data.get("gender", "O")
    address = data.get("address", "").strip() or None

    doctor_id = data.get("doctor_id", "").strip()
    appointment_date = data.get("appointment_date", "").strip()
    start_time = data.get("start_time", "").strip()
    end_time = data.get("end_time", "").strip()
    consultation_type = data.get("consultation_type", "In-Person")
    telemedicine_video_link = data.get("telemedicine_video_link", "").strip() or None
    reason_for_visit = data.get("reason_for_visit", "").strip() or None

    if not full_name or not phone_number or not date_of_birth or not doctor_id or not appointment_date or not start_time or not end_time:
        return jsonify({"error": "Please fill in all required fields."}), 400

    if end_time <= start_time:
        return jsonify({"error": "End time must be after start time."}), 400

    if consultation_type == "Telemedicine" and not telemedicine_video_link:
        # Default placeholder video room if not explicitly entered
        telemedicine_video_link = f"https://meet.clinic-portal.vn/room-{uuid.uuid4().hex[:8]}"

    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        # 1. Lookup or create patient
        cursor.execute("SELECT patient_id FROM PATIENT WHERE phone_number = %s", (phone_number,))
        patient = cursor.fetchone()

        if patient:
            patient_id = patient["patient_id"]
        else:
            patient_id = str(uuid.uuid4())
            cursor.execute(
                """
                INSERT INTO PATIENT (patient_id, full_name, date_of_birth, gender, phone_number, address, status)
                VALUES (%s, %s, %s, %s, %s, %s, 'Active')
                """,
                (patient_id, full_name, date_of_birth, gender, phone_number, address)
            )

        # 2. Check no overlap for both doctor and patient (BR-01)
        cursor.execute(
            """
            SELECT doctor_id, patient_id
            FROM APPOINTMENT
            WHERE (doctor_id = %s OR patient_id = %s)
              AND appointment_date = %s
              AND status != 'Cancelled'
              AND deleted_at IS NULL
              AND start_time < %s AND end_time > %s
            LIMIT 1
            """,
            (doctor_id, patient_id, appointment_date, end_time, start_time)
        )
        overlap = cursor.fetchone()
        if overlap:
            if overlap["doctor_id"] == doctor_id:
                return jsonify({"error": "Doctor already has an active appointment in this time slot."}), 400
            else:
                return jsonify({"error": "Patient already has another appointment in this time slot."}), 400

        # 3. Create appointment
        appointment_id = str(uuid.uuid4())
        cursor.execute(
            """
            INSERT INTO APPOINTMENT (
                appointment_id, patient_id, doctor_id, appointment_date,
                start_time, end_time, consultation_type, telemedicine_video_link,
                status, reason_for_visit
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 'Scheduled', %s)
            """,
            (
                appointment_id, patient_id, doctor_id, appointment_date,
                start_time, end_time, consultation_type, telemedicine_video_link,
                reason_for_visit
            )
        )

        # 4. Generate consolidated invoice (BR-11)
        cursor.execute(
            """
            SELECT COALESCE(gp.consultation_fee, sp.consultation_fee, 150000.00) AS fee
            FROM DOCTOR d
            LEFT JOIN GENERAL_PRACTITIONER gp ON d.doctor_id = gp.doctor_id
            LEFT JOIN SPECIALIST sp ON d.doctor_id = sp.doctor_id
            WHERE d.doctor_id = %s
            """,
            (doctor_id,)
        )
        fee_row = cursor.fetchone()
        consultation_fee = fee_row["fee"] if fee_row else 150000.00

        invoice_id = str(uuid.uuid4())
        cursor.execute(
            """
            INSERT INTO INVOICE (invoice_id, appointment_id, patient_id, total_amount, payment_status, payment_method)
            VALUES (%s, %s, %s, %s, 'Unpaid', 'Cash')
            """,
            (invoice_id, appointment_id, patient_id, consultation_fee)
        )

        conn.commit()
        return jsonify({
            "success": True,
            "message": "Appointment booked successfully.",
            "appointment_id": appointment_id,
            "invoice_id": invoice_id
        }), 201

    except mysql.connector.Error as err:
        if conn:
            conn.rollback()
        return jsonify({"error": f"Database error: {err.msg}"}), 500
    except Exception as e:
        if conn:
            conn.rollback()
        return jsonify({"error": f"Server error: {str(e)}"}), 500
    finally:
        if conn and conn.is_connected():
            cursor.close()
            conn.close()
