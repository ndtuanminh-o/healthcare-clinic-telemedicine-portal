USE healthcare_clinic_v2;

DELIMITER //

-- 1. BR-01: PREVENT APPOINTMENT SCHEDULING CONFLICTS
DROP TRIGGER IF EXISTS TRG_APPOINTMENT_BEFORE_INSERT//

CREATE TRIGGER TRG_APPOINTMENT_BEFORE_INSERT
BEFORE INSERT ON APPOINTMENT
FOR EACH ROW
BEGIN
    DECLARE v_lock_id CHAR(36);

    -- Lock the doctor and patient records to reduce concurrent booking conflicts.
    SELECT doctor_id INTO v_lock_id
    FROM DOCTOR
    WHERE doctor_id = NEW.doctor_id
    FOR UPDATE;

    SELECT patient_id INTO v_lock_id
    FROM PATIENT
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
        FROM APPOINTMENT A
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
END//


DROP TRIGGER IF EXISTS TRG_APPOINTMENT_BEFORE_UPDATE//

CREATE TRIGGER TRG_APPOINTMENT_BEFORE_UPDATE
BEFORE UPDATE ON APPOINTMENT
FOR EACH ROW
BEGIN
    DECLARE v_lock_id CHAR(36);

    -- Lock the doctor and patient records to reduce concurrent booking conflicts.
    SELECT doctor_id INTO v_lock_id
    FROM DOCTOR
    WHERE doctor_id = NEW.doctor_id
    FOR UPDATE;

    SELECT patient_id INTO v_lock_id
    FROM PATIENT
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
        FROM APPOINTMENT A
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
END//


-- 2. BR-02: VALIDATE DOCTOR WORKING SHIFTS
DROP TRIGGER IF EXISTS TRG_APPOINTMENT_CHECK_SCHEDULE_INSERT//

