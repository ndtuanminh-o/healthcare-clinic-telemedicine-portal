# Normalization Verification & Functional Dependency Analysis
## Formal Proofs for 1NF, 2NF, 3NF, and BCNF
### Topic 05: Healthcare Clinic & Telemedicine Management System | PTIT
**Course:** Database Systems (INT1313) - Semester 1, 2026-2027  
**Team:** G5 - Pingo  

---

## 1. Normalization Objectives & Formal Definitions

Normalization guarantees relational database integrity, eliminates data anomalies (insertion, update, deletion anomalies), and minimizes storage redundancy.

This verification provides formal mathematical proofs that all eleven (11) relational tables in the schema satisfy:
- **First Normal Form (1NF):** Every attribute domain contains only atomic (indivisible) values, and there are no repeating groups or multivalued attributes.
- **Second Normal Form (2NF):** The relation is in 1NF and every non-prime attribute is fully functionally dependent on the entire primary key (no partial functional dependencies).
- **Third Normal Form (3NF):** The relation is in 2NF and no non-prime attribute is transitively dependent on the primary key (for every functional dependency $X \rightarrow Y$, either $X$ is a superkey or $Y$ is a prime attribute).
- **Boyce-Codd Normal Form (BCNF):** For every non-trivial functional dependency $X \rightarrow Y$, $X$ must be a superkey.

---

## 2. Universal Functional Dependency (FD) Specification

Let $\mathcal{R}$ denote the set of relational schemas in the database. The table below specifies the candidate keys and functional dependencies for each relation:

| Relation | Candidate Key(s) | Non-Prime Attributes | Deterministic Functional Dependencies (FDs) | Normal Form Achieved |
| :--- | :--- | :--- | :--- | :---: |
| `DOCTOR` | {`doctor_id`}, {`license_no`} | `full_name`, `phone_number`, `email`, `doctor_type`, `status`, `deleted_at` | FD1: `doctor_id` $\rightarrow$ `full_name`, `license_no`, `phone_number`, `email`, `doctor_type`, `status`, `deleted_at`<br/>FD2: `license_no` $\rightarrow$ `doctor_id`, `full_name`, `phone_number`, `email`, `doctor_type`, `status`, `deleted_at` | **BCNF** |
| `GENERAL_PRACTITIONER` | {`doctor_id`} | `clinic_room_no`, `consultation_fee` | FD1: `doctor_id` $\rightarrow$ `clinic_room_no`, `consultation_fee` | **BCNF** |
| `SPECIALIST` | {`doctor_id`} | `specialty`, `consultation_fee`, `board_certified_year` | FD1: `doctor_id` $\rightarrow$ `specialty`, `consultation_fee`, `board_certified_year` | **BCNF** |
| `DOCTOR_SCHEDULE` | {`schedule_id`} | `doctor_id`, `work_date`, `start_time`, `end_time`, `slot_status` | FD1: `schedule_id` $\rightarrow$ `doctor_id`, `work_date`, `start_time`, `end_time`, `slot_status` | **BCNF** |
| `PATIENT` | {`patient_id`}, {`phone_number`} | `full_name`, `date_of_birth`, `gender`, `address`, `status`, `deleted_at` | FD1: `patient_id` $\rightarrow$ `full_name`, `date_of_birth`, `gender`, `phone_number`, `address`, `status`, `deleted_at`<br/>FD2: `phone_number` $\rightarrow$ `patient_id`, `full_name`, `date_of_birth`, `gender`, `address`, `status`, `deleted_at` | **BCNF** |
| `APPOINTMENT` | {`appointment_id`} | `patient_id`, `doctor_id`, `booking_time`, `appointment_date`, `start_time`, `end_time`, `consultation_type`, `telemedicine_video_link`, `status`, `reason_for_visit`, `deleted_at` | FD1: `appointment_id` $\rightarrow$ all attributes | **BCNF** |
| `MEDICAL_RECORD` | {`record_id`}, {`appointment_id`} | `patient_id`, `specialist_id`, `diagnosis`, `clinical_notes`, `treatment_plan`, `record_date`, `deleted_at` | FD1: `record_id` $\rightarrow$ all attributes<br/>FD2: `appointment_id` $\rightarrow$ `record_id`, `patient_id`, `specialist_id`, `diagnosis`, `clinical_notes`, `treatment_plan`, `record_date`, `deleted_at` | **BCNF** |
| `DIGITAL_PRESCRIPTION` | {`prescription_id`}, {`record_id`} | `issue_date`, `valid_until`, `instructions`, `status`, `deleted_at` | FD1: `prescription_id` $\rightarrow$ all attributes<br/>FD2: `record_id` $\rightarrow$ `prescription_id`, `issue_date`, `valid_until`, `instructions`, `status`, `deleted_at` | **BCNF** |
| `PRESCRIPTION_ITEM` | {`item_id`}, {`prescription_id`, `medicine_id`} | `dosage`, `frequency`, `duration_days`, `quantity` | FD1: `item_id` $\rightarrow$ all attributes<br/>FD2: {`prescription_id`, `medicine_id`} $\rightarrow$ `item_id`, `dosage`, `frequency`, `duration_days`, `quantity` | **BCNF** |
| `MEDICINE` | {`medicine_id`}, {`medicine_name`} | `active_ingredient`, `unit`, `unit_price`, `stock_quantity`, `reorder_level` | FD1: `medicine_id` $\rightarrow$ all attributes<br/>FD2: `medicine_name` $\rightarrow$ `medicine_id`, `active_ingredient`, `unit`, `unit_price`, `stock_quantity`, `reorder_level` | **BCNF** |
| `INVOICE` | {`invoice_id`}, {`appointment_id`} | `patient_id`, `issue_date`, `total_amount`, `payment_status`, `payment_method` | FD1: `invoice_id` $\rightarrow$ all attributes<br/>FD2: `appointment_id` $\rightarrow$ `invoice_id`, `patient_id`, `issue_date`, `total_amount`, `payment_status`, `payment_method` | **BCNF** |

