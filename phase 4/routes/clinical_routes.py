# Medical record routes for the doctor screen (Phase 4 - Loc)
import uuid
from flask import Blueprint, jsonify, request
from db import get_db_connection  

clinical_bp = Blueprint("clinical", __name__)


@clinical_bp.route("/api/doctors")
def list_doctors():
    # Active doctors for the doctor dropdown
    conn = get_db_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute(
        "SELECT doctor_id, full_name FROM DOCTOR "
        "WHERE status = 'Active' AND deleted_at IS NULL ORDER BY full_name"
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(rows)


@clinical_bp.route("/api/doctor/<doctor_id>/appointments")
def doctor_appointments(doctor_id):
    # Appointments of one doctor with patient name
    conn = get_db_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute(
        """
        SELECT a.appointment_id,
               DATE_FORMAT(a.appointment_date, '%Y-%m-%d') AS appointment_date,
               TIME_FORMAT(a.start_time, '%H:%i') AS start_time,
               a.status, p.full_name AS patient_name
        FROM APPOINTMENT a
        JOIN PATIENT p ON p.patient_id = a.patient_id
        WHERE a.doctor_id = %s AND a.deleted_at IS NULL
        ORDER BY a.appointment_date DESC, a.start_time
        """,
        (doctor_id,),
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(rows)


@clinical_bp.route("/api/medical-records/<appointment_id>")
def get_record(appointment_id):
    # Medical record of an appointment (empty object if none yet)
    conn = get_db_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute(
        "SELECT record_id, diagnosis, clinical_notes, treatment_plan "
        "FROM MEDICAL_RECORD WHERE appointment_id = %s AND deleted_at IS NULL",
        (appointment_id,),
    )
    row = cur.fetchone()
    cur.close()
    conn.close()
    return jsonify(row or {})


@clinical_bp.route("/api/medical-records", methods=["POST"])
def save_record():
    # Create or update the medical record of an appointment
    data = request.get_json()
    appointment_id = data.get("appointment_id")
    diagnosis = (data.get("diagnosis") or "").strip()
    clinical_notes = (data.get("clinical_notes") or "").strip()
    treatment_plan = (data.get("treatment_plan") or "").strip()

    if not appointment_id or not diagnosis:
        return jsonify({"error": "appointment_id and diagnosis are required"}), 400

    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("SELECT patient_id FROM APPOINTMENT WHERE appointment_id = %s", (appointment_id,))
        appt = cur.fetchone()
        if not appt:
            return jsonify({"error": "Appointment not found"}), 404

        cur.execute("SELECT record_id FROM MEDICAL_RECORD WHERE appointment_id = %s", (appointment_id,))
        existing = cur.fetchone()
        if existing:
            record_id = existing[0]
            cur.execute(
                "UPDATE MEDICAL_RECORD SET diagnosis = %s, clinical_notes = %s, "
                "treatment_plan = %s, deleted_at = NULL WHERE record_id = %s",
                (diagnosis, clinical_notes, treatment_plan, record_id),
            )
        else:
            record_id = str(uuid.uuid4())
            cur.execute(
                "INSERT INTO MEDICAL_RECORD "
                "(record_id, appointment_id, patient_id, diagnosis, clinical_notes, treatment_plan) "
                "VALUES (%s, %s, %s, %s, %s, %s)",
                (record_id, appointment_id, appt[0], diagnosis, clinical_notes, treatment_plan),
            )
        conn.commit()
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 400
    finally:
        cur.close()
        conn.close()
    return jsonify({"record_id": record_id, "message": "Medical record saved"})
