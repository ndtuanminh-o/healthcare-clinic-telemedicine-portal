[Uploading project_scope.md…]()
# Project Scope

## Project Identity

- **Project ID:** #5
- **Project title:** Healthcare Clinic & Telemedicine Portal
- **Course:** INT1313 - Database Systems
- **Team:** G5
- **Phase:** 1 - Problem Statement and Conceptual Design

## 1. Problem Statement

Healthcare clinics need a reliable way to coordinate patients, doctors,
appointments, clinical records, prescriptions, medicine inventory, billing, and
remote consultations. Separate or informal processes can cause scheduling
conflicts, incomplete medical information, incorrect prescription handling,
inventory errors, and weak access control.

This project proposes a relational database for a clinic portal that centralizes
these activities while preserving clinical, financial, and security integrity.
The system supports in-person appointments and telemedicine appointments.
General Practitioners are the only doctors allowed to provide telemedicine.
Specialists provide in-person consultations and may be registered in multiple
medical specialties.

## 2. System Objective

The system manages:

- Patient registration and patient information.
- Doctor profiles, GP/Specialist specialization, and specialties.
- Doctor schedules and leave dates.
- In-person and telemedicine appointments.
- Online telemedicine sessions.
- Patient medical history.
- GP referrals to target specialties.
- Digital prescriptions and prescription items.
- Medicine catalogue and current inventory quantities.
- Mandatory invoicing for completed appointments.
- One or more payments per invoice.
- Notifications and delivery retry status.
- User accounts, roles, sessions, and audit logs.

## 3. Scope Boundaries

### In Scope

- Relational data modeling using EER notation.
- Total and disjoint specialization of `DOCTOR` into `GENERAL_PRACTITIONER`
  and `SPECIALIST`.
- Many-to-many relationship between `SPECIALIST` and `SPECIALTY`.
- Appointment overlap and doctor schedule validation.
- Prescription and inventory integrity.
- Invoice and payment integrity.
- Referral, IAM, notification, audit-log, and soft-delete support.

### Out of Scope

- Medicine batches.
- Medicine expiry-date validation.
- Real payment gateway integration.
- Real video-call infrastructure.
- Advanced insurance claim processing.

## 4. Main Actors

| Actor | Main responsibilities |
|---|---|
| Patient | Book appointments, view personal records, view prescriptions, pay invoices |
| General Practitioner | Provide general care and telemedicine; create referrals |
| Specialist | Provide in-person care within registered specialties |
| Administrative Staff | Manage patients, appointments, schedules, and operations |
| Pharmacist | Review issued prescriptions and manage inventory |
| Administrator | Manage accounts, roles, configuration, and audit logs |
| Insurance Provider | Verify limited medical and billing information |

## 5. Conceptual Design Decisions

- `MEDICAL_HISTORY` is linked directly to `PATIENT`.
- A telemedicine appointment must be assigned to a GP and must have exactly one
  `TELEMEDICINE_SESSION`.
- An in-person appointment may be assigned to a GP or Specialist.
- Every completed appointment must have exactly one invoice.
- Scheduled and cancelled appointments must not have invoices.
- Each medicine has one current `INVENTORY` record; batch and expiry data are
  not modeled.
- Core clinical and billing records use soft deletion rather than physical
  deletion.
