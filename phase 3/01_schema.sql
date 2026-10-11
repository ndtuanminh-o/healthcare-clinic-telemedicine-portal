-- ============================================================================
-- TOPIC 05: HEALTHCARE CLINIC & TELEMEDICINE PORTAL | PTIT
-- INT1313 - DATABASE SYSTEMS | TEAM: G5 (PINGO)
-- SCRIPT: 01_schema.sql (CORE DDL, CONSTRAINTS, INDEXES & VIEWS)
-- AUTHOR: Nguyen Dang Tuan Minh (@ndtuanminh-o)
-- SPECIFICATION: Compliant with ISO/IEC 11179 Data Dictionary & 3NF Schema
-- TARGET RDBMS: PostgreSQL 14+ / ANSI SQL Compliant
-- ============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Clean teardown (Reverse dependency order)
DROP VIEW IF EXISTS v_low_stock_medicines CASCADE;
DROP VIEW IF EXISTS v_appointment_billing_summary CASCADE;
DROP VIEW IF EXISTS v_doctor_daily_roster CASCADE;

DROP TABLE IF EXISTS INVOICE CASCADE;
DROP TABLE IF EXISTS PRESCRIPTION_ITEM CASCADE;
DROP TABLE IF EXISTS MEDICINE CASCADE;
DROP TABLE IF EXISTS DIGITAL_PRESCRIPTION CASCADE;
DROP TABLE IF EXISTS MEDICAL_RECORD CASCADE;
DROP TABLE IF EXISTS APPOINTMENT CASCADE;
DROP TABLE IF EXISTS PATIENT CASCADE;
DROP TABLE IF EXISTS DOCTOR_SCHEDULE CASCADE;
DROP TABLE IF EXISTS SPECIALIST CASCADE;
DROP TABLE IF EXISTS GENERAL_PRACTITIONER CASCADE;
DROP TABLE IF EXISTS DOCTOR CASCADE;

-- ============================================================================
-- 1. CORE RELATIONAL TABLES & INTEGRITY CONSTRAINTS
-- ============================================================================

-- 1.1 DOCTOR (Superclass)
CREATE TABLE DOCTOR (
    doctor_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name       VARCHAR(100) NOT NULL,
    license_no      VARCHAR(30) NOT NULL UNIQUE,
    phone_number    VARCHAR(15) NOT NULL,
    email           VARCHAR(100),
    doctor_type     VARCHAR(20) NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'Active',
    deleted_at      TIMESTAMP,
    CONSTRAINT chk_doctor_type CHECK (doctor_type IN ('GP', 'Specialist')),
    CONSTRAINT chk_doctor_status CHECK (status IN ('Active', 'Inactive'))
);

-- 1.2 GENERAL_PRACTITIONER (Subclass - Option 8.4a)
CREATE TABLE GENERAL_PRACTITIONER (
    doctor_id           UUID PRIMARY KEY,
    clinic_room_no      VARCHAR(20) NOT NULL,
    consultation_fee    DECIMAL(10, 2) NOT NULL DEFAULT 150000.00,
    CONSTRAINT fk_gp_doctor FOREIGN KEY (doctor_id) 
        REFERENCES DOCTOR(doctor_id) ON DELETE RESTRICT,
    CONSTRAINT chk_gp_fee CHECK (consultation_fee > 0)
);

-- 1.3 SPECIALIST (Subclass - Option 8.4a)
CREATE TABLE SPECIALIST (
    doctor_id               UUID PRIMARY KEY,
    specialty               VARCHAR(50) NOT NULL,
    consultation_fee        DECIMAL(10, 2) NOT NULL DEFAULT 300000.00,
    board_certified_year    INT NOT NULL,
    CONSTRAINT fk_specialist_doctor FOREIGN KEY (doctor_id) 
        REFERENCES DOCTOR(doctor_id) ON DELETE RESTRICT,
    CONSTRAINT chk_specialist_fee CHECK (consultation_fee > 0),
    CONSTRAINT chk_specialist_year CHECK (board_certified_year <= EXTRACT(YEAR FROM CURRENT_DATE))
);

-- 1.4 DOCTOR_SCHEDULE (Duty shifts & On-call slots)
CREATE TABLE DOCTOR_SCHEDULE (
    schedule_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doctor_id       UUID NOT NULL,
    work_date       DATE NOT NULL,
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    slot_status     VARCHAR(20) NOT NULL DEFAULT 'Available',
    CONSTRAINT fk_schedule_doctor FOREIGN KEY (doctor_id) 
        REFERENCES DOCTOR(doctor_id) ON DELETE CASCADE,
    CONSTRAINT chk_schedule_time CHECK (end_time > start_time),
    CONSTRAINT chk_schedule_status CHECK (slot_status IN ('Available', 'Booked', 'Blocked'))
);

