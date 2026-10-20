# Prescription routes for the doctor screen (Phase 4 - Loc)
import uuid
from flask import Blueprint, jsonify, request
from db import get_db_connection  

prescription_bp = Blueprint("prescription", __name__)


@prescription_bp.route("/api/medicines")
def list_medicines():
    conn = get_db_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute("SELECT medicine_id, medicine_name, unit FROM MEDICINE ORDER BY medicine_name")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(rows)


@prescription_bp.route("/api/prescriptions/<record_id>")
def get_prescription(record_id):
    # Prescription items of a medical record
    conn = get_db_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute(
        """
        SELECT m.medicine_name, pi.dosage, pi.frequency, pi.duration_days,
               pi.quantity, pi.unit_price_at_prescription
        FROM DIGITAL_PRESCRIPTION dp
        JOIN PRESCRIPTION_ITEM pi ON pi.prescription_id = dp.prescription_id
        JOIN MEDICINE m ON m.medicine_id = pi.medicine_id
        WHERE dp.record_id = %s AND dp.deleted_at IS NULL
        """,
        (record_id,),
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(rows)


@prescription_bp.route("/api/prescriptions", methods=["POST"])
def create_prescription():
    # Body: {record_id, items: [{medicine_id, dosage, frequency, duration_days, quantity}]}
    data = request.get_json()
    record_id = data.get("record_id")
    items = data.get("items", [])

    if not record_id or not items:
        return jsonify({"error": "record_id and at least one item are required"}), 400

    conn = get_db_connection()
    cur = conn.cursor()
    try:
        # One prescription per medical record (record_id is UNIQUE)
        cur.execute("SELECT prescription_id FROM DIGITAL_PRESCRIPTION WHERE record_id = %s", (record_id,))
        row = cur.fetchone()
        if row:
            prescription_id = row[0]
            cur.execute(
                "UPDATE DIGITAL_PRESCRIPTION SET deleted_at = NULL WHERE prescription_id = %s",
                (prescription_id,),
            )
        else:
            prescription_id = str(uuid.uuid4())
            cur.execute(
                "INSERT INTO DIGITAL_PRESCRIPTION (prescription_id, record_id, valid_until, status) "
                "VALUES (%s, %s, DATE_ADD(CURDATE(), INTERVAL 30 DAY), 'Issued')",
                (prescription_id, record_id),
            )

        for it in items:
            # Snapshot the current medicine price into the item
            cur.execute("SELECT unit_price FROM MEDICINE WHERE medicine_id = %s", (it["medicine_id"],))
            price = cur.fetchone()
            if not price:
                raise ValueError("Medicine not found")
            cur.execute(
                "INSERT INTO PRESCRIPTION_ITEM "
                "(item_id, prescription_id, medicine_id, dosage, frequency, duration_days, "
                " quantity, unit_price_at_prescription) "
                "VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
                (str(uuid.uuid4()), prescription_id, it["medicine_id"], it["dosage"],
                 it["frequency"], it["duration_days"], it["quantity"], price[0]),
            )
        conn.commit()
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 400
    finally:
        cur.close()
        conn.close()
    return jsonify({"prescription_id": prescription_id, "message": "Prescription saved"})


@prescription_bp.route("/api/prescription-audit/<record_id>")
def get_audit(record_id):
    # Minimal audit log (written by triggers) of the prescription of a record
    conn = get_db_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute(
        """
        SELECT m.medicine_name, au.action, au.old_quantity, au.new_quantity,
               DATE_FORMAT(au.changed_at, '%Y-%m-%d %H:%i:%s') AS changed_at
        FROM PRESCRIPTION_AUDIT au
        JOIN DIGITAL_PRESCRIPTION dp ON dp.prescription_id = au.prescription_id
        JOIN MEDICINE m ON m.medicine_id = au.medicine_id
        WHERE dp.record_id = %s
        ORDER BY au.audit_id DESC
        """,
        (record_id,),
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(rows)
