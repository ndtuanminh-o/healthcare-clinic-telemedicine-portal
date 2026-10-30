import uuid
from flask import Blueprint, jsonify, request
from db import get_db_connection

prescription_bp = Blueprint("prescription", __name__)

@prescription_bp.route("/api/medicines")
def list_medicines():
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor(dictionary=True)
        cur.execute(
            """
            SELECT medicine_id, medicine_name, unit, unit_price, stock_quantity
            FROM MEDICINE
            ORDER BY medicine_name
            """
        )
        rows = cur.fetchall()
        return jsonify(rows)
    except Exception as e:
        return jsonify({"error": "Failed to load medicines."}), 500
    finally:
        if conn and conn.is_connected():
            cur.close()
            conn.close()

@prescription_bp.route("/api/prescriptions/<record_id>")
def get_prescription(record_id):
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor(dictionary=True)
        cur.execute(
            """
            SELECT m.medicine_name, pi.dosage, pi.frequency, pi.duration_days,
                   pi.quantity, pi.unit_price_at_prescription,
                   (pi.quantity * pi.unit_price_at_prescription) AS line_total
            FROM DIGITAL_PRESCRIPTION dp
            JOIN PRESCRIPTION_ITEM pi ON pi.prescription_id = dp.prescription_id
            JOIN MEDICINE m ON m.medicine_id = pi.medicine_id
            WHERE dp.record_id = %s AND dp.deleted_at IS NULL
            ORDER BY m.medicine_name
            """,
            (record_id,),
        )
        rows = cur.fetchall()
        return jsonify(rows)
    except Exception as e:
        return jsonify({"error": "Failed to load prescription."}), 500
    finally:
        if conn and conn.is_connected():
            cur.close()
            conn.close()

@prescription_bp.route("/api/prescriptions", methods=["POST"])
def create_prescription():
    data = request.get_json(silent=True) or {}
    record_id = data.get("record_id")
    items = data.get("items", [])

    if not record_id or not items:
        return jsonify({"error": "Record ID and at least one medicine item are required."}), 400

    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor(dictionary=True)

        # 1. Check or create prescription
        cur.execute("SELECT prescription_id, status FROM DIGITAL_PRESCRIPTION WHERE record_id = %s", (record_id,))
        row = cur.fetchone()
        if row:
            prescription_id = row["prescription_id"]
            if row["status"] == "Dispensed":
                return jsonify({"error": "Cannot modify dispensed prescription."}), 400
            cur.execute(
                "UPDATE DIGITAL_PRESCRIPTION SET deleted_at = NULL, status = 'Issued' WHERE prescription_id = %s",
                (prescription_id,),
            )
        else:
            prescription_id = str(uuid.uuid4())
            cur.execute(
                """
                INSERT INTO DIGITAL_PRESCRIPTION (prescription_id, record_id, valid_until, status)
                VALUES (%s, %s, DATE_ADD(CURDATE(), INTERVAL 30 DAY), 'Issued')
                """,
                (prescription_id, record_id),
            )

        total_med_cost = 0.0

        for it in items:
            medicine_id = it.get("medicine_id")
            dosage = (it.get("dosage") or "As directed").strip()
            frequency = (it.get("frequency") or "Twice daily").strip()
            duration_days = int(it.get("duration_days") or 5)
            quantity = int(it.get("quantity") or 1)

            if duration_days <= 0 or quantity <= 0:
                raise ValueError("Quantity and duration days must be greater than 0.")

            # Lock row for inventory check
            cur.execute(
                "SELECT unit_price, stock_quantity, medicine_name FROM MEDICINE WHERE medicine_id = %s FOR UPDATE",
                (medicine_id,)
            )
            med = cur.fetchone()
            if not med:
                raise ValueError(f"Medicine ID '{medicine_id}' not found.")

            if med["stock_quantity"] < quantity:
                raise ValueError(
                    f"Insufficient stock for {med['medicine_name']}: requested {quantity}, available {med['stock_quantity']}."
                )

            unit_price = float(med["unit_price"])
            total_med_cost += unit_price * quantity

            # Deduct inventory atomically (BR-09)
            cur.execute(
                "UPDATE MEDICINE SET stock_quantity = stock_quantity - %s WHERE medicine_id = %s",
                (quantity, medicine_id)
            )

            # Insert line item
            cur.execute(
                """
                INSERT INTO PRESCRIPTION_ITEM
                (item_id, prescription_id, medicine_id, dosage, frequency, duration_days, quantity, unit_price_at_prescription)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (str(uuid.uuid4()), prescription_id, medicine_id, dosage, frequency, duration_days, quantity, unit_price),
            )

        # Update consolidated invoice total amount (BR-11)
        cur.execute(
            """
            UPDATE INVOICE i
            JOIN APPOINTMENT a ON a.appointment_id = i.appointment_id
            JOIN MEDICAL_RECORD mr ON mr.appointment_id = a.appointment_id
            SET i.total_amount = i.total_amount + %s
            WHERE mr.record_id = %s
            """,
            (total_med_cost, record_id)
        )

        conn.commit()
        return jsonify({
            "prescription_id": prescription_id,
            "message": "Prescription issued and inventory updated successfully."
        }), 201

    except ValueError as ve:
        if conn:
            conn.rollback()
        return jsonify({"error": str(ve)}), 400
    except Exception as e:
        if conn:
            conn.rollback()
        return jsonify({"error": f"Failed to issue prescription: {str(e)}"}), 500
    finally:
        if conn and conn.is_connected():
            cur.close()
            conn.close()

@prescription_bp.route("/api/prescription-audit/<record_id>")
def get_audit(record_id):
    conn = None
    try:
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
            LIMIT 20
            """,
            (record_id,),
        )
        rows = cur.fetchall()
        return jsonify(rows)
    except Exception as e:
        return jsonify({"error": "Failed to load audit history."}), 500
    finally:
        if conn and conn.is_connected():
            cur.close()
            conn.close()
