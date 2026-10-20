## 1. Test status summary

| Query | Business function | Result rows | Status | 
|---|---|---:|---|---|
| Q01 | Telemedicine ratio by doctor | 60 | Pass | 
| Q02 | Doctors above average workload | 28 | Pass | 
| Q03 | Hybrid Care patients | 436 | Pass |
| Q04 | Specialties above average cancellation rate | 6 | Pass | 
| Q05 | Low-stock medicines in latest 14 days | 0 | Pass with note | 
| Q06 | Medicines above average monthly revenue | 12 | Pass | 
| Q07 | Polypharmacy prescriptions | 68 | Pass | 
| Q08 | Bad-debt risk by patient | 245 | Pass | 
| Q09 | Telemedicine revenue share by month | 1 | Pass with requirement note | 
| Q10 | VIP patients above the 80th percentile | 198 | Pass | 

## 2. Detailed test cases

## Q01 Telemedicine ratio by doctor

### Q01-TC01 Normal case

| Field | Description |
|---|---|
| Test Case ID | Q01-TC01 |
| Objective | Calculate the number and percentage of Telemedicine appointments for each doctor in the latest data month |
| Preconditions | Active doctors and appointments exist; the latest appointment month is available |
| Steps | Execute Q01 in MySQL Workbench and export the result to Q1.csv |
| Expected result | Each active doctor is returned with total non-cancelled appointments, Telemedicine appointments and a percentage between 0% and 100% |
| Actual result | 60 doctor rows were returned; percentage values range from 0.00% to 58.97% |
| Status | **Pass** |

### Manual validation

For BS. Trịnh Quốc Quân:

```text
Total non-cancelled appointments = 39
Telemedicine appointments = 23
Calculated ratio = 23 / 39 x 100 = 58.97%
Displayed ratio = 58.97%
```

The percentage calculation was consistent for all 60 rows in Q1.csv.

## Q02 Doctors above the clinic average workload

### Q02-TC01 Normal case

| Field | Description |
|---|---|
| Test Case ID | Q02-TC01 |
| Objective | Find active doctors whose appointment count is higher than the clinic-wide average |
| Preconditions | Active doctors and non-cancelled appointments exist in the latest data month |
| Steps | Execute Q02 and export the result to Q2.csv |
| Expected result | Every returned doctor has `appointment_count > clinic_average_appointments` |
| Actual result | 28 doctors were returned; the clinic average was 49.18 appointments and every returned count was greater than 49.18 |
| Status | **Pass** |

### Example validation

```text
BS. Mai Mai Thảo: 62 > 49.18
BS. Thái Tuấn Dũng: 61 > 49.18
BS. Vương Hữu Anh: 61 > 49.18
```

## Q03 Patients using Hybrid Care

### Q03-TC01 Normal case

| Field | Description |
|---|---|
| Test Case ID | Q03-TC01 |
| Objective | Find patients with both Telemedicine and In-Person appointments |
| Preconditions | Patients have at least two non-cancelled appointments |
| Steps | Execute Q03 and export the result to Q3.csv |
| Expected result | Every returned patient has at least two non-cancelled appointments and has both consultation types |
| Actual result | 436 patients were returned; the minimum number of non-cancelled appointments was 2 |
| Status | **Pass** |

### Q03-TC02 Boundary case

| Field | Description |
|---|---|
| Test Case ID | Q03-TC02 |
| Objective | Verify that patients with fewer than two appointments are excluded |
| Expected result | A patient with only one qualifying appointment does not appear |
| Actual result | The exported results contain no row with fewer than two non-cancelled appointments |
| Status | **Pass** |

## Q04 Specialties above the average cancellation rate

### Q04-TC01 Normal case

| Field | Description |
|---|---|
| Test Case ID | Q04-TC01 |
| Objective | Identify specialties whose cancellation percentage is higher than the clinic average |
| Preconditions | Appointment records have valid doctor and specialty relationships |
| Steps | Execute Q04 and export the result to Q4.csv |
| Expected result | Every returned specialty has `cancellation_percentage > clinic_average_cancellation_percentage` |
| Actual result | 6 specialties were returned; the clinic average was 7.78% and all returned specialties were above 7.78% |
| Status | **Pass** |

### Example validation

| Specialty | Cancellation rate | Clinic average | Validation |
|---|---:|---:|---|
| Hô hấp - Phổi | 9.58% | 7.78% | 9.58% > 7.78% |
| General Practice | 8.34% | 7.78% | 8.34% > 7.78% |
| Nhi khoa | 8.28% | 7.78% | 8.28% > 7.78% |

## Q05 Low-stock medicines

### Q05-TC01 Normal result with no alerts

| Field | Description |
|---|---|
| Test Case ID | Q05-TC01 |
| Objective | Find medicines whose current stock is lower than the prescribed quantity during the latest 14-day window |
| Preconditions | Medicines and issued or dispensed prescriptions exist |
| Steps | Execute Q05 and export the result to Q5.csv |
| Expected result | Only medicines satisfying `current_stock < prescribed_quantity_last_14_days` are returned |
| Actual result | The result contains 0 rows, meaning no medicine met the low-stock condition in the tested data window |
| Status | **Pass with note** |

