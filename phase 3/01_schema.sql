SET FOREIGN_KEY_CHECKS = 0;

DROP VIEW IF EXISTS v_low_stock_medicines;
DROP VIEW IF EXISTS v_appointment_billing_summary;
DROP VIEW IF EXISTS v_doctor_daily_roster;

DROP TABLE IF EXISTS INVOICE;
DROP TABLE IF EXISTS PRESCRIPTION_ITEM;
DROP TABLE IF EXISTS MEDICINE;
DROP TABLE IF EXISTS DIGITAL_PRESCRIPTION;
DROP TABLE IF EXISTS MEDICAL_RECORD;
DROP TABLE IF EXISTS APPOINTMENT;
DROP TABLE IF EXISTS PATIENT;
DROP TABLE IF EXISTS DOCTOR_SCHEDULE;
DROP TABLE IF EXISTS SPECIALIST;
DROP TABLE IF EXISTS GENERAL_PRACTITIONER;
DROP TABLE IF EXISTS DOCTOR;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE DOCTOR (
    doctor_id       CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    full_name       VARCHAR(100) NOT NULL,
    license_no      VARCHAR(30) NOT NULL UNIQUE,
    phone_number    VARCHAR(15) NOT NULL,
    email           VARCHAR(100) NULL,
    doctor_type     ENUM('GP', 'Specialist') NOT NULL,
    status          ENUM('Active', 'Inactive') NOT NULL DEFAULT 'Active',
    deleted_at      DATETIME NULL
);

CREATE TABLE GENERAL_PRACTITIONER (
    doctor_id           CHAR(36) PRIMARY KEY,
    clinic_room_no      VARCHAR(20) NOT NULL,
    consultation_fee    DECIMAL(10, 2) NOT NULL DEFAULT 150000.00,
    CONSTRAINT fk_gp_doctor FOREIGN KEY (doctor_id) 
        REFERENCES DOCTOR(doctor_id) ON DELETE RESTRICT,
    CONSTRAINT chk_gp_fee CHECK (consultation_fee > 0)
);

CREATE TABLE SPECIALIST (
    doctor_id               CHAR(36) PRIMARY KEY,
    specialty               VARCHAR(50) NOT NULL,
    consultation_fee        DECIMAL(10, 2) NOT NULL DEFAULT 300000.00,
    board_certified_year    INT NOT NULL,
    CONSTRAINT fk_specialist_doctor FOREIGN KEY (doctor_id) 
        REFERENCES DOCTOR(doctor_id) ON DELETE RESTRICT,
    CONSTRAINT chk_specialist_fee CHECK (consultation_fee > 0),
    CONSTRAINT chk_specialist_year CHECK (board_certified_year <= YEAR(CURRENT_DATE))
);

CREATE TABLE DOCTOR_SCHEDULE (
    schedule_id     CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    doctor_id       CHAR(36) NOT NULL,
    work_date       DATE NOT NULL,
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    slot_status     ENUM('Available', 'Booked', 'Blocked') NOT NULL DEFAULT 'Available',
    CONSTRAINT fk_schedule_doctor FOREIGN KEY (doctor_id) 
        REFERENCES DOCTOR(doctor_id) ON DELETE CASCADE,
    CONSTRAINT chk_schedule_time CHECK (end_time > start_time)
);

CREATE TABLE PATIENT (
    patient_id      CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    full_name       VARCHAR(100) NOT NULL,
    date_of_birth   DATE NOT NULL,
    gender          ENUM('M', 'F', 'O') DEFAULT 'O',
    phone_number    VARCHAR(15) NOT NULL UNIQUE,
    address         VARCHAR(255) NULL,
    status          ENUM('Active', 'Inactive') NOT NULL DEFAULT 'Active',
    deleted_at      DATETIME NULL,
    CONSTRAINT chk_patient_dob CHECK (date_of_birth <= CURRENT_DATE)
);

CREATE TABLE APPOINTMENT (
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
        REFERENCES PATIENT(patient_id) ON DELETE RESTRICT,
    CONSTRAINT fk_appointment_doctor FOREIGN KEY (doctor_id) 
        REFERENCES DOCTOR(doctor_id) ON DELETE RESTRICT,
    CONSTRAINT chk_appointment_time CHECK (end_time > start_time)
);