-- 1.5 PATIENT (Demographics & Profiles)
CREATE TABLE PATIENT (
    patient_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name       VARCHAR(100) NOT NULL,
    date_of_birth   DATE NOT NULL,
    gender          CHAR(1) DEFAULT 'O',
    phone_number    VARCHAR(15) NOT NULL UNIQUE,
    address         VARCHAR(255),
    status          VARCHAR(20) NOT NULL DEFAULT 'Active',
    deleted_at      TIMESTAMP,
    CONSTRAINT chk_patient_dob CHECK (date_of_birth <= CURRENT_DATE),
    CONSTRAINT chk_patient_gender CHECK (gender IN ('M', 'F', 'O')),
    CONSTRAINT chk_patient_status CHECK (status IN ('Active', 'Inactive'))
);

-- 1.6 APPOINTMENT (Consultation Coordination & Telemedicine)
CREATE TABLE APPOINTMENT (
    appointment_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id              UUID NOT NULL,
    doctor_id               UUID NOT NULL,
    booking_time            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    appointment_date        DATE NOT NULL,
    start_time              TIME NOT NULL,
    end_time                TIME NOT NULL,
    consultation_type       VARCHAR(20) NOT NULL DEFAULT 'In-Person',
    telemedicine_video_link TEXT,
    status                  VARCHAR(20) NOT NULL DEFAULT 'Scheduled',
    reason_for_visit        TEXT,
    deleted_at              TIMESTAMP,
    CONSTRAINT fk_appointment_patient FOREIGN KEY (patient_id) 
        REFERENCES PATIENT(patient_id) ON DELETE RESTRICT,
    CONSTRAINT fk_appointment_doctor FOREIGN KEY (doctor_id) 
        REFERENCES DOCTOR(doctor_id) ON DELETE RESTRICT,
    CONSTRAINT chk_appointment_time CHECK (end_time > start_time),
    CONSTRAINT chk_appointment_type CHECK (consultation_type IN ('In-Person', 'Telemedicine')),
    CONSTRAINT chk_appointment_status CHECK (status IN ('Scheduled', 'In-Progress', 'Completed', 'Cancelled'))
);

-- 1.7 MEDICAL_RECORD (Clinical Diagnosis & Examination Ledger)
CREATE TABLE MEDICAL_RECORD (
    record_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id  UUID NOT NULL UNIQUE,
    patient_id      UUID NOT NULL,
    specialist_id   UUID,
    diagnosis       TEXT NOT NULL,
    clinical_notes  TEXT,
    treatment_plan  TEXT,
    record_date     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at      TIMESTAMP,
    CONSTRAINT fk_record_appointment FOREIGN KEY (appointment_id) 
        REFERENCES APPOINTMENT(appointment_id) ON DELETE RESTRICT,
    CONSTRAINT fk_record_patient FOREIGN KEY (patient_id) 
        REFERENCES PATIENT(patient_id) ON DELETE RESTRICT,
    CONSTRAINT fk_record_specialist FOREIGN KEY (specialist_id) 
        REFERENCES SPECIALIST(doctor_id) ON DELETE SET NULL
);

-- 1.8 DIGITAL_PRESCRIPTION (Prescription Orders)
CREATE TABLE DIGITAL_PRESCRIPTION (
    prescription_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    record_id       UUID NOT NULL UNIQUE,
    issue_date      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_until     DATE NOT NULL,
    instructions    TEXT,
    status          VARCHAR(20) NOT NULL DEFAULT 'Draft',
    deleted_at      TIMESTAMP,
    CONSTRAINT fk_prescription_record FOREIGN KEY (record_id) 
        REFERENCES MEDICAL_RECORD(record_id) ON DELETE RESTRICT,
    CONSTRAINT chk_prescription_validity CHECK (valid_until >= issue_date::DATE),
    CONSTRAINT chk_prescription_status CHECK (status IN ('Draft', 'Issued', 'Dispensed', 'Cancelled'))
);

-- 1.9 MEDICINE (Dispensary Catalog & Stock Metrics)
CREATE TABLE MEDICINE (
    medicine_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    medicine_name       VARCHAR(100) NOT NULL UNIQUE,
    active_ingredient   VARCHAR(100),
    unit                VARCHAR(20) NOT NULL DEFAULT 'Viên',
    unit_price          DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    stock_quantity      INT NOT NULL DEFAULT 0,
    reorder_level       INT NOT NULL DEFAULT 10,
    CONSTRAINT chk_medicine_price CHECK (unit_price >= 0),
    CONSTRAINT chk_medicine_stock CHECK (stock_quantity >= 0),
    CONSTRAINT chk_medicine_reorder CHECK (reorder_level >= 0)
);

