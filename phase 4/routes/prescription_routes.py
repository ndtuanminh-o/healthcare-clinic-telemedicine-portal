# Prescription routes for the doctor screen 
from flask import Blueprint, jsonify, request
from db import get_db_connection  

prescription_bp = Blueprint("prescription", __name__)


@prescription_bp.route("/api/medicines")
def list_medicines():
    conn = get_db_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute("SELECT medicine_id, medicine_name, unit_price FROM MEDICINE ORDER BY medicine_name")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(rows)


@prescription_bp.route("/api/prescriptions/<int:record_id>")
def get_prescription(record_id):
    # Prescription items of a medical record
    conn = get_db_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute(
        """
        SELECT dp.prescription_id, m.medicine_name, pi.dosage, pi.quantity,
               pi.unit_price_at_prescription
        FROM DIGITAL_PRESCRIPTION dp
        JOIN PRESCRIPTION_ITEM pi ON pi.prescription_id = dp.prescription_id
        JOIN MEDICINE m ON m.medicine_id = pi.medicine_id
        WHERE dp.record_id = %s
        """,
        (record_id,),
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(rows)


@prescription_bp.route("/api/prescriptions", methods=["POST"])
def create_prescription():
    # Body: {record_id, items: [{medicine_id, dosage, quantity}]}
    data = request.get_json()
    record_id = data.get("record_id")
    items = data.get("items", [])

    if not record_id or not items:
        return jsonify({"error": "record_id and at least one item are required"}), 400

    conn = get_db_connection()
    cur = conn.cursor()
    try:
        # Reuse the prescription of this record if it already exists
        cur.execute("SELECT prescription_id FROM DIGITAL_PRESCRIPTION WHERE record_id = %s", (record_id,))
        row = cur.fetchone()
        if row:
            prescription_id = row[0]
        else:
            cur.execute("INSERT INTO DIGITAL_PRESCRIPTION (record_id) VALUES (%s)", (record_id,))
            prescription_id = cur.lastrowid

        for it in items:
            # Snapshot the current medicine price into the item
            cur.execute("SELECT unit_price FROM MEDICINE WHERE medicine_id = %s", (it["medicine_id"],))
            price = cur.fetchone()
            if not price:
                raise ValueError("Medicine %s not found" % it["medicine_id"])
            cur.execute(
                """
                INSERT INTO PRESCRIPTION_ITEM
                    (prescription_id, medicine_id, dosage, quantity, unit_price_at_prescription)
                VALUES (%s, %s, %s, %s, %s)
                """,
                (prescription_id, it["medicine_id"], it.get("dosage", ""), it["quantity"], price[0]),
            )
        conn.commit()
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 400
    finally:
        cur.close()
        conn.close()
    return jsonify({"prescription_id": prescription_id, "message": "Prescription saved"})


@prescription_bp.route("/api/prescription-audit/<int:prescription_id>")
def get_audit(prescription_id):
    # Minimal audit log written by triggers
    conn = get_db_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute(
        "SELECT * FROM PRESCRIPTION_AUDIT WHERE prescription_id = %s ORDER BY changed_at DESC",
        (prescription_id,),
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(rows)
