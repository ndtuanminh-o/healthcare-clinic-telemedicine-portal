-- 1. VIEW: các ca làm việc còn trống của bác sĩ
CREATE OR REPLACE VIEW V_DOCTOR_AVAILABLE_SLOT AS
SELECT
    ds.schedule_id,
    d.doctor_id,
    d.full_name AS doctor_name,
    d.doctor_type,
    ds.work_date,
    ds.start_time,
    ds.end_time
FROM DOCTOR_SCHEDULE ds
JOIN DOCTOR d ON d.doctor_id = ds.doctor_id
WHERE ds.slot_status = 'Available';


-- 2. TRIGGER: không cho đặt lịch trùng giờ của cùng một bác sĩ
DROP TRIGGER IF EXISTS TRG_APPOINTMENT_BEFORE_INSERT;

DELIMITER $$

CREATE TRIGGER TRG_APPOINTMENT_BEFORE_INSERT
BEFORE INSERT ON APPOINTMENT
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM APPOINTMENT a
        WHERE a.doctor_id = NEW.doctor_id
          AND a.appointment_date = NEW.appointment_date
          AND a.status <> 'Cancelled'
          AND NEW.start_time < a.end_time
          AND NEW.end_time > a.start_time
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Bac si da co lich hen trung gio nay';
    END IF;
END$$

DELIMITER ;
