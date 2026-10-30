import uuid
from flask import Blueprint, jsonify, request
from db import get_db_connection

clinical_bp = Blueprint("clinical", __name__)

@clinical_bp.route("/api/doctors")
def list_doctors():
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor(dictionary=True)
        cur.execute(
            """
            SELECT d.doctor_id, d.full_name, d.doctor_type,
                   COALESCE(sp.specialty, CONCAT('GP - Room ', gp.clinic_room_no), 'General Practice') AS department,
                   COALESCE(gp.consultation_fee, sp.consultation_fee, 0) AS consultation_fee
            FROM DOCTOR d
            LEFT JOIN GENERAL_PRACTITIONER gp ON d.doctor_id = gp.doctor_id
            LEFT JOIN SPECIALIST sp ON d.doctor_id = sp.doctor_id
            WHERE d.status = 'Active' AND d.deleted_at IS NULL
            ORDER BY d.doctor_type, d.full_name
            """
        )
        rows = cur.fetchall()
        return jsonify(rows)
    except Exception as e:
        return jsonify({"error": "Failed to load doctors."}), 500
    finally:
        if conn and conn.is_connected():
            cur.close()
            conn.close()

@clinical_bp.route("/api/doctor/<doctor_id>/appointments")
def doctor_appointments(doctor_id):
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor(dictionary=True)
        cur.execute(
            """
            SELECT a.appointment_id,
                   DATE_FORMAT(a.appointment_date, '%Y-%m-%d') AS appointment_date,
                   TIME_FORMAT(a.start_time, '%H:%i') AS start_time,
                   TIME_FORMAT(a.end_time, '%H:%i') AS end_time,
                   a.consultation_type,
                   a.status,
                   a.reason_for_visit,
                   p.full_name AS patient_name,
                   p.phone_number AS patient_phone
            FROM APPOINTMENT a
            JOIN PATIENT p ON p.patient_id = a.patient_id
            WHERE a.doctor_id = %s AND a.deleted_at IS NULL
            ORDER BY a.appointment_date DESC, a.start_time
            """,
            (doctor_id,),
        )
        rows = cur.fetchall()
        return jsonify(rows)
    except Exception as e:
        return jsonify({"error": "Failed to load doctor appointments."}), 500
    finally:
        if conn and conn.is_connected():
            cur.close()
            conn.close()

@clinical_bp.route("/api/medical-records/<appointment_id>")
def get_record(appointment_id):
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor(dictionary=True)
        cur.execute(
            """
            SELECT record_id, diagnosis, clinical_notes, treatment_plan
            FROM MEDICAL_RECORD
            WHERE appointment_id = %s AND deleted_at IS NULL
            """,
            (appointment_id,),
        )
        row = cur.fetchone()
        return jsonify(row or {})
    except Exception as e:
        return jsonify({"error": "Failed to load medical record."}), 500
    finally:
        if conn and conn.is_connected():
            cur.close()
            conn.close()

@clinical_bp.route("/api/medical-records", methods=["POST"])
def save_record():
    data = request.get_json(silent=True) or {}
    appointment_id = data.get("appointment_id")
    diagnosis = (data.get("diagnosis") or "").strip()
    clinical_notes = (data.get("clinical_notes") or "").strip()
    treatment_plan = (data.get("treatment_plan") or "").strip()

    if not appointment_id or not diagnosis:
        return jsonify({"error": "Appointment ID and diagnosis are mandatory."}), 400

    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor(dictionary=True)

        cur.execute("SELECT patient_id, doctor_id, status FROM APPOINTMENT WHERE appointment_id = %s", (appointment_id,))
        appt = cur.fetchone()
        if not appt:
            return jsonify({"error": "Appointment not found."}), 404

        patient_id = appt["patient_id"]
        doctor_id = appt["doctor_id"]

        # Check if doctor is specialist
        cur.execute("SELECT doctor_id FROM SPECIALIST WHERE doctor_id = %s", (doctor_id,))
        spec = cur.fetchone()
        specialist_id = spec["doctor_id"] if spec else None

        cur.execute("SELECT record_id FROM MEDICAL_RECORD WHERE appointment_id = %s", (appointment_id,))
        existing = cur.fetchone()
        if existing:
            record_id = existing["record_id"]
            cur.execute(
                """
                UPDATE MEDICAL_RECORD
                SET diagnosis = %s, clinical_notes = %s, treatment_plan = %s, deleted_at = NULL
                WHERE record_id = %s
                """,
                (diagnosis, clinical_notes, treatment_plan, record_id),
            )
        else:
            record_id = str(uuid.uuid4())
            cur.execute(
                """
                INSERT INTO MEDICAL_RECORD
                (record_id, appointment_id, patient_id, specialist_id, diagnosis, clinical_notes, treatment_plan)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                """,
                (record_id, appointment_id, patient_id, specialist_id, diagnosis, clinical_notes, treatment_plan),
            )

        # Transition appointment to Completed (BR-03)
        cur.execute(
            "UPDATE APPOINTMENT SET status = 'Completed' WHERE appointment_id = %s AND status != 'Cancelled'",
            (appointment_id,)
        )

        conn.commit()
        return jsonify({"record_id": record_id, "message": "Medical record saved successfully."}), 200
    except Exception as e:
        if conn:
            conn.rollback()
        return jsonify({"error": f"Failed to save record: {str(e)}"}), 400
    finally:
        if conn and conn.is_connected():
            cur.close()
            conn.close()
