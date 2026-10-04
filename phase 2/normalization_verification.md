# Normalization Verification & Functional Dependency Analysis
## Formal Proofs for 1NF, 2NF, 3NF
### Topic 05: Healthcare Clinic & Telemedicine Management System | PTIT
**Project:** Clinic Management & Telemedicine Portal | **Team:** G5 - Pingo  

---

## 1. Normalization Objectives & Formal Definitions

This verification provides formal mathematical proofs that all relations in the Healthcare Clinic & Telemedicine Portal system adhere to relational design quality rules up to Third Normal Form (3NF). Normalization eliminates data redundancy and prevents insertion, update, and deletion anomalies.

**First Normal Form (1NF):** Every attribute domain contains only atomic (indivisible) values, and there are no repeating groups or multivalued attributes.

**Second Normal Form (2NF):** The relation is in 1NF, and every non-prime attribute is fully functionally dependent on the entire primary key (no partial functional dependencies).

**Third Normal Form (3NF):** The relation is in 2NF, and no non-prime attribute is transitively dependent on the primary key. For every functional dependency $X \rightarrow Y$, either $X$ is a superkey or $Y$ is a prime attribute.

---

## 2. Universal Functional Dependency (FD) Specification

Let $\mathcal{R}$ denote the set of relational schemas in the database. The table below specifies the candidate keys, non-prime attributes, functional dependencies, and normal forms achieved for each relation up to **Third Normal Form (3NF)**:

| Relation | Candidate Key(s) | Non-Prime Attributes | Deterministic Functional Dependencies (FDs) | Normal Form Achieved |
| :--- | :--- | :--- | :--- | :---: |
| `DOCTOR` | {`doctor_id`}, {`license_no`} | `full_name`, `phone_number`, `email`, `doctor_type`, `status`, `deleted_at` | FD1: `doctor_id` $\rightarrow$ `full_name`, `license_no`, `phone_number`, `email`, `doctor_type`, `status`, `deleted_at`<br>FD2: `license_no` $\rightarrow$ `doctor_id`, `full_name`, `phone_number`, `email`, `doctor_type`, `status`, `deleted_at` | **3NF** |
| `GENERAL_PRACTITIONER` | {`doctor_id`} | `clinic_room_no`, `consultation_fee` | FD1: `doctor_id` $\rightarrow$ `clinic_room_no`, `consultation_fee` | **3NF** |
| `SPECIALIST` | {`doctor_id`} | `specialty`, `consultation_fee`, `board_certified_year` | FD1: `doctor_id` $\rightarrow$ `specialty`, `consultation_fee`, `board_certified_year` | **3NF** |
| `DOCTOR_SCHEDULE` | {`schedule_id`} | `doctor_id`, `work_date`, `start_time`, `end_time`, `slot_status` | FD1: `schedule_id` $\rightarrow$ `doctor_id`, `work_date`, `start_time`, `end_time`, `slot_status` | **3NF** |
| `PATIENT` | {`patient_id`}, {`phone_number`} | `full_name`, `date_of_birth`, `gender`, `address`, `status`, `deleted_at` | FD1: `patient_id` $\rightarrow$ `full_name`, `date_of_birth`, `gender`, `phone_number`, `address`, `status`, `deleted_at`<br>FD2: `phone_number` $\rightarrow$ `patient_id`, `full_name`, `date_of_birth`, `gender`, `address`, `status`, `deleted_at` | **3NF** |
| `APPOINTMENT` | {`appointment_id`} | `patient_id`, `doctor_id`, `booking_time`, `appointment_date`, `start_time`, `end_time`, `consultation_type`, `telemedicine_video_link`, `status`, `reason_for_visit`, `deleted_at` | FD1: `appointment_id` $\rightarrow$ `patient_id`, `doctor_id`, `booking_time`, `appointment_date`, `start_time`, `end_time`, `consultation_type`, `telemedicine_video_link`, `status`, `reason_for_visit`, `deleted_at` | **3NF** |
| `MEDICAL_RECORD` | {`record_id`}, {`appointment_id`} | `patient_id`, `specialist_id`, `diagnosis`, `clinical_notes`, `treatment_plan`, `record_date`, `deleted_at` | FD1: `record_id` $\rightarrow$ `appointment_id`, `patient_id`, `specialist_id`, `diagnosis`, `clinical_notes`, `treatment_plan`, `record_date`, `deleted_at`<br>FD2: `appointment_id` $\rightarrow$ `record_id`, `patient_id`, `specialist_id`, `diagnosis`, `clinical_notes`, `treatment_plan`, `record_date`, `deleted_at` | **3NF** |
| `DIGITAL_PRESCRIPTION` | {`prescription_id`}, {`record_id`} | `issue_date`, `valid_until`, `instructions`, `status`, `deleted_at` | FD1: `prescription_id` $\rightarrow$ `record_id`, `issue_date`, `valid_until`, `instructions`, `status`, `deleted_at`<br>FD2: `record_id` $\rightarrow$ `prescription_id`, `issue_date`, `valid_until`, `instructions`, `status`, `deleted_at` | **3NF** |
| `PRESCRIPTION_ITEM` | {`item_id`}, {`prescription_id`, `medicine_id`} | `dosage`, `frequency`, `duration_days`, `quantity` | FD1: `item_id` $\rightarrow$ `prescription_id`, `medicine_id`, `dosage`, `frequency`, `duration_days`, `quantity`<br>FD2: {`prescription_id`, `medicine_id`} $\rightarrow$ `item_id`, `dosage`, `frequency`, `duration_days`, `quantity` | **3NF** |
| `MEDICINE` | {`medicine_id`}, {`medicine_name`} | `active_ingredient`, `unit`, `unit_price`, `stock_quantity`, `reorder_level` | FD1: `medicine_id` $\rightarrow$ `active_ingredient`, `unit`, `unit_price`, `stock_quantity`, `reorder_level`<br>FD2: `medicine_name` $\rightarrow$ `medicine_id`, `active_ingredient`, `unit`, `unit_price`, `stock_quantity`, `reorder_level` | **3NF** |
| `INVOICE` | {`invoice_id`}, {`appointment_id`} | `patient_id`, `issue_date`, `total_amount`, `payment_status`, `payment_method` | FD1: `invoice_id` $\rightarrow$ `appointment_id`, `patient_id`, `issue_date`, `total_amount`, `payment_status`, `payment_method`<br>FD2: `appointment_id` $\rightarrow$ `invoice_id`, `patient_id`, `issue_date`, `total_amount`, `payment_status`, `payment_method` | **3NF** |

