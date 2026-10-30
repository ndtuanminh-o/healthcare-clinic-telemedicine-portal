USE healthcare_clinic_v2;

/* ========================================================================
   Q01. Telemedicine ratio for every doctor in the latest data month
   Techniques: CTE, LEFT JOIN, conditional aggregation.
   The month is aggregated first (date-range scan on the covering index), then
   joined to doctor. The correlated subquery of the original is removed.
   ======================================================================== */
WITH report_period AS (
    SELECT
        DATE_FORMAT(MAX(appointment_date), '%Y-%m-01') AS start_date,
        DATE_ADD(DATE_FORMAT(MAX(appointment_date), '%Y-%m-01'), INTERVAL 1 MONTH) AS end_date
    FROM appointment
    WHERE deleted_at IS NULL
),
month_stats AS (
    SELECT
        a.doctor_id,
        COUNT(*) AS total_appointments,
        SUM(CASE WHEN a.consultation_type = 'Telemedicine' THEN 1 ELSE 0 END)
            AS telemedicine_appointments
    FROM appointment a
    JOIN report_period rp
      ON a.appointment_date >= rp.start_date
     AND a.appointment_date < rp.end_date
    WHERE a.status <> 'Cancelled'
      AND a.deleted_at IS NULL
    GROUP BY a.doctor_id
)
SELECT
    d.doctor_id,
    d.full_name AS doctor_name,
    d.doctor_type,
    COALESCE(m.total_appointments, 0) AS total_non_cancelled_appointments,
    COALESCE(m.telemedicine_appointments, 0) AS telemedicine_appointments,
    ROUND(
        100.0 * COALESCE(m.telemedicine_appointments, 0) / NULLIF(m.total_appointments, 0),
        2
    ) AS telemedicine_percentage
FROM doctor d
LEFT JOIN month_stats m ON m.doctor_id = d.doctor_id
WHERE d.deleted_at IS NULL
ORDER BY telemedicine_percentage DESC, total_non_cancelled_appointments DESC;

/* ========================================================================
   Q02. Doctors whose workload is above the clinic-wide average
   Techniques: JOIN, aggregation, CTE, subquery filter.
   Average is taken over active, non-deleted doctors only.
   ======================================================================== */