---

## 3. Step-by-Step Formal Normalization Proofs

### 3.1. Verification of 1NF (Atomicity & Repeating Groups)
- **Criterion:** All attributes must store indivisible atomic values.
- **Verification:**
  - `APPOINTMENT`: Temporal intervals are stored in discrete atomic fields (`appointment_date`, `start_time`, `end_time`).
  - `PRESCRIPTION_ITEM`: Avoids composite medication arrays. Each row represents a single prescribed medication line item.
  - `PATIENT`: Gender is stored as single atomic enumeration code (`'M'`, `'F'`, `'O'`).
- **Conclusion:** All relations strictly satisfy **1NF**.

---

### 3.2. Verification of 2NF (Elimination of Partial Dependencies)
- **Criterion:** Every non-prime attribute must be fully functionally dependent on the candidate key. Partial dependency can only exist if candidate keys are composite.
- **Verification:**
  - Relations with single-attribute primary keys (`doctor_id`, `patient_id`, `schedule_id`, `appointment_id`, `record_id`, `prescription_id`, `item_id`, `medicine_id`, `invoice_id`) automatically satisfy 2NF because partial dependency on a single-column key is mathematically impossible.
  - For `PRESCRIPTION_ITEM`: Even with composite alternate key {`prescription_id`, `medicine_id`}, the attributes `dosage`, `frequency`, `duration_days`, and `quantity` depend on both the prescription order and the specific drug. No non-prime attribute depends solely on `prescription_id` or solely on `medicine_id`.
- **Conclusion:** All relations strictly satisfy **2NF**.

---

### 3.3. Verification of 3NF (Elimination of Transitive Dependencies)
- **Criterion:** For every functional dependency $X \rightarrow Y$, $X$ is a superkey, or $Y$ is a prime attribute.
- **Verification:**
  - In `APPOINTMENT`: `patient_id` and `doctor_id` are stored, but patient details (`full_name`, `phone_number`) and doctor details are not repeated here.
  - In `INVOICE`: `patient_id` is an audit reference. Total billing calculations are derived from consultation fees and medication lines, with no non-key attribute determining another non-key attribute.
  - In `PRESCRIPTION_ITEM`: Pharmaceutical details (`medicine_name`, `unit_price`) remain strictly in `MEDICINE`, preventing transitive dependency:
    `item_id` → `medicine_id` ↛ `unit_price` (non-prime attribute not duplicated in item table).
- **Conclusion:** All relations strictly satisfy **3NF**.

---

### 3.4. Verification of BCNF (Boyce-Codd Normal Form)
- **Criterion:** For every non-trivial functional dependency $X \rightarrow Y$, $X$ must be a superkey.
- **Verification:**
  - In `DOCTOR`: The only determinants are `doctor_id` and `license_no`. Both are candidate keys (superkeys).
  - In `PATIENT`: The only determinants are `patient_id` and `phone_number`. Both are candidate keys.
  - In `MEDICINE`: The only determinants are `medicine_id` and `medicine_name`. Both are candidate keys.
  - In `MEDICAL_RECORD`: Determinants are `record_id` and `appointment_id` (enforced by `UNIQUE` constraint). Both are candidate keys.
  - In `DIGITAL_PRESCRIPTION`: Determinants are `prescription_id` and `record_id` (enforced by `UNIQUE` constraint). Both are candidate keys.
  - In `INVOICE`: Determinants are `invoice_id` and `appointment_id` (enforced by `UNIQUE` constraint). Both are candidate keys.
- **Conclusion:** All 11 tables strictly achieve **BCNF**, completely eliminating data anomalies and redundant storage.