CREATE TRIGGER TRG_APPOINTMENT_CHECK_SCHEDULE_INSERT
BEFORE INSERT ON APPOINTMENT
FOR EACH ROW
BEGIN
    -- Verify that the appointment falls entirely within a scheduled shift.
    IF NOT EXISTS (
        SELECT 1
        FROM DOCTOR_SCHEDULE DS
        WHERE DS.doctor_id = NEW.doctor_id
          AND DS.work_date = NEW.appointment_date
          AND NEW.start_time >= DS.start_time
          AND NEW.end_time <= DS.end_time
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'BR-02: Appointment must be completely within the doctor working shift';
    END IF;
END//


DROP TRIGGER IF EXISTS TRG_APPOINTMENT_CHECK_SCHEDULE_UPDATE//

CREATE TRIGGER TRG_APPOINTMENT_CHECK_SCHEDULE_UPDATE
BEFORE UPDATE ON APPOINTMENT
FOR EACH ROW
BEGIN
    -- Revalidate the doctor's shift when the doctor, date, or appointment time changes.
    IF NOT EXISTS (
        SELECT 1
        FROM DOCTOR_SCHEDULE DS
        WHERE DS.doctor_id = NEW.doctor_id
          AND DS.work_date = NEW.appointment_date
          AND NEW.start_time >= DS.start_time
          AND NEW.end_time <= DS.end_time
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'BR-02: Appointment must be completely within the doctor working shift';
    END IF;
END//


-- 3. BR-09: AUTOMATICALLY DEDUCT MEDICINE INVENTORY
DROP TRIGGER IF EXISTS TRG_PRESCRIPTION_AFTER_UPDATE//

CREATE TRIGGER TRG_PRESCRIPTION_AFTER_UPDATE
AFTER UPDATE ON DIGITAL_PRESCRIPTION
FOR EACH ROW
BEGIN
    DECLARE v_expected INT DEFAULT 0;
    DECLARE v_updated INT DEFAULT 0;

    -- Execute only when the prescription status changes to Issued.
    IF OLD.status <> 'Issued'
       AND NEW.status = 'Issued' THEN

        -- Count the distinct medicines included in the prescription.
        SELECT COUNT(*)
        INTO v_expected
        FROM (
            SELECT medicine_id
            FROM PRESCRIPTION_ITEM
            WHERE prescription_id = NEW.prescription_id
            GROUP BY medicine_id
        ) AS MEDICINE_LIST;

        -- Deduct medicine quantities only when sufficient stock is available.
        UPDATE MEDICINE M
        INNER JOIN (
            SELECT
                medicine_id,
                SUM(quantity) AS total_quantity
            FROM PRESCRIPTION_ITEM
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
END//


-- 4. BR-10: PREVENT MODIFICATION OF ISSUED PRESCRIPTIONS
DROP TRIGGER IF EXISTS TRG_PRESCRIPTION_BEFORE_UPDATE//

CREATE TRIGGER TRG_PRESCRIPTION_BEFORE_UPDATE
BEFORE UPDATE ON DIGITAL_PRESCRIPTION
FOR EACH ROW
BEGIN
    -- Issued prescriptions cannot be modified.
    IF OLD.status = 'Issued' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'BR-10: Issued prescription cannot be modified';
    END IF;
END//


DROP TRIGGER IF EXISTS TRG_PRESCRIPTION_BEFORE_DELETE//

CREATE TRIGGER TRG_PRESCRIPTION_BEFORE_DELETE
BEFORE DELETE ON DIGITAL_PRESCRIPTION
FOR EACH ROW
BEGIN
    -- Issued prescriptions cannot be deleted.
    IF OLD.status = 'Issued' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'BR-10: Issued prescription cannot be deleted';
    END IF;
END//


-- 5. BR-10: PROTECT ISSUED PRESCRIPTION DETAILS
DROP TRIGGER IF EXISTS TRG_PRESCRIPTION_ITEM_BEFORE_INSERT//

CREATE TRIGGER TRG_PRESCRIPTION_ITEM_BEFORE_INSERT
BEFORE INSERT ON PRESCRIPTION_ITEM
FOR EACH ROW
BEGIN
    -- Prevent adding medicines to an issued prescription.
    IF EXISTS (
        SELECT 1
        FROM DIGITAL_PRESCRIPTION DP
        WHERE DP.prescription_id = NEW.prescription_id
          AND DP.status = 'Issued'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'BR-10: Cannot add medicine to an issued prescription';
    END IF;
END//


DROP TRIGGER IF EXISTS TRG_PRESCRIPTION_ITEM_BEFORE_UPDATE//

CREATE TRIGGER TRG_PRESCRIPTION_ITEM_BEFORE_UPDATE
BEFORE UPDATE ON PRESCRIPTION_ITEM
FOR EACH ROW
BEGIN
    -- Prevent modifying or transferring details of an issued prescription.
    IF EXISTS (
        SELECT 1
        FROM DIGITAL_PRESCRIPTION DP
        WHERE DP.prescription_id = OLD.prescription_id
          AND DP.status = 'Issued'
    )
    OR EXISTS (
        SELECT 1
        FROM DIGITAL_PRESCRIPTION DP
        WHERE DP.prescription_id = NEW.prescription_id
          AND DP.status = 'Issued'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'BR-10: Cannot modify details of an issued prescription';
    END IF;
END//


DROP TRIGGER IF EXISTS TRG_PRESCRIPTION_ITEM_BEFORE_DELETE//

CREATE TRIGGER TRG_PRESCRIPTION_ITEM_BEFORE_DELETE
BEFORE DELETE ON PRESCRIPTION_ITEM
FOR EACH ROW
BEGIN
    -- Prevent deleting details belonging to an issued prescription.
    IF EXISTS (
        SELECT 1
        FROM DIGITAL_PRESCRIPTION DP
        WHERE DP.prescription_id = OLD.prescription_id
          AND DP.status = 'Issued'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'BR-10: Cannot delete details of an issued prescription';
    END IF;
END//


-- 6. PATIENT DATE OF BIRTH VALIDATION
DROP TRIGGER IF EXISTS TRG_PATIENT_BEFORE_INSERT//

CREATE TRIGGER TRG_PATIENT_BEFORE_INSERT
BEFORE INSERT ON PATIENT
FOR EACH ROW
BEGIN
    -- Reject patient records with a future date of birth.
    IF NEW.date_of_birth > CURRENT_DATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid date of birth: date_of_birth cannot be in the future';
    END IF;
END//


DROP TRIGGER IF EXISTS TRG_PATIENT_BEFORE_UPDATE//

CREATE TRIGGER TRG_PATIENT_BEFORE_UPDATE
BEFORE UPDATE ON PATIENT
FOR EACH ROW
BEGIN
    -- Revalidate the date of birth whenever a patient record is updated.
    IF NEW.date_of_birth > CURRENT_DATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid date of birth: date_of_birth cannot be in the future';
    END IF;
END//


DELIMITER ;
