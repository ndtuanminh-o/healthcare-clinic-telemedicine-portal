[3_Data_Dictionary.md](https://github.com/user-attachments/files/32012127/3_Data_Dictionary_ISO11179_EN.md)

#Data Dictionary (Adapted from ISO/IEC 11179)

The Data Dictionary provides comprehensive metadata specifications for all eleven (11) entities and relations designed in Phase 1 (Conceptual and Logical Relational Schema), adhering to the international metadata standard **ISO/IEC 11179**. 

Each entity is documented using a standardized 6-column specification:
* **Attribute Name:** Physical column attribute identifier.
* **Data Type:** Physical storage domain specification (UUID, VARCHAR, DECIMAL, etc.).
* **Key Type:** Relational key designation (`PK` = Primary Key, `FK` = Foreign Key, `UQ` = Unique Alternate Key).
* **Nullable:** Nullability constraint (`No` = NOT NULL, `Yes` = Nullable).
* **Default Value:** Pre-assigned initial default value or generation expression.
* **Integrity & Business Rules:** Formal semantic definition, domain rules, integrity checks, and foreign key references.

---

## 3.1 Entity: DOCTOR (Superclass)
Base entity storing identity credentials, licensing information, and operational state for all registered medical practitioners.

| Attribute Name | Data Type | Key Type | Nullable | Default Value | Integrity & Business Rules |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `doctor_id` | UUID / CHAR(36) | PK | No | `GEN_RANDOM_UUID()` | Primary surrogate identifier. Global UUID across all specialization subclasses. |
| `full_name` | VARCHAR(100) | - | No | None | Full legal practitioner name. Cannot be empty. |
| `license_no` | VARCHAR(30) | UQ | No | None | Ministry of Health medical practice license number. Globally unique. |
| `phone_number` | VARCHAR(15) | - | No | None | Official clinic contact telephone number. |
| `email` | VARCHAR(100) | - | Yes | NULL | Official practitioner hospital email address. |
| `doctor_type` | ENUM('GP', 'Specialist') | - | No | None | Specialization discriminator enforcing disjoint EER hierarchy. |
| `status` | ENUM('Active', 'Inactive') | - | No | 'Active' | Medical practitioner operational and employment lifecycle state. |
| `deleted_at` | DATETIME | - | Yes | NULL | Non-destructive soft-delete audit timestamp (ISO/IEC 29148 regulatory retention). |

---

## 3.2 Entity: GENERAL_PRACTITIONER (Subclass)
Subclass inheriting from `DOCTOR`, managing physical on-premise consultations and outpatient clinic rooms.

| Attribute Name | Data Type | Key Type | Nullable | Default Value | Integrity & Business Rules |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `doctor_id` | UUID / CHAR(36) | PK, FK | No | None | References `DOCTOR(doctor_id)`. 1:1 identity inheritance mapping (Option 8.4a). |
| `clinic_room_no` | VARCHAR(20) | - | No | None | Assigned physical consultation room identifier (e.g., 'Room 102', 'Clinic-A'). |
| `consultation_fee` | DECIMAL(10,2) | - | No | 150000.00 | Base outpatient physical consultation charge. Constraint: `CHECK (consultation_fee > 0)`. |

---

## 3.3 Entity: SPECIALIST (Subclass)
Subclass inheriting from `DOCTOR`, managing specialized clinical departments and remote telemedicine encounters.

| Attribute Name | Data Type | Key Type | Nullable | Default Value | Integrity & Business Rules |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `doctor_id` | UUID / CHAR(36) | PK, FK | No | None | References `DOCTOR(doctor_id)`. 1:1 identity inheritance mapping (Option 8.4a). |
| `specialty` | VARCHAR(50) | - | No | None | Clinical specialty domain (e.g., Cardiology, Neurology, Dermatology). |
| `consultation_fee` | DECIMAL(10,2) | - | No | 300000.00 | Specialist & telemedicine consultation rate. Constraint: `CHECK (consultation_fee > 0)`. |
| `board_certified_year`| INT | - | No | None | Year medical board certification was awarded. Constraint: `CHECK (board_certified_year <= EXTRACT(YEAR FROM CURRENT_DATE))`. |

---

## 3.4 Entity: DOCTOR_SCHEDULE
Manages scheduled duty shifts, on-call slots, and calendar availability for clinical staff.

| Attribute Name | Data Type | Key Type | Nullable | Default Value | Integrity & Business Rules |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `schedule_id` | UUID / CHAR(36) | PK | No | `GEN_RANDOM_UUID()` | Primary surrogate identifier for doctor working schedule slot. |
| `doctor_id` | UUID / CHAR(36) | FK | No | None | Foreign key referencing `DOCTOR(doctor_id)`. |
| `work_date` | DATE | - | No | None | Calendar date of scheduled shift. |
| `start_time` | TIME | - | No | None | Shift commencement time. |
| `end_time` | TIME | - | No | None | Shift conclusion time. Constraint: `CHECK (end_time > start_time)`. |
| `slot_status` | ENUM('Available', 'Booked', 'Blocked') | - | No | 'Available' | Real-time booking availability state for appointment allocation. |

---

## 3.5 Entity: PATIENT
Stores demographic profiles, medical contact identities, and account status for registered clinic patients.

| Attribute Name | Data Type | Key Type | Nullable | Default Value | Integrity & Business Rules |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `patient_id` | UUID / CHAR(36) | PK | No | `GEN_RANDOM_UUID()` | Primary surrogate identifier for registered patient profile. |
| `full_name` | VARCHAR(100) | - | No | None | Legal full name of patient. Cannot be blank. |
| `date_of_birth` | DATE | - | No | None | Patient date of birth. Constraint: `CHECK (date_of_birth <= CURRENT_DATE)`. |
| `gender` | ENUM('M', 'F', 'O') | - | Yes | 'O' | Clinical demographic gender identification ('M' = Male, 'F' = Female, 'O' = Other). |
| `phone_number` | VARCHAR(15) | UQ | No | None | Primary mobile contact phone number. Globally unique for patient identity verification. |
| `address` | VARCHAR(255) | - | Yes | NULL | Residential mailing and prescription home delivery address. |
| `status` | ENUM('Active', 'Inactive') | - | No | 'Active' | Patient portal registration and record activity flag. |
| `deleted_at` | DATETIME | - | Yes | NULL | Soft-delete retention timestamp for healthcare data audit compliance. |

---

## 3.6 Entity: APPOINTMENT
Central coordinator for both in-person physical clinical consultations and virtual telemedicine sessions.

| Attribute Name | Data Type | Key Type | Nullable | Default Value | Integrity & Business Rules |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `appointment_id` | UUID / CHAR(36) | PK | No | `GEN_RANDOM_UUID()` | Primary surrogate appointment reservation token. |
| `patient_id` | UUID / CHAR(36) | FK | No | None | Foreign key referencing `PATIENT(patient_id)`. |
| `doctor_id` | UUID / CHAR(36) | FK | No | None | Foreign key referencing `DOCTOR(doctor_id)`. |
| `booking_time` | DATETIME | - | No | `CURRENT_TIMESTAMP` | Timestamp when appointment reservation was officially recorded. |
| `appointment_date` | DATE | - | No | None | Scheduled calendar date of consultation encounter. |
| `start_time` | TIME | - | No | None | Scheduled session start time. |
| `end_time` | TIME | - | No | None | Scheduled session end time. Constraint: `CHECK (end_time > start_time)`. |
| `consultation_type`| ENUM('In-Person', 'Telemedicine') | - | No | 'In-Person' | Care delivery channel modality. |
| `status` | ENUM('Scheduled', 'In-Progress', 'Completed', 'Cancelled') | - | No | 'Scheduled' | Operational state machine progression flag (BR-03). |
| `telemedicine_video_link` | TEXT | - | Yes | NULL | Encrypted video portal URL. Mandatory when `consultation_type = 'Telemedicine'` and status moves to `In-Progress` (BR-05). |
| `reason_for_visit` | TEXT | - | Yes | NULL | Patient chief complaint or initial symptoms recorded upon intake. |
| `deleted_at` | DATETIME | - | Yes | NULL | Soft-delete audit retention timestamp. |

---

## 3.7 Entity: MEDICAL_RECORD
Official diagnostic ledger, physical exam notes, and clinical documentation created during consultation encounters.

| Attribute Name | Data Type | Key Type | Nullable | Default Value | Integrity & Business Rules |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `record_id` | UUID / CHAR(36) | PK | No | `GEN_RANDOM_UUID()` | Primary surrogate identifier for clinical consultation encounter record. |
| `appointment_id` | UUID / CHAR(36) | FK, UQ | No | None | Foreign key referencing `APPOINTMENT(appointment_id)`. `UNIQUE` enforces strict 1:0..1 constraint per encounter. |
| `patient_id` | UUID / CHAR(36) | FK | No | None | Foreign key referencing `PATIENT(patient_id)`. |
| `specialist_id` | UUID / CHAR(36) | FK | Yes | NULL | Optional attending specialist physician referencing `SPECIALIST(doctor_id)`. |
| `diagnosis` | TEXT | - | No | None | Formal clinical ICD diagnostic summary. Cannot be null (BR-06). |
| `clinical_notes` | TEXT | - | Yes | NULL | Physician clinical observation findings and anamnesis notes. |
| `treatment_plan` | TEXT | - | Yes | NULL | Prescribed non-pharmacological therapy regimen and follow-up guidance. |
| `record_date` | DATETIME | - | No | `CURRENT_TIMESTAMP` | Timestamp when diagnostic record was entered and signed. |
| `deleted_at` | DATETIME | - | Yes | NULL | Soft-delete audit retention flag. |

---

## 3.8 Entity: DIGITAL_PRESCRIPTION
Pharmaceutical prescription authorization issued by attending medical staff upon conclusion of diagnostic encounters.

| Attribute Name | Data Type | Key Type | Nullable | Default Value | Integrity & Business Rules |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `prescription_id` | UUID / CHAR(36) | PK | No | `GEN_RANDOM_UUID()` | Primary surrogate identifier for electronic prescription order. |
| `record_id` | UUID / CHAR(36) | FK, UQ | No | None | References `MEDICAL_RECORD(record_id)`. `UNIQUE` enforces at most one prescription per medical record (BR-07). |
| `issue_date` | DATETIME | - | No | `CURRENT_TIMESTAMP` | Timestamp when prescription authorization was issued. |
| `valid_until` | DATE | - | No | None | Legal prescription validity expiry date. Must be `>= issue_date`. |
| `instructions` | TEXT | - | Yes | NULL | General administration directives and patient precautions. |
| `status` | ENUM('Draft', 'Issued', 'Dispensed', 'Cancelled') | - | No | 'Draft' | Lifecycle status. Transition to `'Issued'` triggers inventory deduction and locks record immutability (BR-09, BR-10). |
| `deleted_at` | DATETIME | - | Yes | NULL | Soft-delete audit retention flag. |

---

## 3.9 Entity: PRESCRIPTION_ITEM
Associative relation linking prescriptions with specific pharmaceuticals, administration dosages, and dispensed quantities.

| Attribute Name | Data Type | Key Type | Nullable | Default Value | Integrity & Business Rules |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `item_id` | UUID / CHAR(36) | PK | No | `GEN_RANDOM_UUID()` | Primary surrogate identifier for individual prescription line item. |
| `prescription_id` | UUID / CHAR(36) | FK | No | None | Foreign key referencing `DIGITAL_PRESCRIPTION(prescription_id)`. Cascades soft operations. |
| `medicine_id` | UUID / CHAR(36) | FK | No | None | Foreign key referencing dispensary catalog `MEDICINE(medicine_id)`. |
| `dosage` | VARCHAR(50) | - | No | None | Specific medication dosage unit per intake (e.g., '500mg', '10ml'). |
| `frequency` | VARCHAR(50) | - | No | None | Administration frequency schedule (e.g., 'Twice daily after meals'). |
| `duration_days` | INT | - | No | None | Scheduled duration of pharmaceutical therapy in days. Constraint: `CHECK (duration_days > 0)`. |
| `quantity` | INT | - | No | None | Total units of medication prescribed for dispensing. Constraint: `CHECK (quantity > 0)`. |
| `unit_price_at_prescription` | DECIMAL(10,2) | - | No | None | Historical unit price snapshot frozen at prescription issuance. Constraint: `CHECK (unit_price_at_prescription >= 0)`. |

---

## 3.10 Entity: MEDICINE
Dispensary pharmacy inventory catalog storing registered medications, active compounds, pricing, and stock metrics.

| Attribute Name | Data Type | Key Type | Nullable | Default Value | Integrity & Business Rules |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `medicine_id` | UUID / CHAR(36) | PK | No | `GEN_RANDOM_UUID()` | Primary surrogate identifier for pharmaceutical catalog product. |
| `medicine_name` | VARCHAR(100) | UQ | No | None | Proprietary brand or generic pharmaceutical name. Globally unique. |
| `active_ingredient`| VARCHAR(100) | - | Yes | NULL | Core active pharmacological chemical compound. |
| `unit` | VARCHAR(20) | - | No | 'Tablet' | Unit of dispensing measurement (e.g., 'Tablet', 'Capsule', 'Vial', 'Bottle'). |
| `unit_price` | DECIMAL(10,2) | - | No | 0.00 | Retail sale price per single dispensing unit. Constraint: `CHECK (unit_price >= 0)`. |
| `stock_quantity` | INT | - | No | 0 | Real-time on-hand inventory balance. Constraint: `CHECK (stock_quantity >= 0)` (BR-09). |
| `reorder_level` | INT | - | No | 10 | Automated threshold trigger for procurement reordering. Constraint: `CHECK (reorder_level >= 0)`. |

---

## 3.11 Entity: INVOICE
Fiscal invoice accounting for clinical services rendered and dispensed pharmaceuticals for completed patient consultations.

| Attribute Name | Data Type | Key Type | Nullable | Default Value | Integrity & Business Rules |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `invoice_id` | UUID / CHAR(36) | PK | No | `GEN_RANDOM_UUID()` | Primary surrogate financial invoice identifier. |
| `appointment_id` | UUID / CHAR(36) | FK, UQ | No | None | Foreign key referencing `APPOINTMENT(appointment_id)`. `UNIQUE` guarantees single billing statement per visit (BR-11). |
| `patient_id` | UUID / CHAR(36) | FK | No | None | Foreign key referencing billed `PATIENT(patient_id)`. |
| `issue_date` | DATETIME | - | No | `CURRENT_TIMESTAMP` | Official billing and generation timestamp. |
| `total_amount` | DECIMAL(12,2) | - | No | 0.00 | Final gross billing charge: $Fee_{Consultation} + \sum (Item_{Quantity} \times Item_{Price})$. Constraint: `CHECK (total_amount >= 0)`. |
| `payment_status` | ENUM('Unpaid', 'Paid', 'Refunded') | - | No | 'Unpaid' | Financial settlement workflow state machine (BR-12). |
| `payment_method` | ENUM('Cash', 'Credit Card', 'Insurance', 'Bank Transfer') | - | No | 'Cash' | Channel utilized for payment settlement. |
