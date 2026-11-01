import uuid

from flask import Blueprint, jsonify, request

from db import get_db_connection


prescription_bp = Blueprint("prescription", __name__)


@prescription_bp.route("/api/medicines")
def list_medicines():
    conn = None
    cur = None
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
        return jsonify(cur.fetchall())
    except Exception:
        return jsonify({"error": "Failed to load medicines."}), 500
    finally:
        if cur:
            cur.close()
        if conn and conn.is_connected():
            conn.close()


@prescription_bp.route("/api/prescriptions/<record_id>")
def get_prescription(record_id):
    conn = None
    cur = None
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
        return jsonify(cur.fetchall())
    except Exception:
        return jsonify({"error": "Failed to load prescription."}), 500
    finally:
        if cur:
            cur.close()
        if conn and conn.is_connected():
            conn.close()


@prescription_bp.route("/api/prescriptions", methods=["POST"])
def create_prescription():
    data = request.get_json(silent=True) or {}
    record_id = data.get("record_id")
    items = data.get("items", [])

    if not record_id or not items:
        return jsonify({
            "error": "Record ID and at least one medicine item are required."
        }), 400

    conn = None
    cur = None
    try:
        conn = get_db_connection()
        cur = conn.cursor(dictionary=True)

        # Keep the prescription Draft while line items are being inserted.
        # The database trigger correctly rejects changes to an Issued prescription.
        cur.execute(
            """
            SELECT prescription_id, status
            FROM DIGITAL_PRESCRIPTION
            WHERE record_id = %s
            FOR UPDATE
            """,
            (record_id,),
        )
        row = cur.fetchone()

        if row:
            prescription_id = row["prescription_id"]
            if row["status"] in ("Issued", "Dispensed"):
                return jsonify({
                    "error": "Cannot modify an issued or dispensed prescription."
                }), 400

            cur.execute(
                """
                UPDATE DIGITAL_PRESCRIPTION
                SET deleted_at = NULL, status = 'Draft'
                WHERE prescription_id = %s
                """,
                (prescription_id,),
            )
        else:
            prescription_id = str(uuid.uuid4())
            cur.execute(
                """
                INSERT INTO DIGITAL_PRESCRIPTION
                    (prescription_id, record_id, valid_until, status)
                VALUES
                    (%s, %s, DATE_ADD(CURDATE(), INTERVAL 30 DAY), 'Draft')
                """,
                (prescription_id, record_id),
            )

        total_med_cost = 0.0

        for item in items:
            medicine_id = item.get("medicine_id")
            dosage = (item.get("dosage") or "As directed").strip()
            frequency = (item.get("frequency") or "Twice daily").strip()
            duration_days = int(item.get("duration_days") or 5)
            quantity = int(item.get("quantity") or 1)

            if duration_days <= 0 or quantity <= 0:
                raise ValueError("Quantity and duration days must be greater than 0.")

            cur.execute(
                """
                SELECT unit_price, stock_quantity, medicine_name
                FROM MEDICINE
                WHERE medicine_id = %s
                FOR UPDATE
                """,
                (medicine_id,),
            )
            medicine = cur.fetchone()
            if not medicine:
                raise ValueError(f"Medicine ID '{medicine_id}' not found.")

            if medicine["stock_quantity"] < quantity:
                raise ValueError(
                    f"Insufficient stock for {medicine['medicine_name']}: "
                    f"requested {quantity}, available {medicine['stock_quantity']}."
                )

            unit_price = float(medicine["unit_price"])
            total_med_cost += unit_price * quantity

            # Deduct stock in the same transaction as the prescription insert.
            cur.execute(
                """
                UPDATE MEDICINE
                SET stock_quantity = stock_quantity - %s
                WHERE medicine_id = %s
                """,
                (quantity, medicine_id),
            )

            # AFTER INSERT audit trigger records this operation.
            cur.execute(
                """
                INSERT INTO PRESCRIPTION_ITEM
                    (item_id, prescription_id, medicine_id, dosage, frequency,
                     duration_days, quantity, unit_price_at_prescription)
                VALUES
                    (%s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    str(uuid.uuid4()),
                    prescription_id,
                    medicine_id,
                    dosage,
                    frequency,
                    duration_days,
                    quantity,
                    unit_price,
                ),
            )

        # Only issue the prescription after all items have been inserted.
        cur.execute(
            """
            UPDATE DIGITAL_PRESCRIPTION
            SET status = 'Issued'
            WHERE prescription_id = %s
            """,
            (prescription_id,),
        )

        # Add medicine cost to the consolidated invoice.
        cur.execute(
            """
            UPDATE INVOICE i
            JOIN APPOINTMENT a ON a.appointment_id = i.appointment_id
            JOIN MEDICAL_RECORD mr ON mr.appointment_id = a.appointment_id
            SET i.total_amount = i.total_amount + %s
            WHERE mr.record_id = %s
            """,
            (total_med_cost, record_id),
        )

        conn.commit()
        return jsonify({
            "prescription_id": prescription_id,
            "message": "Prescription issued and inventory updated successfully.",
        }), 201

    except ValueError as error:
        if conn:
            conn.rollback()
        return jsonify({"error": str(error)}), 400
    except Exception as error:
        if conn:
            conn.rollback()
        return jsonify({"error": f"Failed to issue prescription: {error}"}), 500
    finally:
        if cur:
            cur.close()
        if conn and conn.is_connected():
            conn.close()


@prescription_bp.route("/api/prescription-audit/<record_id>")
def get_audit(record_id):
    conn = None
    cur = None
    try:
        conn = get_db_connection()
        cur = conn.cursor(dictionary=True)
        cur.execute(
            """
            SELECT m.medicine_name, au.action, au.old_quantity, au.new_quantity,
                   DATE_FORMAT(au.changed_at, '%Y-%m-%d %H:%i:%s') AS changed_at
            FROM PRESCRIPTION_AUDIT au
            JOIN DIGITAL_PRESCRIPTION dp
                ON dp.prescription_id = au.prescription_id
            JOIN MEDICINE m ON m.medicine_id = au.medicine_id
            WHERE dp.record_id = %s
            ORDER BY au.audit_id DESC
            LIMIT 20
            """,
            (record_id,),
        )
        return jsonify(cur.fetchall())
    except Exception:
        return jsonify({"error": "Failed to load audit history."}), 500
    finally:
        if cur:
            cur.close()
        if conn and conn.is_connected():
            conn.close()
