import uuid
from flask import Blueprint, render_template, request, redirect, url_for, flash
import mysql.connector
from db import get_db_connection

appointment_bp = Blueprint("appointment", __name__)

@appointment_bp.route("/booking", methods=["GET", "POST"])
def booking():
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        if request.method == "POST":
            full_name = request.form.get("full_name", "").strip()
            phone_number = request.form.get("phone_number", "").strip()
            date_of_birth = request.form.get("date_of_birth", "").strip()
            gender = request.form.get("gender", "O")
            address = request.form.get("address", "").strip() or None

            doctor_id = request.form.get("doctor_id", "").strip()
            appointment_date = request.form.get("appointment_date", "").strip()
            start_time = request.form.get("start_time", "").strip()
            end_time = request.form.get("end_time", "").strip()
            consultation_type = request.form.get("consultation_type", "In-Person")
            telemedicine_video_link = request.form.get("telemedicine_video_link", "").strip() or None
            reason_for_visit = request.form.get("reason_for_visit", "").strip() or None

            if not full_name or not phone_number or not date_of_birth or not doctor_id or not appointment_date or not start_time or not end_time:
                flash("Please fill in all required fields.", "danger")
                return redirect(url_for("appointment.booking"))

            if end_time <= start_time:
                flash("Constraint Error: End time must be after start time (end_time > start_time).", "danger")
                return redirect(url_for("appointment.booking"))

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

            cursor.execute(
                """
                SELECT COUNT(*) AS overlap_count
                FROM APPOINTMENT
                WHERE doctor_id = %s
                  AND appointment_date = %s
                  AND status != 'Cancelled'
                  AND ((start_time < %s AND end_time > %s)
                    OR (start_time < %s AND end_time > %s)
                    OR (start_time >= %s AND end_time <= %s))
                """,
                (doctor_id, appointment_date, end_time, start_time, start_time, start_time, start_time, end_time)
            )
            overlap_row = cursor.fetchone()
            if overlap_row and overlap_row["overlap_count"] > 0:
                flash("Business Rule Violation BR-01: Doctor already has an overlapping appointment in this time slot.", "danger")
                return redirect(url_for("appointment.booking"))

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

            conn.commit()
            flash("Appointment booked successfully!", "success")
            return redirect(url_for("appointment.booking"))

        cursor.execute(
            """
            SELECT d.doctor_id, d.full_name, d.doctor_type,
                   COALESCE(s.specialty, gp.clinic_room_no) AS detail,
                   COALESCE(s.consultation_fee, gp.consultation_fee) AS fee
            FROM DOCTOR d
            LEFT JOIN SPECIALIST s ON d.doctor_id = s.doctor_id
            LEFT JOIN GENERAL_PRACTITIONER gp ON d.doctor_id = gp.doctor_id
            WHERE d.status = 'Active'
            ORDER BY d.full_name
            """
        )
        doctors = cursor.fetchall()

        cursor.execute(
            """
            SELECT a.appointment_id, p.full_name AS patient_name, p.phone_number,
                   d.full_name AS doctor_name, a.appointment_date,
                   a.start_time, a.end_time, a.consultation_type, a.status
            FROM APPOINTMENT a
            JOIN PATIENT p ON a.patient_id = p.patient_id
            JOIN DOCTOR d ON a.doctor_id = d.doctor_id
            ORDER BY a.booking_time DESC
            LIMIT 10
            """
        )
        recent_appointments = cursor.fetchall()

        return render_template("booking.html", doctors=doctors, appointments=recent_appointments)

    except mysql.connector.Error as err:
        if conn:
            conn.rollback()
        flash(f"Database Error: {err.msg}", "danger")
        return redirect(url_for("appointment.booking"))
    except Exception as e:
        if conn:
            conn.rollback()
        flash(f"System Error: {str(e)}", "danger")
        return redirect(url_for("appointment.booking"))
    finally:
        if conn and conn.is_connected():
            cursor.close()
            conn.close()
