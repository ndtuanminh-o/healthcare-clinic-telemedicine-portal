USE healthcare_clinic_v2;

DELIMITER //

-- ============================================================================
-- 1. BR-01: PREVENT APPOINTMENT SCHEDULING CONFLICTS
-- ============================================================================
DROP TRIGGER IF EXISTS TRG_APPOINTMENT_BEFORE_INSERT//

CREATE TRIGGER TRG_APPOINTMENT_BEFORE_INSERT
BEFORE INSERT ON appointment
FOR EACH ROW
BEGIN
    DECLARE v_lock_id CHAR(36);

    IF IFNULL(@DISABLE_TRIGGERS, 0) <> 1 THEN
        -- Lock the doctor and patient records to reduce concurrent booking conflicts.
        SELECT doctor_id INTO v_lock_id
        FROM doctor
        WHERE doctor_id = NEW.doctor_id
        FOR UPDATE;

        SELECT patient_id INTO v_lock_id
        FROM patient
        WHERE patient_id = NEW.patient_id
        FOR UPDATE;

        -- Ensure the appointment end time is later than the start time.
        IF NEW.end_time <= NEW.start_time THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid appointment time: end_time must be greater than start_time';
        END IF;

        -- Check for overlapping appointments assigned to the same doctor or patient.
        IF EXISTS (
            SELECT 1
            FROM appointment A
            WHERE A.appointment_date = NEW.appointment_date
              AND A.status NOT IN ('Cancelled', 'Completed')
              AND (
                    A.doctor_id = NEW.doctor_id
                    OR A.patient_id = NEW.patient_id
                  )
              AND NEW.start_time < A.end_time
              AND NEW.end_time > A.start_time
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR-01: Doctor or patient already has an overlapping appointment';
        END IF;
    END IF;
END//


DROP TRIGGER IF EXISTS TRG_APPOINTMENT_BEFORE_UPDATE//

CREATE TRIGGER TRG_APPOINTMENT_BEFORE_UPDATE
BEFORE UPDATE ON appointment
FOR EACH ROW
BEGIN
    DECLARE v_lock_id CHAR(36);

    IF IFNULL(@DISABLE_TRIGGERS, 0) <> 1 THEN
        -- Lock the doctor and patient records to reduce concurrent booking conflicts.
        SELECT doctor_id INTO v_lock_id
        FROM doctor
        WHERE doctor_id = NEW.doctor_id
        FOR UPDATE;

        SELECT patient_id INTO v_lock_id
        FROM patient
        WHERE patient_id = NEW.patient_id
        FOR UPDATE;

        -- Ensure the appointment end time is later than the start time.
        IF NEW.end_time <= NEW.start_time THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid appointment time: end_time must be greater than start_time';
        END IF;

        -- Check for overlapping appointments, excluding the current record.
        IF EXISTS (
            SELECT 1
            FROM appointment A
            WHERE A.appointment_id <> OLD.appointment_id
              AND A.appointment_date = NEW.appointment_date
              AND A.status NOT IN ('Cancelled', 'Completed')
              AND (
                    A.doctor_id = NEW.doctor_id
                    OR A.patient_id = NEW.patient_id
                  )
              AND NEW.start_time < A.end_time
              AND NEW.end_time > A.start_time
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR-01: Doctor or patient already has an overlapping appointment';
        END IF;
    END IF;
END//


-- ============================================================================
-- 2. BR-02: VALIDATE DOCTOR WORKING SHIFTS
-- ============================================================================
DROP TRIGGER IF EXISTS TRG_APPOINTMENT_CHECK_SCHEDULE_INSERT//

CREATE TRIGGER TRG_APPOINTMENT_CHECK_SCHEDULE_INSERT
BEFORE INSERT ON appointment
FOR EACH ROW
BEGIN
    IF IFNULL(@DISABLE_TRIGGERS, 0) <> 1 THEN
        -- Verify that the appointment falls entirely within a scheduled shift.
        IF NOT EXISTS (
            SELECT 1
            FROM doctor_schedule DS
            WHERE DS.doctor_id = NEW.doctor_id
              AND DS.work_date = NEW.appointment_date
              AND NEW.start_time >= DS.start_time
              AND NEW.end_time <= DS.end_time
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR-02: Appointment must be completely within the doctor working shift';
        END IF;
    END IF;
END//


DROP TRIGGER IF EXISTS TRG_APPOINTMENT_CHECK_SCHEDULE_UPDATE//

CREATE TRIGGER TRG_APPOINTMENT_CHECK_SCHEDULE_UPDATE
BEFORE UPDATE ON appointment
FOR EACH ROW
BEGIN
    IF IFNULL(@DISABLE_TRIGGERS, 0) <> 1 THEN
        -- Revalidate the doctor's shift when the doctor, date, or appointment time changes.
        IF NOT EXISTS (
            SELECT 1
            FROM doctor_schedule DS
            WHERE DS.doctor_id = NEW.doctor_id
              AND DS.work_date = NEW.appointment_date
              AND NEW.start_time >= DS.start_time
              AND NEW.end_time <= DS.end_time
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR-02: Appointment must be completely within the doctor working shift';
        END IF;
    END IF;
END//


-- ============================================================================
-- 3. BR-09: AUTOMATICALLY DEDUCT MEDICINE INVENTORY
-- ============================================================================
DROP TRIGGER IF EXISTS TRG_PRESCRIPTION_AFTER_UPDATE//

CREATE TRIGGER TRG_PRESCRIPTION_AFTER_UPDATE
AFTER UPDATE ON digital_prescription
FOR EACH ROW
BEGIN
    DECLARE v_expected INT DEFAULT 0;
    DECLARE v_updated INT DEFAULT 0;

    IF IFNULL(@DISABLE_TRIGGERS, 0) <> 1 THEN
        -- Execute only when the prescription status changes to Issued.
        IF OLD.status <> 'Issued'
           AND NEW.status = 'Issued' THEN

            -- Count the distinct medicines included in the prescription.
            SELECT COUNT(*)
            INTO v_expected
            FROM (
                SELECT medicine_id
                FROM prescription_item
                WHERE prescription_id = NEW.prescription_id
                GROUP BY medicine_id
            ) AS MEDICINE_LIST;

            -- Deduct medicine quantities only when sufficient stock is available.
            UPDATE medicine M
            INNER JOIN (
                SELECT
                    medicine_id,
                    SUM(quantity) AS total_quantity
                FROM prescription_item
                WHERE prescription_id = NEW.prescription_id
                GROUP BY medicine_id
            ) AS PI
                ON M.medicine_id = PI.medicine_id
            SET M.stock_quantity =
                M.stock_quantity - PI.total_quantity
            WHERE M.stock_quantity >= PI.total_quantity;

            -- The number of updated rows must match the number of medicines required.
            SET v_updated = ROW_COUNT();

            -- If any medicine has insufficient stock, cancel the entire issuance.
            IF v_updated <> v_expected THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'BR-09: Insufficient medicine stock. Prescription issuance has been cancelled';
            END IF;

        END IF;
    END IF;
END//


-- ============================================================================
-- 4. BR-10: PREVENT MODIFICATION OF ISSUED PRESCRIPTIONS
-- ============================================================================
DROP TRIGGER IF EXISTS TRG_PRESCRIPTION_BEFORE_UPDATE//

CREATE TRIGGER TRG_PRESCRIPTION_BEFORE_UPDATE
BEFORE UPDATE ON digital_prescription
FOR EACH ROW
BEGIN
    IF IFNULL(@DISABLE_TRIGGERS, 0) <> 1 THEN
        -- Issued prescriptions cannot be modified.
        IF OLD.status = 'Issued' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR-10: Issued prescription cannot be modified';
        END IF;
    END IF;
END//


DROP TRIGGER IF EXISTS TRG_PRESCRIPTION_BEFORE_DELETE//

CREATE TRIGGER TRG_PRESCRIPTION_BEFORE_DELETE
BEFORE DELETE ON digital_prescription
FOR EACH ROW
BEGIN
    IF IFNULL(@DISABLE_TRIGGERS, 0) <> 1 THEN
        -- Issued prescriptions cannot be deleted.
        IF OLD.status = 'Issued' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR-10: Issued prescription cannot be deleted';
        END IF;
    END IF;
END//


-- ============================================================================
-- 5. BR-10: PROTECT ISSUED PRESCRIPTION DETAILS
-- ============================================================================
DROP TRIGGER IF EXISTS TRG_PRESCRIPTION_ITEM_BEFORE_INSERT//

CREATE TRIGGER TRG_PRESCRIPTION_ITEM_BEFORE_INSERT
BEFORE INSERT ON prescription_item
FOR EACH ROW
BEGIN
    IF IFNULL(@DISABLE_TRIGGERS, 0) <> 1 THEN
        -- Prevent adding medicines to an issued prescription.
        IF EXISTS (
            SELECT 1
            FROM digital_prescription DP
            WHERE DP.prescription_id = NEW.prescription_id
              AND DP.status = 'Issued'
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR-10: Cannot add medicine to an issued prescription';
        END IF;
    END IF;
END//


DROP TRIGGER IF EXISTS TRG_PRESCRIPTION_ITEM_BEFORE_UPDATE//

CREATE TRIGGER TRG_PRESCRIPTION_ITEM_BEFORE_UPDATE
BEFORE UPDATE ON prescription_item
FOR EACH ROW
BEGIN
    IF IFNULL(@DISABLE_TRIGGERS, 0) <> 1 THEN
        -- Prevent modifying or transferring details of an issued prescription.
        IF EXISTS (
            SELECT 1
            FROM digital_prescription DP
            WHERE DP.prescription_id = OLD.prescription_id
              AND DP.status = 'Issued'
        )
        OR EXISTS (
            SELECT 1
            FROM digital_prescription DP
            WHERE DP.prescription_id = NEW.prescription_id
              AND DP.status = 'Issued'
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR-10: Cannot modify details of an issued prescription';
        END IF;
    END IF;
END//


DROP TRIGGER IF EXISTS TRG_PRESCRIPTION_ITEM_BEFORE_DELETE//

CREATE TRIGGER TRG_PRESCRIPTION_ITEM_BEFORE_DELETE
BEFORE DELETE ON prescription_item
FOR EACH ROW
BEGIN
    IF IFNULL(@DISABLE_TRIGGERS, 0) <> 1 THEN
        -- Prevent deleting details belonging to an issued prescription.
        IF EXISTS (
            SELECT 1
            FROM digital_prescription DP
            WHERE DP.prescription_id = OLD.prescription_id
              AND DP.status = 'Issued'
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR-10: Cannot delete details of an issued prescription';
        END IF;
    END IF;
END//


-- ============================================================================
-- 6. PATIENT DATE OF BIRTH VALIDATION
-- ============================================================================
DROP TRIGGER IF EXISTS TRG_PATIENT_BEFORE_INSERT//

CREATE TRIGGER TRG_PATIENT_BEFORE_INSERT
BEFORE INSERT ON patient
FOR EACH ROW
BEGIN
    IF IFNULL(@DISABLE_TRIGGERS, 0) <> 1 THEN
        -- Reject patient records with a future date of birth.
        IF NEW.date_of_birth > CURRENT_DATE() THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid date of birth: date_of_birth cannot be in the future';
        END IF;
    END IF;
END//


DROP TRIGGER IF EXISTS TRG_PATIENT_BEFORE_UPDATE//

CREATE TRIGGER TRG_PATIENT_BEFORE_UPDATE
BEFORE UPDATE ON patient
FOR EACH ROW
BEGIN
    IF IFNULL(@DISABLE_TRIGGERS, 0) <> 1 THEN
        -- Revalidate the date of birth whenever a patient record is updated.
        IF NEW.date_of_birth > CURRENT_DATE() THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid date of birth: date_of_birth cannot be in the future';
        END IF;
    END IF;
END//

DELIMITER ;


-- ============================================================================
-- 7. VIEWS
-- ============================================================================

CREATE OR REPLACE VIEW v_doctor_daily_roster AS
SELECT 
    ds.schedule_id,
    d.doctor_id,
    d.full_name AS doctor_name,
    d.doctor_type,
    COALESCE(gp.clinic_room_no, 'Telemedicine Room') AS location,
    COALESCE(sp.specialty, 'General Practice') AS clinical_domain,
    ds.work_date,
    ds.start_time,
    ds.end_time,
    ds.slot_status
FROM doctor_schedule ds
JOIN doctor d ON ds.doctor_id = d.doctor_id
LEFT JOIN general_practitioner gp ON d.doctor_id = gp.doctor_id
LEFT JOIN specialist sp ON d.doctor_id = sp.doctor_id
WHERE d.status = 'Active' AND d.deleted_at IS NULL;

CREATE OR REPLACE VIEW v_appointment_billing_summary AS
SELECT 
    a.appointment_id,
    a.booking_time,
    a.appointment_date,
    a.consultation_type,
    a.status AS appointment_status,
    p.patient_id,
    p.full_name AS patient_name,
    d.doctor_id,
    d.full_name AS doctor_name,
    d.doctor_type,
    i.invoice_id,
    i.total_amount,
    i.payment_status
FROM appointment a
JOIN patient p ON a.patient_id = p.patient_id
JOIN doctor d ON a.doctor_id = d.doctor_id
LEFT JOIN invoice i ON a.appointment_id = i.appointment_id
WHERE a.deleted_at IS NULL;

CREATE OR REPLACE VIEW v_low_stock_medicines AS
SELECT 
    medicine_id,
    medicine_name,
    stock_quantity,
    reorder_level,
    unit,
    unit_price,
    (reorder_level - stock_quantity) AS units_needed
FROM medicine
WHERE stock_quantity <= reorder_level;

CREATE OR REPLACE VIEW v_doctor_integrity_violations AS
SELECT d.doctor_id, d.full_name, d.doctor_type,
       'Doctor marked GP has row in specialist' AS violation_type
FROM doctor d
JOIN specialist s ON d.doctor_id = s.doctor_id
WHERE d.doctor_type = 'GP'
UNION ALL
SELECT d.doctor_id, d.full_name, d.doctor_type,
       'Doctor marked Specialist has row in general_practitioner' AS violation_type
FROM doctor d
JOIN general_practitioner gp ON d.doctor_id = gp.doctor_id
WHERE d.doctor_type = 'Specialist';