The empty result is not a SQL failure. It means that no low-stock alert was found. For a stronger demonstration, the team may temporarily prepare one controlled medicine whose stock is lower than its recent prescription quantity, run Q05, and then restore the database.

## Q06 Medicines above average monthly revenue

### Q06-TC01 Normal case

| Field | Description |
|---|---|
| Test Case ID | Q06-TC01 |
| Objective | Find medicines whose revenue in the latest month is above the average revenue per medicine |
| Preconditions | Issued or dispensed prescriptions contain `unit_price_at_prescription` |
| Steps | Execute Q06 and export the result to Q6.csv |
| Expected result | Every returned medicine has revenue greater than the calculated average |
| Actual result | 12 medicines were returned; the average revenue was 854,438.10 and every returned medicine exceeded that value |
| Status | **Pass** |

### Example validation

```text
Lipitor 20mg: 5,649,000.00 > 854,438.10
Jardiance 10mg: 4,284,000.00 > 854,438.10
Crestor 10mg: 3,861,000.00 > 854,438.10
```

## Q07 Polypharmacy prescriptions

### Q07-TC01 Normal case

| Field | Description |
|---|---|
| Test Case ID | Q07-TC01 |
| Objective | Find prescriptions containing more distinct medicines than the clinic average |
| Preconditions | Non-cancelled digital prescriptions contain prescription items |
| Steps | Execute Q07 and export the result to Q7.csv |
| Expected result | Every returned prescription has a distinct medicine count greater than the clinic average |
| Actual result | 68 prescriptions were returned; the average was 1.90 distinct medicines and all returned prescriptions exceeded 1.90 |
| Status | **Pass** |

### Example validation

```text
Prescription 9afde817-...: 3 distinct medicines > 1.90 average
Prescription 87ffacec-...: 3 distinct medicines > 1.90 average
```

## Q08 Bad-debt risk by patient

### Q08-TC01 Normal case

| Field | Description |
|---|---|
| Test Case ID | Q08-TC01 |
| Objective | Find patients whose unpaid invoice total is above the average unpaid amount |
| Preconditions | Unpaid invoices exist for multiple patients |
| Steps | Execute Q08 and export the result to Q8.csv |
| Expected result | Every returned patient has `total_unpaid_amount > average_unpaid_amount` |
| Actual result | 245 patients were returned; the average unpaid amount was 240,416.67 and all returned patients exceeded that amount |
| Status | **Pass** |

### Example validation

| Patient | Unpaid invoices | Total unpaid | Average unpaid | Validation |
|---|---:|---:|---:|---|
| Hà Đình Thịnh | 3 | 900,000.00 | 240,416.67 | Pass |
| Hà Minh Quang | 5 | 850,000.00 | 240,416.67 | Pass |
| Thái Văn Trung | 3 | 800,000.00 | 240,416.67 | Pass |

## Q09 Telemedicine revenue share by month

### Q09-TC01 Normal case

| Field | Description |
|---|---|
| Test Case ID | Q09-TC01 |
| Objective | Find months where Telemedicine revenue exceeds the threshold defined in Q09 |
| Preconditions | Completed appointments have paid invoices |
| Steps | Execute Q09 and export the result to Q9.csv |
| Expected result | Returned months have Telemedicine revenue percentage greater than the SQL threshold |
| Actual result | September 2026 was returned with total revenue 1,245,559,100.00, Telemedicine revenue 363,107,100.00 and a ratio of 29.15% |
| Status | **Pass with requirement note** |

### Important requirement note

The current Q09 SQL uses:

```sql
WHERE telemedicine_revenue / NULLIF(total_monthly_revenue, 0) > 0.20
```

Therefore 29.15% correctly passes the current query. If the teacher's requirement is strictly **greater than 30%**, change the condition to `> 0.30` and rerun Q09. Under a 30% threshold, this September result would not be returned.

## Q10 VIP patients above the 80th percentile

### Q10-TC01 Normal case

| Field | Description |
|---|---|
| Test Case ID | Q10-TC01 |
| Objective | Find patients whose total medical spending is at or above the 80th percentile |
| Preconditions | Completed visits and prescription spending exist |
| Steps | Execute Q10 and export the result to Q10.csv |
| Expected result | Every returned patient has a spending percentile rank of at least 80.00 |
| Actual result | 198 patients were returned; percentile ranks ranged from 81.29 to 100.00 |
| Status | **Pass** |

### Example validation

```text
Dương Minh Tùng: total spending = 2,159,000.00; percentile = 100.00
Đào Phương Vân: total spending = 1,980,000.00; percentile = 99.91
Mai Ánh Hà: total spending = 1,928,000.00; percentile = 99.81
```




