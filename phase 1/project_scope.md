[project_scope.md](https://github.com/user-attachments/files/32013008/project_scope.md)
## Project Scope

### 1. Project Overview

The Healthcare Clinic and Telemedicine Portal is a relational database project for managing outpatient clinic consultations and remote telemedicine services through one integrated platform.

The system combines appointment coordination, doctor scheduling, patient management, clinical documentation, digital prescriptions, medicine inventory, invoicing, payments, verification, and role-based access control.

The project is designed as a high-integrity relational database system that supports both in-person and virtual consultations while preserving clinical and financial auditability.

### 1.1 System Objective

The project aims to:

1. Provide a unified appointment workflow for in-person and telemedicine consultations.
2. Prevent overlapping appointments for doctors and patients.
3. Model doctor specialization using an Enhanced Entity-Relationship hierarchy.
4. Connect completed consultations with medical records and digital prescriptions.
5. Track medicine stock and prevent invalid or excessive dispensing.
6. Generate one consolidated invoice for each appointment.
7. Maintain accurate payment and settlement status.
8. Preserve historical clinical and financial records through soft deletion and audit-friendly identifiers.
9. Enforce data integrity through primary keys, foreign keys, unique constraints, checks, defaults, and database triggers.
10. Protect data through role-based access control and least-privilege permissions.

### Stable Key Definitions

Each stable key is an immutable UUID-based surrogate identifier unless explicitly described as an inherited identity key. Mutable business attributes, such as phone numbers, license numbers, medicine names, and appointment dates, are not used as primary identity keys.

|---|---|
| `DOCTOR` | Common licensed-practitioner details, credentials, contact information, and employment status. Stable key: `doctor_id`. |
| `GENERAL_PRACTITIONER` | Physical outpatient doctor specialization with clinic room and consultation fee. Stable key: inherited `doctor_id` from `DOCTOR`. |
| `SPECIALIST` | Specialized-care and telemedicine doctor specialization with specialty and certification information. Stable key: inherited `doctor_id` from `DOCTOR`. |
| `DOCTOR_SCHEDULE` | Doctor duty interval with work date, start time, end time, and availability status. Stable key: `schedule_id`. |
| `PATIENT` | Registered patient identity, demographic details, contact information, and account status. Stable key: `patient_id`. |
| `APPOINTMENT` | In-person or telemedicine booking with patient, doctor, date, time slot, reason, and status. Stable key: `appointment_id`. |
| `MEDICAL_RECORD` | Consultation encounter record containing diagnosis, clinical notes, treatment plan, and record date. Stable key: `record_id`. |
| `DIGITAL_PRESCRIPTION` | Physician-issued pharmaceutical authorization linked to a medical record, with validity and lifecycle status. Stable key: `prescription_id`. |
| `PRESCRIPTION_ITEM` | Prescription line linking a medicine to dosage, frequency, duration, quantity, and captured price. Stable key: `item_id`. |
| `MEDICINE` | Approved pharmaceutical catalog and dispensary inventory with unit price, stock quantity, and reorder level. Stable key: `medicine_id`. |
| `INVOICE` | Consolidated financial bill for consultation services and dispensed medicines. Stable key: `invoice_id`. |
| `PAYMENT` | Logical-schema relation recording payment transactions associated with an invoice. Stable key: `payment_id`. |
| `DOCTOR` | Common licensed-practitioner details, credentials, contact information, and employment status. |
| `GENERAL_PRACTITIONER` | Physical outpatient doctor specialization with clinic room and consultation fee. |
| `SPECIALIST` | Specialized-care and telemedicine doctor specialization with specialty and certification information. |
| `DOCTOR_SCHEDULE` | Doctor duty interval with work date, start time, end time, and availability status. |
| `PATIENT` | Registered patient identity, demographic details, contact information, and account status. |
| `APPOINTMENT` | In-person or telemedicine booking with patient, doctor, date, time slot, reason, and status. |
| `MEDICAL_RECORD` | Consultation encounter record containing diagnosis, clinical notes, treatment plan, and record date. |
| `DIGITAL_PRESCRIPTION` | Physician-issued pharmaceutical authorization linked to a medical record, with validity and lifecycle status. |
| `PRESCRIPTION_ITEM` | Prescription line linking a medicine to dosage, frequency, duration, quantity, and captured price. |
| `MEDICINE` | Approved pharmaceutical catalog and dispensary inventory with unit price, stock quantity, and reorder level. |
| `INVOICE` | Consolidated financial bill for consultation services and dispensed medicines. |
| `PAYMENT` | Logical-schema relation recording payment transactions associated with an invoice. |

### In Scope

#### Appointment and Scheduling Management

- Register doctors, patients, and doctor duty schedules.
- Support in-person and telemedicine appointment types.
- Record booking time, consultation date, start time, end time, reason for visit, and appointment status.
- Validate that an appointment falls within an active doctor schedule.
- Prevent overlapping active appointments for the same doctor or patient.
- Support the following appointment lifecycle:
  - `Scheduled` → `In-Progress` → `Completed`
  - `Scheduled` → `Cancelled`

#### Doctor Management

- Maintain a common `DOCTOR` superclass for licensed medical practitioners.
- Support two disjoint and total doctor subclasses:
  - `GENERAL_PRACTITIONER` for physical clinic consultations.
  - `SPECIALIST` for specialized care and telemedicine consultations.
- Store license, contact, employment status, consultation fee, clinic room, specialty, and board certification information.

#### Patient Management

- Store patient identity and demographic information.
- Maintain contact details, gender, address, and account status.
- Use an immutable UUID-based patient identifier.
- Preserve records through soft deletion instead of physical deletion.

#### Clinical Record Management

- Create at most one medical record for a completed appointment.
- Store diagnosis, clinical notes, treatment plan, attending specialist, and record date.
- Require an active patient, consulting physician, and mandatory diagnosis.
- Link medical records to appointments and patients through foreign keys.

#### Digital Prescription Management

- Create at most one digital prescription for a medical record.
- Store issue date, validity period, instructions, and prescription status.
- Support prescription states including `Draft`, `Issued`, `Dispensed`, and `Cancelled`.
- Prevent modification or deletion after a prescription is marked `Issued`.
- Support one or more prescription items per prescription.

#### Medicine and Inventory Management

- Maintain a medicine catalog with unique medicine names.
- Store active ingredients, dispensing units, prices, current stock, and reorder levels.
- Require positive prescription quantities and durations.
- Block prescriptions for expired medicines.
- Decrease stock atomically when a prescription changes to `Issued`.
- Prevent dispensing quantities greater than available stock.

#### Billing and Payment Management

- Generate exactly one consolidated invoice for each appointment.
- Calculate the invoice from the consultation fee and dispensed medicine costs.
- Track invoice status as `Unpaid`, `Paid`, or `Refunded`.
- Support cash, credit card, insurance, and bank transfer payment methods.
- Prevent payments from exceeding the outstanding invoice balance.

#### Security and Access Control

The system will define the following business roles:

- `role_receptionist`
- `role_physician`
- `role_pharmacist`
- `role_billing_officer`
- `role_system_auditor`

Each role will receive only the permissions required for its operational responsibilities. Read and write privileges will be separated by entity and business function.

### Core Data Model

The logical database model contains the following primary entities and relationships. The stable-key definitions are specified in the separate table above. The logical mapping also includes `PAYMENT` as a dependent financial relation.

| Entity | Responsibility |
|---|---|
| `DOCTOR` | Common identity and credentials for licensed practitioners |
| `GENERAL_PRACTITIONER` | Physical outpatient doctor specialization |
| `SPECIALIST` | Specialized and telemedicine doctor specialization |
| `DOCTOR_SCHEDULE` | Doctor working intervals and availability |
| `PATIENT` | Registered patient identity and demographics |
| `APPOINTMENT` | In-person or telemedicine booking |
| `MEDICAL_RECORD` | Clinical diagnosis and consultation documentation |
| `DIGITAL_PRESCRIPTION` | Prescription authorization and status |
| `PRESCRIPTION_ITEM` | Medicine, dosage, duration, and quantity line |
| `MEDICINE` | Pharmaceutical catalog and stock |
| `INVOICE` | Consolidated clinical and medicine billing |
| `PAYMENT` | Payment transactions associated with invoices |