WITH report_period AS (
    SELECT
        DATE_FORMAT(MAX(appointment_date), '%Y-%m-01') AS start_date,
        DATE_ADD(DATE_FORMAT(MAX(appointment_date), '%Y-%m-01'), INTERVAL 1 MONTH) AS end_date
    FROM appointment
    WHERE deleted_at IS NULL
),
doctor_workload AS (
    SELECT
        d.doctor_id,
        d.full_name AS doctor_name,
        d.doctor_type,
        COALESCE(m.appointment_count, 0) AS appointment_count
    FROM doctor d
    LEFT JOIN (
        SELECT a.doctor_id, COUNT(*) AS appointment_count
        FROM appointment a
        JOIN report_period rp
          ON a.appointment_date >= rp.start_date
         AND a.appointment_date < rp.end_date
        WHERE a.status <> 'Cancelled'
          AND a.deleted_at IS NULL
        GROUP BY a.doctor_id
    ) m ON m.doctor_id = d.doctor_id
    WHERE d.status = 'Active'
      AND d.deleted_at IS NULL
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
FROM patient p
JOIN appointment a ON a.patient_id = p.patient_id
WHERE a.status <> 'Cancelled'
  AND a.deleted_at IS NULL
  AND p.deleted_at IS NULL
GROUP BY p.patient_id, p.full_name
HAVING COUNT(a.appointment_id) >= 2
   AND EXISTS (
       SELECT 1
       FROM appointment a_online
       WHERE a_online.patient_id = p.patient_id
         AND a_online.consultation_type = 'Telemedicine'
         AND a_online.status <> 'Cancelled'
         AND a_online.deleted_at IS NULL
   )
   AND EXISTS (
       SELECT 1
       FROM appointment a_in_person
       WHERE a_in_person.patient_id = p.patient_id
         AND a_in_person.consultation_type = 'In-Person'
         AND a_in_person.status <> 'Cancelled'
         AND a_in_person.deleted_at IS NULL
   )
ORDER BY non_cancelled_appointments DESC, patient_name;

/* ========================================================================
   Q04. Specialties with an above-average cancellation rate (all-time scope)
   Techniques: JOIN, CASE aggregation, window totals.
   The clinic-wide rate comes from window sums over the grouped result, so
   appointment is scanned once instead of twice.
   ======================================================================== */
WITH doctor_specialty AS (
    SELECT
        d.doctor_id,
        CASE
            WHEN d.doctor_type = 'Specialist' THEN COALESCE(sp.specialty, 'Unknown')
            ELSE 'General Practice'
        END AS specialty
    FROM doctor d
    LEFT JOIN specialist sp ON sp.doctor_id = d.doctor_id
), specialty_stats AS (
    SELECT
        ds.specialty,
        COUNT(a.appointment_id) AS total_appointments,
        SUM(CASE WHEN a.status = 'Cancelled' THEN 1 ELSE 0 END)
            AS cancelled_appointments
    FROM doctor_specialty ds
    JOIN appointment a ON a.doctor_id = ds.doctor_id
    WHERE a.deleted_at IS NULL
    GROUP BY ds.specialty
), with_clinic_rate AS (
    SELECT
        s.*,
        SUM(s.cancelled_appointments) OVER () * 1.0
            / NULLIF(SUM(s.total_appointments) OVER (), 0) AS clinic_cancellation_rate
    FROM specialty_stats s
)
SELECT
    w.specialty,
    w.total_appointments,
    w.cancelled_appointments,
    ROUND(100.0 * w.cancelled_appointments / NULLIF(w.total_appointments, 0), 2)
        AS cancellation_percentage,
    ROUND(100.0 * w.clinic_cancellation_rate, 2)
        AS clinic_average_cancellation_percentage
FROM with_clinic_rate w
WHERE 1.0 * w.cancelled_appointments / NULLIF(w.total_appointments, 0)
      > w.clinic_cancellation_rate
ORDER BY cancellation_percentage DESC, w.specialty;

/* ========================================================================
   Q05. Stock-risk alert based on consumption during the latest 14 days
   Techniques: JOIN, SUM in a CTE, comparison with current stock.
   Alert when current stock covers fewer days than the 14-day window, i.e.
   stock < quantity prescribed in the window. days_of_cover is added for
   readability.
   ======================================================================== */
WITH latest AS (
    SELECT MAX(issue_date) AS max_issue_date
    FROM digital_prescription
    WHERE deleted_at IS NULL
), consumption_last_14_days AS (
    SELECT
        pi.medicine_id,
        SUM(pi.quantity) AS prescribed_quantity_last_14_days
    FROM prescription_item pi
    JOIN digital_prescription dp
        ON dp.prescription_id = pi.prescription_id
    CROSS JOIN latest l
    WHERE dp.status IN ('Issued', 'Dispensed')
      AND dp.deleted_at IS NULL
      AND dp.issue_date >= DATE_SUB(l.max_issue_date, INTERVAL 14 DAY)
      AND dp.issue_date <= l.max_issue_date
    GROUP BY pi.medicine_id
)
SELECT
    m.medicine_id,
    m.medicine_name,
    m.stock_quantity AS current_stock,
    c.prescribed_quantity_last_14_days,
    m.reorder_level,
    m.stock_quantity - c.prescribed_quantity_last_14_days
        AS stock_minus_recent_consumption,
    ROUND(m.stock_quantity / (c.prescribed_quantity_last_14_days / 14.0), 1)
        AS days_of_cover
FROM medicine m
JOIN consumption_last_14_days c ON c.medicine_id = m.medicine_id
WHERE m.stock_quantity < c.prescribed_quantity_last_14_days
ORDER BY stock_minus_recent_consumption ASC, m.medicine_name;

/* ========================================================================
   Q06. Medicines with monthly revenue above the average medicine revenue
   Techniques: JOIN, SUM, CTE, AVG subquery.
   unit_price_at_prescription is NOT NULL, so the old COALESCE is removed.
   ======================================================================== */
WITH report_period AS (
    SELECT
        DATE_FORMAT(MAX(appointment_date), '%Y-%m-01') AS start_date,
        DATE_ADD(DATE_FORMAT(MAX(appointment_date), '%Y-%m-01'), INTERVAL 1 MONTH) AS end_date
    FROM appointment
    WHERE deleted_at IS NULL
),
medicine_monthly_revenue AS (
    SELECT
        m.medicine_id,
        m.medicine_name,
        SUM(pi.quantity * pi.unit_price_at_prescription) AS total_medicine_revenue
    FROM medicine m
    JOIN prescription_item pi ON pi.medicine_id = m.medicine_id
    JOIN digital_prescription dp
        ON dp.prescription_id = pi.prescription_id
    JOIN report_period rp
      ON dp.issue_date >= rp.start_date
     AND dp.issue_date < rp.end_date
    WHERE dp.status IN ('Issued', 'Dispensed')
      AND dp.deleted_at IS NULL
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
   Techniques: COUNT(DISTINCT), GROUP BY, CTE average.
   Items are aggregated first; patient and record are joined only for the
   final result.
   ======================================================================== */
WITH item_counts AS (
    SELECT
        pi.prescription_id,
        COUNT(DISTINCT pi.medicine_id) AS distinct_medicine_count
    FROM prescription_item pi
    JOIN digital_prescription dp ON dp.prescription_id = pi.prescription_id
    WHERE dp.status <> 'Cancelled'
      AND dp.deleted_at IS NULL
    GROUP BY pi.prescription_id
), average_prescription_size AS (
    SELECT AVG(distinct_medicine_count) AS average_distinct_medicines
    FROM item_counts
)
SELECT
    ic.prescription_id,
    mr.patient_id,
    p.full_name AS patient_name,
    dp.issue_date,
    ic.distinct_medicine_count,
    ROUND(a.average_distinct_medicines, 2)
        AS clinic_average_distinct_medicines
FROM item_counts ic
CROSS JOIN average_prescription_size a
JOIN digital_prescription dp ON dp.prescription_id = ic.prescription_id
JOIN medical_record mr ON mr.record_id = dp.record_id
JOIN patient p ON p.patient_id = mr.patient_id
WHERE ic.distinct_medicine_count > a.average_distinct_medicines
ORDER BY ic.distinct_medicine_count DESC, dp.issue_date DESC;

/* ========================================================================
   Q08. Bad-debt risk by patient
   Techniques: JOIN, SUM, CTE for average debt.
   Debt of soft-deleted patients is deliberately kept: it is still owed.
   For partial payments, subtract SUM(payment.amount) per invoice.
   ======================================================================== */
WITH unpaid_debt_by_patient AS (
    SELECT
        p.patient_id,
        p.full_name AS patient_name,
        COUNT(i.invoice_id) AS unpaid_invoice_count,
        SUM(i.total_amount) AS total_unpaid_amount
    FROM patient p
    JOIN invoice i ON i.patient_id = p.patient_id
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
   Q09. Months where Telemedicine exceeds 20% of realised appointment revenue
   Techniques: JOIN, conditional SUM, monthly GROUP BY, CTE filter.
   Realised revenue = Completed appointments with a Paid invoice (Unpaid and
   Refunded invoices are no longer counted).
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
    FROM appointment a
    JOIN invoice i ON i.appointment_id = a.appointment_id
    WHERE a.status = 'Completed'
      AND a.deleted_at IS NULL
      AND i.payment_status = 'Paid'
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
WHERE telemedicine_revenue / NULLIF(total_monthly_revenue, 0) > 0.20
ORDER BY revenue_year, revenue_month;

/* ========================================================================
   Q10. VIP patients above the 80th percentile of total medical spending
   Techniques: multi-stage aggregation, JOINs, ROW_NUMBER, PERCENT_RANK.
   Spending = consultation fee + medicine cost, both for Completed visits.
   appointment is scanned once (patient x doctor), then reused for the fee
   total and for the primary doctor.
   LIMITATION: the fee is the doctor's CURRENT fee because the schema does not
   store the fee at visit time. Add a fee snapshot to invoice (see README).
   ======================================================================== */
WITH doctor_fee AS (
    SELECT
        d.doctor_id,
        d.full_name,
        COALESCE(gp.consultation_fee, sp.consultation_fee, 0) AS fee
    FROM doctor d
    LEFT JOIN general_practitioner gp ON gp.doctor_id = d.doctor_id
    LEFT JOIN specialist sp ON sp.doctor_id = d.doctor_id
), patient_doctor AS (
    SELECT
        a.patient_id,
        a.doctor_id,
        COUNT(*) AS visits,
        MAX(a.appointment_date) AS last_visit
    FROM appointment a
    WHERE a.status = 'Completed'
      AND a.deleted_at IS NULL
    GROUP BY a.patient_id, a.doctor_id
), consultation_spend AS (
    SELECT
        pd.patient_id,
        SUM(pd.visits * df.fee) AS consultation_total
    FROM patient_doctor pd
    JOIN doctor_fee df ON df.doctor_id = pd.doctor_id
    GROUP BY pd.patient_id
), ranked_doctors AS (
    SELECT
        pd.patient_id,
        df.full_name AS doctor_name,
        ROW_NUMBER() OVER (
            PARTITION BY pd.patient_id
            ORDER BY pd.visits DESC, pd.last_visit DESC, df.full_name
        ) AS doctor_rank
    FROM patient_doctor pd
    JOIN doctor_fee df ON df.doctor_id = pd.doctor_id
), medicine_spend AS (
    SELECT
        mr.patient_id,
        SUM(pi.quantity * pi.unit_price_at_prescription) AS medicine_total
    FROM medical_record mr
    JOIN appointment a
        ON a.appointment_id = mr.appointment_id
       AND a.status = 'Completed'
       AND a.deleted_at IS NULL
    JOIN digital_prescription dp ON dp.record_id = mr.record_id
    JOIN prescription_item pi ON pi.prescription_id = dp.prescription_id
    WHERE dp.status IN ('Issued', 'Dispensed')
      AND dp.deleted_at IS NULL
      AND mr.deleted_at IS NULL
    GROUP BY mr.patient_id
), patient_spending AS (
    SELECT
        p.patient_id,
        p.full_name AS patient_name,
        COALESCE(cs.consultation_total, 0) AS consultation_total,
        COALESCE(ms.medicine_total, 0) AS medicine_total,
        COALESCE(cs.consultation_total, 0)
            + COALESCE(ms.medicine_total, 0) AS total_medical_spending
    FROM patient p
    LEFT JOIN consultation_spend cs ON cs.patient_id = p.patient_id
    LEFT JOIN medicine_spend ms ON ms.patient_id = p.patient_id
    WHERE p.deleted_at IS NULL
      AND (cs.patient_id IS NOT NULL OR ms.patient_id IS NOT NULL)
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
