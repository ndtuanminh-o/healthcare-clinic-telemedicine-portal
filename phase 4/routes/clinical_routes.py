# Medical record routes for the doctor screen 
from flask import Blueprint, jsonify, request
from db import get_db_connection  

clinical_bp = Blueprint("clinical", __name__)


@clinical_bp.route("/api/doctor/<int:doctor_id>/appointments")
def doctor_appointments(doctor_id):
    # List appointments of one doctor with patient name
    conn = get_db_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute(
        """
        SELECT a.appointment_id, a.appointment_date, a.status,
               p.patient_id, p.full_name AS patient_name
        FROM APPOINTMENT a
        JOIN PATIENT p ON p.patient_id = a.patient_id
        WHERE a.doctor_id = %s
        ORDER BY a.appointment_date DESC
        """,
        (doctor_id,),
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(rows)


@clinical_bp.route("/api/medical-records/<int:appointment_id>")
def get_record(appointment_id):
    # Get the medical record of an appointment
    conn = get_db_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute("SELECT * FROM MEDICAL_RECORD WHERE appointment_id = %s", (appointment_id,))
    row = cur.fetchone()
    cur.close()
    conn.close()
    return jsonify(row or {})


@clinical_bp.route("/api/medical-records", methods=["POST"])
def save_record():
    # Create or update the medical record of an appointment
    data = request.get_json()
    appointment_id = data.get("appointment_id")
    diagnosis = data.get("diagnosis", "").strip()
    notes = data.get("notes", "").strip()

    if not appointment_id or not diagnosis:
        return jsonify({"error": "appointment_id and diagnosis are required"}), 400

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT record_id FROM MEDICAL_RECORD WHERE appointment_id = %s", (appointment_id,))
    existing = cur.fetchone()
    if existing:
        cur.execute(
            "UPDATE MEDICAL_RECORD SET diagnosis = %s, notes = %s WHERE record_id = %s",
            (diagnosis, notes, existing[0]),
        )
        record_id = existing[0]
    else:
        cur.execute(
            "INSERT INTO MEDICAL_RECORD (appointment_id, diagnosis, notes) VALUES (%s, %s, %s)",
            (appointment_id, diagnosis, notes),
        )
        record_id = cur.lastrowid
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"record_id": record_id, "message": "Medical record saved"})
