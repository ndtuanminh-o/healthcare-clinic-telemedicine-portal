CREATE DATABASE IF NOT EXISTS healthcare_clinic_v2
    DEFAULT CHARACTER SET utf8mb4;
USE healthcare_clinic_v2;

SET FOREIGN_KEY_CHECKS = 0;

DROP VIEW IF EXISTS v_low_stock_medicines;
DROP VIEW IF EXISTS v_appointment_billing_summary;
DROP VIEW IF EXISTS v_doctor_daily_roster;
DROP VIEW IF EXISTS v_doctor_available_slot;
DROP VIEW IF EXISTS v_doctor_integrity_violations;

DROP TABLE IF EXISTS audit_log;
DROP TABLE IF EXISTS payment;
DROP TABLE IF EXISTS invoice;
DROP TABLE IF EXISTS prescription_item;
DROP TABLE IF EXISTS medicine;
DROP TABLE IF EXISTS digital_prescription;
DROP TABLE IF EXISTS medical_record;
DROP TABLE IF EXISTS appointment;
DROP TABLE IF EXISTS patient;
DROP TABLE IF EXISTS doctor_schedule;
DROP TABLE IF EXISTS specialist;
DROP TABLE IF EXISTS general_practitioner;
DROP TABLE IF EXISTS doctor;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE doctor (
    doctor_id       CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    full_name       VARCHAR(100) NOT NULL,
    license_no      VARCHAR(30) NOT NULL UNIQUE,
    phone_number    VARCHAR(15) NOT NULL,
    email           VARCHAR(100) NULL,
    doctor_type     ENUM('GP', 'Specialist') NOT NULL,
    status          ENUM('Active', 'Inactive') NOT NULL DEFAULT 'Active',
    deleted_at      DATETIME NULL,
    UNIQUE KEY uq_doctor_id_type (doctor_id, doctor_type)
);

CREATE TABLE general_practitioner (
    doctor_id           CHAR(36) PRIMARY KEY,
    doctor_type         ENUM('GP', 'Specialist') NOT NULL DEFAULT 'GP',
    clinic_room_no      VARCHAR(20) NOT NULL,
    consultation_fee    DECIMAL(12, 2) NOT NULL DEFAULT 150000.00,
    CONSTRAINT fk_gp_doctor FOREIGN KEY (doctor_id, doctor_type)
        REFERENCES doctor (doctor_id, doctor_type),
    CONSTRAINT chk_gp_type CHECK (doctor_type = 'GP'),
    CONSTRAINT chk_gp_fee CHECK (consultation_fee > 0)
);

CREATE TABLE specialist (
    doctor_id               CHAR(36) PRIMARY KEY,
    doctor_type             ENUM('GP', 'Specialist') NOT NULL DEFAULT 'Specialist',
    specialty               VARCHAR(50) NOT NULL,
    consultation_fee        DECIMAL(12, 2) NOT NULL DEFAULT 300000.00,
    board_certified_year    INT NOT NULL,
    CONSTRAINT fk_specialist_doctor FOREIGN KEY (doctor_id, doctor_type)
        REFERENCES doctor (doctor_id, doctor_type),
    CONSTRAINT chk_sp_type CHECK (doctor_type = 'Specialist'),
    CONSTRAINT chk_specialist_fee CHECK (consultation_fee > 0),
    -- The upper bound (not in the future) is enforced by trg_specialist_bi/bu
    CONSTRAINT chk_specialist_year CHECK (board_certified_year >= 1900)
);

CREATE TABLE doctor_schedule (
    schedule_id     CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    doctor_id       CHAR(36) NOT NULL,
    work_date       DATE NOT NULL,
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    slot_status     ENUM('Available', 'Booked', 'Blocked') NOT NULL DEFAULT 'Available',
    CONSTRAINT fk_schedule_doctor FOREIGN KEY (doctor_id)
        REFERENCES doctor (doctor_id) ON DELETE CASCADE,
    CONSTRAINT chk_schedule_time CHECK (end_time > start_time),
    -- natural key: the same doctor cannot have two shifts starting at the same time
    CONSTRAINT uq_schedule_doctor_slot UNIQUE (doctor_id, work_date, start_time)
);

