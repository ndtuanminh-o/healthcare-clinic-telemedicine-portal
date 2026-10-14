
SET @report_month_start = DATE_FORMAT(
    (SELECT MAX(appointment_date) FROM APPOINTMENT),
    '%Y-%m-01'
);
SET @report_month_end = DATE_ADD(@report_month_start, INTERVAL 1 MONTH);

/* ========================================================================
   Q01. Telemedicine ratio for every doctor in the latest data month
   Techniques: JOIN, aggregation, correlated subquery in SELECT.
   Cancelled appointments are excluded from the denominator.
   ======================================================================== */
SELECT
    d.doctor_id,
    d.full_name AS doctor_name,
    d.doctor_type,
    COUNT(a.appointment_id) AS total_non_cancelled_appointments,
    SUM(CASE WHEN a.consultation_type = 'Telemedicine' THEN 1 ELSE 0 END)
        AS telemedicine_appointments,
    ROUND(
        100.0 *
        (
            SELECT COUNT(*)
            FROM APPOINTMENT a_tele
            WHERE a_tele.doctor_id = d.doctor_id
              AND a_tele.consultation_type = 'Telemedicine'
              AND a_tele.status <> 'Cancelled'
              AND a_tele.appointment_date >= @report_month_start
              AND a_tele.appointment_date < @report_month_end
        ) / NULLIF(COUNT(a.appointment_id), 0),
        2
    ) AS telemedicine_percentage
FROM DOCTOR d
LEFT JOIN APPOINTMENT a
    ON a.doctor_id = d.doctor_id
   AND a.status <> 'Cancelled'
   AND a.appointment_date >= @report_month_start
   AND a.appointment_date < @report_month_end
GROUP BY d.doctor_id, d.full_name, d.doctor_type
ORDER BY telemedicine_percentage DESC, total_non_cancelled_appointments DESC;

/* ========================================================================
   Q02. Doctors whose workload is above the clinic-wide average
   Techniques: JOIN, aggregation, CTE/subquery, HAVING-equivalent filter.
   ======================================================================== */
WITH doctor_workload AS (
    SELECT
        d.doctor_id,
        d.full_name AS doctor_name,
        d.doctor_type,
        COUNT(a.appointment_id) AS appointment_count
    FROM DOCTOR d
    LEFT JOIN APPOINTMENT a
        ON a.doctor_id = d.doctor_id
       AND a.status <> 'Cancelled'
       AND a.appointment_date >= @report_month_start
       AND a.appointment_date < @report_month_end
    GROUP BY d.doctor_id, d.full_name, d.doctor_type
), workload_average AS (
    SELECT AVG(appointment_count) AS average_appointments_per_doctor
    FROM doctor_workload
)
SELECT
    w.doctor_id,
    w.doctor_name,
    w.doctor_type,
    w.appointment_count,
    ROUND(a.average_appointments_per_doctor, 2)
        AS clinic_average_appointments
FROM doctor_workload w
CROSS JOIN workload_average a
WHERE w.appointment_count > a.average_appointments_per_doctor
ORDER BY w.appointment_count DESC;

/* ========================================================================
   Q03. Patients using both in-person and telemedicine care
   Techniques: JOIN, GROUP BY/HAVING, two correlated EXISTS subqueries.
   ======================================================================== */
SELECT
    p.patient_id,
    p.full_name AS patient_name,
    COUNT(a.appointment_id) AS non_cancelled_appointments,
    MIN(a.appointment_date) AS first_appointment_date,
    MAX(a.appointment_date) AS latest_appointment_date
FROM PATIENT p
JOIN APPOINTMENT a ON a.patient_id = p.patient_id
WHERE a.status <> 'Cancelled'
GROUP BY p.patient_id, p.full_name
HAVING COUNT(a.appointment_id) >= 2
   AND EXISTS (
       SELECT 1
       FROM APPOINTMENT a_online
       WHERE a_online.patient_id = p.patient_id
         AND a_online.consultation_type = 'Telemedicine'
         AND a_online.status <> 'Cancelled'
   )
   AND EXISTS (
       SELECT 1
       FROM APPOINTMENT a_in_person
       WHERE a_in_person.patient_id = p.patient_id
         AND a_in_person.consultation_type = 'In-Person'
         AND a_in_person.status <> 'Cancelled'
   )
