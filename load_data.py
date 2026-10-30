import os
import sys
import subprocess
import shutil

def find_mysql_binary():
    cmd = shutil.which("mysql")
    if cmd:
        return cmd

    candidates = [
        r"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe",
        r"C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe",
        r"C:\Program Files (x86)\MySQL\MySQL Server 8.0\bin\mysql.exe",
        r"C:\xampp\mysql\bin\mysql.exe",
        r"C:\laragon\bin\mysql\mysql-8.0.30-winx64\bin\mysql.exe"
    ]
    for p in candidates:
        if os.path.exists(p):
            return p
    return "mysql"

def run_mysql_command(mysql_bin, user, password, host, port, db_name, sql):
    cmd = [
        mysql_bin,
        f"-u{user}",
        f"-p{password}",
        f"-h{host}",
        f"-P{port}",
        "--default-character-set=utf8mb4",
    ]
    if db_name:
        cmd.append(db_name)
    cmd.extend(["-e", sql])
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error executing SQL: {result.stderr.strip()}", file=sys.stderr)
        return False
    return True

def main():
    password = sys.argv[1] if len(sys.argv) > 1 else os.getenv("DB_PASSWORD", "")
    user = sys.argv[2] if len(sys.argv) > 2 else os.getenv("DB_USER", "root")
    host = sys.argv[3] if len(sys.argv) > 3 else os.getenv("DB_HOST", "localhost")
    port = sys.argv[4] if len(sys.argv) > 4 else os.getenv("DB_PORT", "3306")
    db_name = sys.argv[5] if len(sys.argv) > 5 else "healthcare_clinic_v2"

    mysql_bin = find_mysql_binary()
    print(f"Using MySQL client: {mysql_bin}")
    print(f"Connecting to MySQL at {host}:{port} as {user}...")

    # 1. Create target database
    print(f"Creating database `{db_name}`...")
    create_sql = f"CREATE DATABASE IF NOT EXISTS {db_name} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    if not run_mysql_command(mysql_bin, user, password, host, port, None, create_sql):
        sys.exit(1)

    base_dir = os.path.dirname(os.path.abspath(__file__))

    # 2. Run Phase 3 Schema
    schema_path = os.path.join(base_dir, "phase 3", "01_schema.sql").replace("\\", "/")
    print(f"Importing schema: {schema_path}...")
    run_mysql_command(mysql_bin, user, password, host, port, db_name, f"source {schema_path};")

    # 3. Run Mock Data in FK dependency order
    mock_dir = os.path.join(base_dir, "phase 3", "03_mock_data")
    if not os.path.exists(mock_dir):
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

    for mf in mock_files:
        fpath = os.path.join(mock_dir, mf).replace("\\", "/")
        print(f"Importing mock data: {mf}...")
        run_mysql_command(mysql_bin, user, password, host, port, db_name, f"source {fpath};")

    # 4. Run Triggers & Views
    trg_path = os.path.join(base_dir, "phase 3", "02_trigger_and_view.sql").replace("\\", "/")
    if not os.path.exists(trg_path):
        trg_path = os.path.join(base_dir, "phase 3", "02_trigger_and _view.sql").replace("\\", "/")
    if os.path.exists(trg_path):
        print(f"Importing Phase 3 triggers & views: {os.path.basename(trg_path)}...")
        run_mysql_command(mysql_bin, user, password, host, port, db_name, f"source {trg_path};")

    # 5. Run Phase 4 Audit tables and triggers
    audit_table = os.path.join(base_dir, "phase 4", "database", "prescription_audit.sql").replace("\\", "/")
    audit_trg = os.path.join(base_dir, "phase 4", "database", "prescription_audit_triggers.sql").replace("\\", "/")
    if os.path.exists(audit_table):
        print("Importing Phase 4 audit schema...")
        run_mysql_command(mysql_bin, user, password, host, port, db_name, f"source {audit_table};")
    if os.path.exists(audit_trg):
        print("Importing Phase 4 audit triggers...")
        run_mysql_command(mysql_bin, user, password, host, port, db_name, f"source {audit_trg};")

    print(f"\nSuccessfully populated database `{db_name}` with full schema, mock data, and triggers!")

if __name__ == "__main__":
    main()