CREATE TABLE MEDICAL_RECORD (
    record_id       CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    appointment_id  CHAR(36) NOT NULL UNIQUE,
    patient_id      CHAR(36) NOT NULL,
    specialist_id   CHAR(36) NULL,
    diagnosis       TEXT NOT NULL,
    clinical_notes  TEXT NULL,
    treatment_plan  TEXT NULL,
    record_date     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at      DATETIME NULL,
    CONSTRAINT fk_record_appointment FOREIGN KEY (appointment_id) 
        REFERENCES APPOINTMENT(appointment_id) ON DELETE RESTRICT,
    CONSTRAINT fk_record_patient FOREIGN KEY (patient_id) 
        REFERENCES PATIENT(patient_id) ON DELETE RESTRICT,
    CONSTRAINT fk_record_specialist FOREIGN KEY (specialist_id) 
        REFERENCES SPECIALIST(doctor_id) ON DELETE SET NULL
);

CREATE TABLE DIGITAL_PRESCRIPTION (
    prescription_id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    record_id       CHAR(36) NOT NULL UNIQUE,
    issue_date      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_until     DATE NOT NULL,
    instructions    TEXT NULL,
    status          ENUM('Draft', 'Issued', 'Dispensed', 'Cancelled') NOT NULL DEFAULT 'Draft',
    deleted_at      DATETIME NULL,
    CONSTRAINT fk_prescription_record FOREIGN KEY (record_id) 
        REFERENCES MEDICAL_RECORD(record_id) ON DELETE RESTRICT,
    CONSTRAINT chk_prescription_validity CHECK (valid_until >= DATE(issue_date))
);

CREATE TABLE MEDICINE (
    medicine_id         CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    medicine_name       VARCHAR(100) NOT NULL UNIQUE,
    active_ingredient   VARCHAR(100) NULL,
    unit                VARCHAR(20) NOT NULL DEFAULT 'Viên',
    unit_price          DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    stock_quantity      INT NOT NULL DEFAULT 0,
    reorder_level       INT NOT NULL DEFAULT 10,
    CONSTRAINT chk_medicine_price CHECK (unit_price >= 0),
    CONSTRAINT chk_medicine_stock CHECK (stock_quantity >= 0),
    CONSTRAINT chk_medicine_reorder CHECK (reorder_level >= 0)
);

CREATE TABLE PRESCRIPTION_ITEM (
    item_id                     CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    prescription_id             CHAR(36) NOT NULL,
    medicine_id                 CHAR(36) NOT NULL,
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

CREATE TABLE INVOICE (
    invoice_id      CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    appointment_id  CHAR(36) NOT NULL UNIQUE,
    patient_id      CHAR(36) NOT NULL,
    issue_date      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount    DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    payment_status  ENUM('Unpaid', 'Paid', 'Refunded') NOT NULL DEFAULT 'Unpaid',
    payment_method  ENUM('Cash', 'Credit Card', 'Insurance', 'Bank Transfer') NOT NULL DEFAULT 'Cash',
    CONSTRAINT fk_invoice_appointment FOREIGN KEY (appointment_id) 
        REFERENCES APPOINTMENT(appointment_id) ON DELETE RESTRICT,
    CONSTRAINT fk_invoice_patient FOREIGN KEY (patient_id) 
        REFERENCES PATIENT(patient_id) ON DELETE RESTRICT,
    CONSTRAINT chk_invoice_total CHECK (total_amount >= 0)
);

CREATE INDEX idx_doctor_schedule_lookup 
    ON DOCTOR_SCHEDULE (doctor_id, work_date, start_time);

CREATE INDEX idx_appointment_doctor_date 
    ON APPOINTMENT (doctor_id, appointment_date, start_time);

CREATE INDEX idx_appointment_patient 
    ON APPOINTMENT (patient_id, appointment_date);

CREATE INDEX idx_patient_phone 
    ON PATIENT (phone_number);

CREATE INDEX idx_medical_record_patient 
    ON MEDICAL_RECORD (patient_id, record_date);

CREATE INDEX idx_pres_item_prescription 
    ON PRESCRIPTION_ITEM (prescription_id);

CREATE INDEX idx_pres_item_medicine 
    ON PRESCRIPTION_ITEM (medicine_id);

CREATE INDEX idx_medicine_stock_alert 
    ON MEDICINE (stock_quantity, reorder_level);

CREATE INDEX idx_invoice_status_date 
    ON INVOICE (payment_status, issue_date);

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