ORDER BY non_cancelled_appointments DESC, patient_name;

/* ========================================================================
   Q04. Specialties with an above-average cancellation rate
   Techniques: JOIN, CASE aggregation, derived-table/subquery comparison.
   ======================================================================== */
WITH specialty_stats AS (
    SELECT
        CASE
            WHEN d.doctor_type = 'Specialist' THEN COALESCE(sp.specialty, 'Unknown')
            ELSE 'General Practice'
        END AS specialty,
        COUNT(a.appointment_id) AS total_appointments,
        SUM(CASE WHEN a.status = 'Cancelled' THEN 1 ELSE 0 END)
            AS cancelled_appointments
    FROM DOCTOR d
    LEFT JOIN SPECIALIST sp ON sp.doctor_id = d.doctor_id
    JOIN APPOINTMENT a ON a.doctor_id = d.doctor_id
    GROUP BY
        CASE
            WHEN d.doctor_type = 'Specialist' THEN COALESCE(sp.specialty, 'Unknown')
            ELSE 'General Practice'
        END
), overall_rate AS (
    SELECT
        1.0 * SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0) AS clinic_cancellation_rate
    FROM APPOINTMENT
)
SELECT
    s.specialty,
    s.total_appointments,
    s.cancelled_appointments,
    ROUND(100.0 * s.cancelled_appointments / NULLIF(s.total_appointments, 0), 2)
        AS cancellation_percentage,
    ROUND(100.0 * o.clinic_cancellation_rate, 2)
        AS clinic_average_cancellation_percentage
FROM specialty_stats s
CROSS JOIN overall_rate o
WHERE 1.0 * s.cancelled_appointments / NULLIF(s.total_appointments, 0)
      > o.clinic_cancellation_rate
ORDER BY cancellation_percentage DESC, s.specialty;

/* ========================================================================
   Q05. Stock-risk alert based on consumption during the latest 14 days
   Techniques: JOIN, SUM in a subquery/CTE, comparison with current stock.
   ======================================================================== */
WITH consumption_last_14_days AS (
    SELECT
        pi.medicine_id,
        SUM(pi.quantity) AS prescribed_quantity_last_14_days
    FROM PRESCRIPTION_ITEM pi
    JOIN DIGITAL_PRESCRIPTION dp
        ON dp.prescription_id = pi.prescription_id
    WHERE dp.status IN ('Issued', 'Dispensed')
      AND dp.issue_date >= DATE_SUB(
          (SELECT MAX(issue_date) FROM DIGITAL_PRESCRIPTION),
          INTERVAL 14 DAY
      )
      AND dp.issue_date <= (SELECT MAX(issue_date) FROM DIGITAL_PRESCRIPTION)
    GROUP BY pi.medicine_id
)
SELECT
    m.medicine_id,
    m.medicine_name,
    m.stock_quantity AS current_stock,
    COALESCE(c.prescribed_quantity_last_14_days, 0)
        AS prescribed_quantity_last_14_days,
    m.reorder_level,
    m.stock_quantity - COALESCE(c.prescribed_quantity_last_14_days, 0)
        AS stock_minus_recent_consumption
FROM MEDICINE m
JOIN consumption_last_14_days c ON c.medicine_id = m.medicine_id
WHERE m.stock_quantity < c.prescribed_quantity_last_14_days
ORDER BY stock_minus_recent_consumption ASC, m.medicine_name;

/* ========================================================================
   Q06. Medicines with monthly revenue above the average medicine revenue
   Techniques: JOIN, SUM, derived tables, AVG subquery.
   Revenue is based on issued/dispensed prescription items.
   ======================================================================== */
WITH medicine_monthly_revenue AS (
    SELECT
        m.medicine_id,
        m.medicine_name,
        SUM(
            pi.quantity * COALESCE(
                pi.unit_price_at_prescription,
                m.unit_price
            )
        ) AS total_medicine_revenue
    FROM MEDICINE m
    JOIN PRESCRIPTION_ITEM pi ON pi.medicine_id = m.medicine_id
    JOIN DIGITAL_PRESCRIPTION dp
        ON dp.prescription_id = pi.prescription_id
    WHERE dp.status IN ('Issued', 'Dispensed')
      AND dp.issue_date >= @report_month_start
      AND dp.issue_date < @report_month_end
    GROUP BY m.medicine_id, m.medicine_name
), average_revenue AS (
    SELECT AVG(total_medicine_revenue) AS average_revenue_per_medicine
    FROM medicine_monthly_revenue
)
SELECT
    r.medicine_id,
    r.medicine_name,
    r.total_medicine_revenue,
    ROUND(a.average_revenue_per_medicine, 2)
        AS average_revenue_per_medicine
