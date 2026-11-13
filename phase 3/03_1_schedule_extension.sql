USE healthcare_clinic_v2;

START TRANSACTION;

SET SESSION cte_max_recursion_depth = 1000;

WITH RECURSIVE dates AS (
    SELECT DATE('2026-11-01') AS work_date

    UNION ALL

    SELECT DATE_ADD(work_date, INTERVAL 1 DAY)
    FROM dates
    WHERE work_date < '2026-12-31'
)
INSERT INTO DOCTOR_SCHEDULE
(
    schedule_id,
    doctor_id,
    work_date,
    start_time,
    end_time,
    slot_status
)
SELECT
    UUID(),
    d.doctor_id,
    dates.work_date,
    '08:00:00',
    '17:00:00',
    'Available'
FROM dates
CROSS JOIN DOCTOR d
WHERE DAYOFWEEK(dates.work_date) NOT IN (1, 7)
  AND d.status = 'Active'
  AND d.deleted_at IS NULL
  AND NOT EXISTS (
      SELECT 1
      FROM DOCTOR_SCHEDULE existing_schedule
      WHERE existing_schedule.doctor_id = d.doctor_id
        AND existing_schedule.work_date = dates.work_date
        AND existing_schedule.start_time = '08:00:00'
        AND existing_schedule.end_time = '17:00:00'
  );

COMMIT;