---

## 3. Step-by-Step Formal Normalization Proofs

### 3.1 Verification of 1NF (Atomicity and Repeating Groups)

- **Criterion:** All attributes must store indivisible atomic values, with no repeating groups or composite arrays.
- **Verification:**
  - `APPOINTMENT`: Temporal intervals are stored in discrete atomic fields (`appointment_date`, `start_time`, `end_time`).
  - `PRESCRIPTION_ITEM`: Avoids composite medication arrays. Each row represents a single prescribed medication line item.
  - `PATIENT`: Gender is stored as a single atomic enumeration code (`'M'`, `'F'`, `'O'`).
- **Conclusion:** All relations strictly satisfy **1NF**.

---

### 3.2 Verification of 2NF (Elimination of Partial Dependencies)

- **Criterion:** Every non-prime attribute must be fully functionally dependent on the primary or candidate key. Partial dependency can only exist if candidate keys are composite.
- **Verification:**
  - Relations with single-attribute primary keys (`doctor_id`, `patient_id`, `schedule_id`, `appointment_id`, `record_id`, `prescription_id`, `item_id`, `medicine_id`, `invoice_id`) automatically satisfy 2NF because partial dependency on a single-column key is mathematically impossible.
  - For `PRESCRIPTION_ITEM`: Even with the composite alternate key {`prescription_id`, `medicine_id`}, the attributes `dosage`, `frequency`, `duration_days`, and `quantity` depend on both the prescription order and the specific drug. No non-prime attribute depends solely on a subset of the key.
- **Conclusion:** All relations strictly satisfy **2NF**.

---

### 3.3 Verification of 3NF (Elimination of Transitive Dependencies)

- **Criterion:** For every functional dependency $X \rightarrow Y$, $X$ is a superkey or $Y$ is a prime attribute. Therefore, no non-prime attribute is transitively dependent on any key.
- **Verification:**
  - In `APPOINTMENT`: `patient_id` and `doctor_id` are stored as foreign keys, while patient details (`full_name`, `phone_number`) and doctor details remain strictly in `PATIENT` and `DOCTOR`, preventing transitive dependencies.
  - In `INVOICE`: `patient_id` serves as an audit reference. Total billing calculations are derived without any non-key attribute determining another non-key attribute.
  - In `PRESCRIPTION_ITEM`: Pharmaceutical details (`medicine_name`, `unit_price`) remain strictly in `MEDICINE`, avoiding transitive dependency (`item_id` $\rightarrow$ `medicine_id` $\not\rightarrow$ `unit_price`).
  - In relations with candidate keys (`DOCTOR`, `PATIENT`, `MEDICINE`, `MEDICAL_RECORD`, `DIGITAL_PRESCRIPTION`, `INVOICE`), all non-prime attributes depend directly on a candidate key without intermediate non-key attributes.
- **Conclusion:** All 11 relations strictly achieve **3NF**, completely eliminating insertion, update, and deletion anomalies while preserving all functional dependencies and maintaining high query performance.