FROM medicine_monthly_revenue r
CROSS JOIN average_revenue a
WHERE r.total_medicine_revenue > a.average_revenue_per_medicine
ORDER BY r.total_medicine_revenue DESC;

/* ========================================================================
   Q07. Polypharmacy: prescriptions above the system average item count
   Techniques: COUNT(DISTINCT), GROUP BY, correlated average subquery.
   ======================================================================== */
WITH prescription_medicine_counts AS (
    SELECT
        dp.prescription_id,
        mr.patient_id,
        p.full_name AS patient_name,
        dp.issue_date,
        COUNT(DISTINCT pi.medicine_id) AS distinct_medicine_count
    FROM DIGITAL_PRESCRIPTION dp
    JOIN MEDICAL_RECORD mr ON mr.record_id = dp.record_id
    JOIN PATIENT p ON p.patient_id = mr.patient_id
    JOIN PRESCRIPTION_ITEM pi ON pi.prescription_id = dp.prescription_id
    WHERE dp.status <> 'Cancelled'
    GROUP BY
        dp.prescription_id,
        mr.patient_id,
        p.full_name,
        dp.issue_date
), average_prescription_size AS (
    SELECT AVG(distinct_medicine_count) AS average_distinct_medicines
    FROM prescription_medicine_counts
)
SELECT
    c.prescription_id,
    c.patient_id,
    c.patient_name,
    c.issue_date,
    c.distinct_medicine_count,
    ROUND(a.average_distinct_medicines, 2)
        AS clinic_average_distinct_medicines
FROM prescription_medicine_counts c
CROSS JOIN average_prescription_size a
WHERE c.distinct_medicine_count > a.average_distinct_medicines
ORDER BY c.distinct_medicine_count DESC, c.issue_date DESC;

/* ========================================================================
   Q08. Bad-debt risk by patient
   Techniques: JOIN, SUM, subquery/CTE for average debt.
   Limitation: the current schema has no PAYMENT table or paid_amount;
   only invoices whose payment_status is Unpaid can be measured here.
   ======================================================================== */
WITH unpaid_debt_by_patient AS (
    SELECT
        p.patient_id,
        p.full_name AS patient_name,
        COUNT(i.invoice_id) AS unpaid_invoice_count,
        SUM(i.total_amount) AS total_unpaid_amount
    FROM PATIENT p
    JOIN INVOICE i ON i.patient_id = p.patient_id
    WHERE i.payment_status = 'Unpaid'
    GROUP BY p.patient_id, p.full_name
), average_unpaid_debt AS (
    SELECT AVG(total_unpaid_amount) AS average_unpaid_amount
    FROM unpaid_debt_by_patient
)
SELECT
    d.patient_id,
    d.patient_name,
    d.unpaid_invoice_count,
    d.total_unpaid_amount,
    ROUND(a.average_unpaid_amount, 2) AS average_unpaid_amount
FROM unpaid_debt_by_patient d
CROSS JOIN average_unpaid_debt a
WHERE d.total_unpaid_amount > a.average_unpaid_amount
ORDER BY d.total_unpaid_amount DESC;

/* ========================================================================
   Q09. Months where Telemedicine exceeds 30% of total appointment revenue
   Techniques: JOIN, conditional SUM, monthly GROUP BY, outer subquery filter.
   Only Completed appointments are treated as realized revenue.
   ======================================================================== */
WITH monthly_revenue AS (
    SELECT
        YEAR(a.appointment_date) AS revenue_year,
        MONTH(a.appointment_date) AS revenue_month,
        SUM(i.total_amount) AS total_monthly_revenue,
        SUM(
            CASE
                WHEN a.consultation_type = 'Telemedicine'
                THEN i.total_amount
                ELSE 0
            END
        ) AS telemedicine_revenue
    FROM APPOINTMENT a
    JOIN INVOICE i ON i.appointment_id = a.appointment_id
    WHERE a.status = 'Completed'
    GROUP BY YEAR(a.appointment_date), MONTH(a.appointment_date)
)
SELECT
    revenue_year,
    revenue_month,
    total_monthly_revenue,
    telemedicine_revenue,
    ROUND(100.0 * telemedicine_revenue / NULLIF(total_monthly_revenue, 0), 2)
        AS telemedicine_revenue_percentage