CREATE TABLE patient (
    patient_id      CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    full_name       VARCHAR(100) NOT NULL,
    date_of_birth   DATE NOT NULL,
    gender          ENUM('M', 'F', 'O') DEFAULT 'O',
    phone_number    VARCHAR(15) NOT NULL UNIQUE,
    address         VARCHAR(255) NULL,
    status          ENUM('Active', 'Inactive') NOT NULL DEFAULT 'Active',
    deleted_at      DATETIME NULL,
    -- The upper bound (not in the future) is enforced by trg_patient_bi/bu
    CONSTRAINT chk_patient_dob CHECK (date_of_birth >= '1900-01-01')
);

CREATE TABLE appointment (
    appointment_id          CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    patient_id              CHAR(36) NOT NULL,
    doctor_id               CHAR(36) NOT NULL,
    booking_time            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    appointment_date        DATE NOT NULL,
    start_time              TIME NOT NULL,
    end_time                TIME NOT NULL,
    consultation_type       ENUM('In-Person', 'Telemedicine') NOT NULL DEFAULT 'In-Person',
    telemedicine_video_link TEXT NULL,
    status                  ENUM('Scheduled', 'In-Progress', 'Completed', 'Cancelled') NOT NULL DEFAULT 'Scheduled',
    reason_for_visit        TEXT NULL,
    deleted_at              DATETIME NULL,
    CONSTRAINT fk_appointment_patient FOREIGN KEY (patient_id)
        REFERENCES patient (patient_id) ON DELETE RESTRICT,
    CONSTRAINT fk_appointment_doctor FOREIGN KEY (doctor_id)
        REFERENCES doctor (doctor_id) ON DELETE RESTRICT,
    CONSTRAINT chk_appointment_time CHECK (end_time > start_time),
    CONSTRAINT chk_appointment_video_link CHECK (
        consultation_type = 'Telemedicine' OR telemedicine_video_link IS NULL
    ),
    -- target of the composite FKs of medical_record and invoice
    CONSTRAINT uq_appointment_id_patient UNIQUE (appointment_id, patient_id)
);

CREATE TABLE medical_record (
    record_id       CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    appointment_id  CHAR(36) NOT NULL UNIQUE,
    patient_id      CHAR(36) NOT NULL,
    specialist_id   CHAR(36) NULL,
    diagnosis       TEXT NOT NULL,
    clinical_notes  TEXT NULL,
    treatment_plan  TEXT NULL,
    record_date     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at      DATETIME NULL,
    -- record.patient_id must equal the patient of its appointment
    CONSTRAINT fk_record_appt_patient FOREIGN KEY (appointment_id, patient_id)
        REFERENCES appointment (appointment_id, patient_id) ON DELETE RESTRICT,
    CONSTRAINT fk_record_specialist FOREIGN KEY (specialist_id)
        REFERENCES specialist (doctor_id) ON DELETE SET NULL
);

CREATE TABLE digital_prescription (
    prescription_id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    record_id       CHAR(36) NOT NULL UNIQUE,
    issue_date      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_until     DATE NOT NULL,
    instructions    TEXT NULL,
    status          ENUM('Draft', 'Issued', 'Dispensed', 'Cancelled') NOT NULL DEFAULT 'Draft',
    deleted_at      DATETIME NULL,
    CONSTRAINT fk_prescription_record FOREIGN KEY (record_id)
        REFERENCES medical_record (record_id) ON DELETE RESTRICT,
    CONSTRAINT chk_prescription_validity CHECK (valid_until >= DATE(issue_date))
);