-- 1.10 PRESCRIPTION_ITEM (Prescription Line Items)
CREATE TABLE PRESCRIPTION_ITEM (
    item_id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_id             UUID NOT NULL,
    medicine_id                 UUID NOT NULL,
    dosage                      VARCHAR(50) NOT NULL,
    frequency                   VARCHAR(50) NOT NULL,
    duration_days               INT NOT NULL,
    quantity                    INT NOT NULL,
    unit_price_at_prescription  DECIMAL(10, 2) NOT NULL,
    CONSTRAINT fk_item_prescription FOREIGN KEY (prescription_id) 
        REFERENCES DIGITAL_PRESCRIPTION(prescription_id) ON DELETE CASCADE,
    CONSTRAINT fk_item_medicine FOREIGN KEY (medicine_id) 
        REFERENCES MEDICINE(medicine_id) ON DELETE RESTRICT,
    CONSTRAINT chk_item_duration CHECK (duration_days > 0),
    CONSTRAINT chk_item_quantity CHECK (quantity > 0),
    CONSTRAINT chk_item_price CHECK (unit_price_at_prescription >= 0)
);

-- 1.11 INVOICE (Encounter Fiscal Billing)
CREATE TABLE INVOICE (
    invoice_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id  UUID NOT NULL UNIQUE,
    patient_id      UUID NOT NULL,
    issue_date      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount    DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    payment_status  VARCHAR(20) NOT NULL DEFAULT 'Unpaid',
    payment_method  VARCHAR(20) NOT NULL DEFAULT 'Cash',
    CONSTRAINT fk_invoice_appointment FOREIGN KEY (appointment_id) 
        REFERENCES APPOINTMENT(appointment_id) ON DELETE RESTRICT,
    CONSTRAINT fk_invoice_patient FOREIGN KEY (patient_id) 
        REFERENCES PATIENT(patient_id) ON DELETE RESTRICT,
    CONSTRAINT chk_invoice_total CHECK (total_amount >= 0),
    CONSTRAINT chk_invoice_status CHECK (payment_status IN ('Unpaid', 'Paid', 'Refunded')),
    CONSTRAINT chk_invoice_method CHECK (payment_method IN ('Cash', 'Credit Card', 'Insurance', 'Bank Transfer'))
);

-- ============================================================================
-- 2. PERFORMANCE INDEXING STRATEGY (B-TREE INDEXES)
-- ============================================================================

-- Doctor schedule & availability lookup
CREATE INDEX idx_doctor_schedule_lookup 
    ON DOCTOR_SCHEDULE (doctor_id, work_date, start_time);

-- Appointment query by doctor and date (Conflict prevention & Roster lookup)
CREATE INDEX idx_appointment_doctor_date 
    ON APPOINTMENT (doctor_id, appointment_date, start_time);

-- Patient appointment history lookup
CREATE INDEX idx_appointment_patient 
    ON APPOINTMENT (patient_id, appointment_date);

-- Patient phone quick search
CREATE INDEX idx_patient_phone 
    ON PATIENT (phone_number);

-- Clinical record lookup
CREATE INDEX idx_medical_record_patient 
    ON MEDICAL_RECORD (patient_id, record_date);

-- Prescription items FK index for cascade operations & joins
CREATE INDEX idx_pres_item_prescription 
    ON PRESCRIPTION_ITEM (prescription_id);

CREATE INDEX idx_pres_item_medicine 
    ON PRESCRIPTION_ITEM (medicine_id);

-- Medicine inventory replenishment trigger/warning
CREATE INDEX idx_medicine_stock_alert 
    ON MEDICINE (stock_quantity, reorder_level);

-- Financial invoice status & settlement audit
CREATE INDEX idx_invoice_status_date 
    ON INVOICE (payment_status, issue_date);

-- ============================================================================
-- 3. ANALYTICAL & REPORTING VIEWS
-- ============================================================================

-- View 1: Doctor Daily Roster (Duty Schedule & Specialization)
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
FROM DOCTOR_SCHEDULE ds
JOIN DOCTOR d ON ds.doctor_id = d.doctor_id
LEFT JOIN GENERAL_PRACTITIONER gp ON d.doctor_id = gp.doctor_id
LEFT JOIN SPECIALIST sp ON d.doctor_id = sp.doctor_id
WHERE d.status = 'Active';

-- View 2: Appointment Billing Summary (Consultation Fee + Medicine Total)
CREATE OR REPLACE VIEW v_appointment_billing_summary AS
SELECT 
    i.invoice_id,
    a.appointment_id,
    p.full_name AS patient_name,
    p.phone_number AS patient_phone,
    d.full_name AS doctor_name,
    a.consultation_type,
    a.appointment_date,
    i.total_amount,
    i.payment_status,
    i.payment_method,
    i.issue_date
FROM INVOICE i
JOIN APPOINTMENT a ON i.appointment_id = a.appointment_id
JOIN PATIENT p ON i.patient_id = p.patient_id
JOIN DOCTOR d ON a.doctor_id = d.doctor_id;

-- View 3: Low Stock Medicines Alert (Inventory Procurement)
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
FROM MEDICINE
WHERE stock_quantity <= reorder_level
ORDER BY stock_quantity ASC;

-- ============================================================================
-- END OF SCRIPT: 01_schema.sql
-- Procedural Triggers (BR-01, BR-09, BR-10) are maintained in 03_triggers.sql
-- ============================================================================