FROM monthly_revenue
WHERE telemedicine_revenue / NULLIF(total_monthly_revenue, 0) > 0.30
ORDER BY revenue_year, revenue_month;

/* ========================================================================
   Q10. VIP patients above the 80th percentile of total medical spending
   Techniques: multi-stage aggregation, JOINs, ROW_NUMBER, PERCENT_RANK.
   Spending = consultation fee + medicine cost for Completed appointments.
   The primary doctor is the doctor with the most completed visits for the
   patient; ties are resolved by the most recent appointment.
   ======================================================================== */
WITH consultation_spend AS (
    SELECT
        a.patient_id,
        SUM(
            CASE
                WHEN d.doctor_type = 'GP' THEN gp.consultation_fee
                WHEN d.doctor_type = 'Specialist' THEN sp.consultation_fee
                ELSE 0
            END
        ) AS consultation_total
    FROM APPOINTMENT a
    JOIN DOCTOR d ON d.doctor_id = a.doctor_id
    LEFT JOIN GENERAL_PRACTITIONER gp ON gp.doctor_id = d.doctor_id
    LEFT JOIN SPECIALIST sp ON sp.doctor_id = d.doctor_id
    WHERE a.status = 'Completed'
    GROUP BY a.patient_id
), medicine_spend AS (
    SELECT
        mr.patient_id,
        SUM(
            pi.quantity * COALESCE(
                pi.unit_price_at_prescription,
                m.unit_price
            )
        ) AS medicine_total
    FROM MEDICAL_RECORD mr
    JOIN DIGITAL_PRESCRIPTION dp ON dp.record_id = mr.record_id
    JOIN PRESCRIPTION_ITEM pi ON pi.prescription_id = dp.prescription_id
    JOIN MEDICINE m ON m.medicine_id = pi.medicine_id
    WHERE dp.status IN ('Issued', 'Dispensed')
    GROUP BY mr.patient_id
), patient_spending AS (
    SELECT
        p.patient_id,
        p.full_name AS patient_name,
        COALESCE(cs.consultation_total, 0)
            + COALESCE(ms.medicine_total, 0) AS total_medical_spending,
        COALESCE(cs.consultation_total, 0) AS consultation_total,
        COALESCE(ms.medicine_total, 0) AS medicine_total
    FROM PATIENT p
    LEFT JOIN consultation_spend cs ON cs.patient_id = p.patient_id
    LEFT JOIN medicine_spend ms ON ms.patient_id = p.patient_id
    WHERE cs.patient_id IS NOT NULL OR ms.patient_id IS NOT NULL
), ranked_doctors AS (
    SELECT
        a.patient_id,
        d.full_name AS doctor_name,
        COUNT(*) AS completed_visits,
        MAX(a.appointment_date) AS latest_visit_date,
        ROW_NUMBER() OVER (
            PARTITION BY a.patient_id
            ORDER BY COUNT(*) DESC, MAX(a.appointment_date) DESC, d.full_name
        ) AS doctor_rank
    FROM APPOINTMENT a
    JOIN DOCTOR d ON d.doctor_id = a.doctor_id
    WHERE a.status = 'Completed'
    GROUP BY a.patient_id, d.doctor_id, d.full_name
), percentile_spending AS (
    SELECT
        s.*,
        PERCENT_RANK() OVER (ORDER BY s.total_medical_spending) AS spending_percent_rank
    FROM patient_spending s
)
SELECT
    ps.patient_id,
    ps.patient_name,
    rd.doctor_name AS primary_treating_doctor,
    ps.consultation_total,
    ps.medicine_total,
    ps.total_medical_spending,
    ROUND(100.0 * ps.spending_percent_rank, 2) AS spending_percentile_rank
FROM percentile_spending ps
LEFT JOIN ranked_doctors rd
    ON rd.patient_id = ps.patient_id
   AND rd.doctor_rank = 1
WHERE ps.spending_percent_rank >= 0.80
ORDER BY ps.total_medical_spending DESC;