CREATE TABLE medicine (
    medicine_id         CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    medicine_name       VARCHAR(100) NOT NULL UNIQUE,
    active_ingredient   VARCHAR(100) NULL,
    unit                VARCHAR(20) NOT NULL DEFAULT 'Viên',
    unit_price          DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    stock_quantity      INT NOT NULL DEFAULT 0,
    reorder_level       INT NOT NULL DEFAULT 10,
    expiry_date         DATE NULL,   -- BR-09: expired medicine cannot be prescribed
    CONSTRAINT chk_medicine_price CHECK (unit_price >= 0),
    CONSTRAINT chk_medicine_stock CHECK (stock_quantity >= 0),
    CONSTRAINT chk_medicine_reorder CHECK (reorder_level >= 0)
);

CREATE TABLE prescription_item (
    item_id                     CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    prescription_id             CHAR(36) NOT NULL,
    medicine_id                 CHAR(36) NOT NULL,
    dosage                      VARCHAR(50) NOT NULL,
    frequency                   VARCHAR(50) NOT NULL,
    duration_days               INT NOT NULL,
    quantity                    INT NOT NULL,
    unit_price_at_prescription  DECIMAL(12, 2) NOT NULL,
    CONSTRAINT fk_item_prescription FOREIGN KEY (prescription_id)
        REFERENCES digital_prescription (prescription_id) ON DELETE CASCADE,
    CONSTRAINT fk_item_medicine FOREIGN KEY (medicine_id)
        REFERENCES medicine (medicine_id) ON DELETE RESTRICT,
    CONSTRAINT chk_item_duration CHECK (duration_days > 0),
    CONSTRAINT chk_item_quantity CHECK (quantity > 0),
    CONSTRAINT chk_item_price CHECK (unit_price_at_prescription >= 0),
    -- candidate key declared in normalization_verification.md
    CONSTRAINT uq_item_prescription_medicine UNIQUE (prescription_id, medicine_id)
);

CREATE TABLE invoice (
    invoice_id      CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    appointment_id  CHAR(36) NOT NULL UNIQUE,
    patient_id      CHAR(36) NOT NULL,
    issue_date      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount    DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    payment_status  ENUM('Unpaid', 'Paid', 'Refunded') NOT NULL DEFAULT 'Unpaid',
    payment_method  ENUM('Cash', 'Credit Card', 'Insurance', 'Bank Transfer') NOT NULL DEFAULT 'Cash',
    CONSTRAINT fk_invoice_appt_patient FOREIGN KEY (appointment_id, patient_id)
        REFERENCES appointment (appointment_id, patient_id) ON DELETE RESTRICT,
    CONSTRAINT chk_invoice_total CHECK (total_amount >= 0)
);

-- BR-12: payment transactions; their sum may never exceed invoice.total_amount
CREATE TABLE payment (
    payment_id      CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    invoice_id      CHAR(36) NOT NULL,
    amount          DECIMAL(12, 2) NOT NULL,
    payment_method  ENUM('Cash', 'Credit Card', 'Insurance', 'Bank Transfer') NOT NULL DEFAULT 'Cash',
    paid_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_payment_invoice FOREIGN KEY (invoice_id)
        REFERENCES invoice (invoice_id) ON DELETE RESTRICT,
    CONSTRAINT chk_payment_amount CHECK (amount > 0)
);

-- Audit trail for clinical and financial data (ids and status only, no PHI text)
CREATE TABLE audit_log (
    audit_id        BIGINT AUTO_INCREMENT PRIMARY KEY,
    table_name      VARCHAR(40) NOT NULL,
    row_id          CHAR(36) NOT NULL,
    action          ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    changed_by      VARCHAR(100) NOT NULL,
    changed_at      DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    details         JSON NULL
);

CREATE INDEX idx_appointment_doctor_date
    ON appointment (doctor_id, appointment_date, start_time);
CREATE INDEX idx_appointment_patient
    ON appointment (patient_id, appointment_date);
CREATE INDEX idx_medical_record_patient
    ON medical_record (patient_id, record_date);
CREATE INDEX idx_pres_item_medicine
    ON prescription_item (medicine_id);
CREATE INDEX idx_medicine_stock_alert
    ON medicine (stock_quantity, reorder_level);
CREATE INDEX idx_invoice_status_date
    ON invoice (payment_status, issue_date);
