import os
import sys
import mysql.connector

def run_sql_file(cursor, filepath):
    print(f"Executing: {os.path.basename(filepath)}...")
    with open(filepath, 'r', encoding='utf-8') as f:
        sql = f.read()
    
    # Split on semicolon or statements
    statements = sql.split(';')
    for statement in statements:
        stmt = statement.strip()
        if stmt:
            cursor.execute(stmt)

def main():
    password = sys.argv[1] if len(sys.argv) > 1 else ""
    user = sys.argv[2] if len(sys.argv) > 2 else "root"
    host = sys.argv[3] if len(sys.argv) > 3 else "localhost"
    port = int(sys.argv[4]) if len(sys.argv) > 4 else 3306

    print(f"Connecting to MySQL at {host}:{port} as {user}...")
    conn = mysql.connector.connect(
        host=host,
        user=user,
        password=password,
        port=port
    )
    cursor = conn.cursor()

    db_name = "healthcare_portal"
    print(f"Creating database `{db_name}` if not exists...")
    cursor.execute(f"CREATE DATABASE IF NOT EXISTS {db_name} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;")
    cursor.execute(f"USE {db_name};")

    base_dir = os.path.dirname(os.path.abspath(__file__))
    schema_path = os.path.join(base_dir, "phase 3", "01_schema.sql")
    run_sql_file(cursor, schema_path)

    mock_dir = os.path.join(base_dir, "phase 3", "02_mock_data")
    mock_files = [
        "DOCTOR.sql",
        "GENERAL_PRACTITIONER.sql",
        "SPECIALIST.sql",
        "DOCTOR_SCHEDULE.sql",
        "PATIENT.sql",
        "APPOINTMENT.sql",
        "MEDICAL_RECORD.sql",
        "MEDICINE.sql",
        "DIGITAL_PRESCRIPTION.sql",
        "PRESCRIPTION_ITEM.sql",
        "INVOICE.sql"
    ]

    cursor.execute("SET FOREIGN_KEY_CHECKS = 0;")
    for mf in mock_files:
        fpath = os.path.join(mock_dir, mf)
        if os.path.exists(fpath):
            run_sql_file(cursor, fpath)
            conn.commit()
    cursor.execute("SET FOREIGN_KEY_CHECKS = 1;")

    # Prescription audit table
    audit_sql = os.path.join(base_dir, "phase 4", "database", "prescription_audit.sql")
    if os.path.exists(audit_sql):
        run_sql_file(cursor, audit_sql)

    conn.commit()
    cursor.close()
    conn.close()
    print("Database loaded successfully!")

if __name__ == "__main__":
    main()