CREATE INDEX idx_payment_invoice
    ON payment (invoice_id);
CREATE INDEX idx_audit_lookup
    ON audit_log (table_name, row_id, changed_at);

-- Added for the reporting queries (measured in the audit report, section 3.2).
-- deleted_at is the last column so the soft-delete filter stays index-only.
CREATE INDEX idx_appt_date_doctor_status_type
    ON appointment (appointment_date, doctor_id, status, consultation_type, deleted_at);
CREATE INDEX idx_appt_patient_status_type_date
    ON appointment (patient_id, status, consultation_type, appointment_date, deleted_at);
CREATE INDEX idx_appt_status_patient_doctor_date
    ON appointment (status, patient_id, doctor_id, appointment_date, consultation_type, deleted_at);
CREATE INDEX idx_appt_doctor_status
    ON appointment (doctor_id, status, deleted_at);
CREATE INDEX idx_presc_issue_status
    ON digital_prescription (issue_date, status, deleted_at);
CREATE INDEX idx_item_presc_med_qty
    ON prescription_item (prescription_id, medicine_id, quantity);
CREATE INDEX idx_invoice_status_patient_total
    ON invoice (payment_status, patient_id, total_amount);


CREATE OR REPLACE VIEW v_doctor_daily_roster AS
SELECT
    ds.schedule_id,
    d.doctor_id,
    d.full_name AS doctor_name,
    d.doctor_type,
    COALESCE(gp.clinic_room_no, 'Phòng Telemedicine') AS location,
    COALESCE(sp.specialty, 'Đa khoa (General Practice)') AS clinical_domain,
    ds.work_date,
    ds.start_time,
    ds.end_time,
    ds.slot_status
FROM doctor_schedule ds
JOIN doctor d ON ds.doctor_id = d.doctor_id
LEFT JOIN general_practitioner gp ON d.doctor_id = gp.doctor_id
LEFT JOIN specialist sp ON d.doctor_id = sp.doctor_id
WHERE d.status = 'Active'
  AND d.deleted_at IS NULL;

-- Phone number is masked (least privilege for the billing role)
CREATE OR REPLACE VIEW v_appointment_billing_summary AS
SELECT
    i.invoice_id,
    a.appointment_id,
    p.full_name AS patient_name,
    CONCAT(REPEAT('*', GREATEST(CHAR_LENGTH(p.phone_number) - 3, 0)),
           RIGHT(p.phone_number, 3)) AS patient_phone_masked,
    d.full_name AS doctor_name,
    a.consultation_type,
    a.appointment_date,
    i.total_amount,
    i.payment_status,
    i.payment_method,
    i.issue_date
FROM invoice i
JOIN appointment a ON i.appointment_id = a.appointment_id
JOIN patient p ON i.patient_id = p.patient_id
JOIN doctor d ON a.doctor_id = d.doctor_id;

CREATE OR REPLACE VIEW v_low_stock_medicines AS
SELECT
    medicine_id,
    medicine_name,
    active_ingredient,
    unit,
    stock_quantity,
    reorder_level,
    (reorder_level - stock_quantity) AS units_needed,
    unit_price
FROM medicine
WHERE stock_quantity <= reorder_level
ORDER BY stock_quantity ASC;

CREATE OR REPLACE VIEW v_doctor_integrity_violations AS
SELECT d.doctor_id, d.doctor_type, 'no subclass row' AS problem
FROM doctor d
WHERE NOT EXISTS (SELECT 1 FROM general_practitioner g WHERE g.doctor_id = d.doctor_id)
  AND NOT EXISTS (SELECT 1 FROM specialist s WHERE s.doctor_id = d.doctor_id)
UNION ALL
SELECT d.doctor_id, d.doctor_type, 'both subclass rows'
FROM doctor d
WHERE EXISTS (SELECT 1 FROM general_practitioner g WHERE g.doctor_id = d.doctor_id)
  AND EXISTS (SELECT 1 FROM specialist s WHERE s.doctor_id = d.doctor_id);
