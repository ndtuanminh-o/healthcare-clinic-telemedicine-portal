# Healthcare Clinic & Telemedicine Portal — EER

This folder contains the Phase 1 Enhanced Entity-Relationship (EER) diagram
for the Healthcare Clinic & Telemedicine Portal.

## Files in this folder

There are exactly three project files in this folder:

| File | Purpose |
|---|---|
| `healthcare_clinic_telemedicine_portal_eer.drawio` | Editable Draw.io source and authoritative EER model |
| `healthcare_clinic_telemedicine_portal_eer_preview.svg` | SVG preview for quick viewing on GitHub |
| `README.md` | Documentation for the EER diagram |

## EER Model Summary

The diagram uses one connected Chen EER model covering the main healthcare
portal processes. It is organized into six connected areas:

1. Patient, appointments, and telemedicine sessions
2. Doctor specialization, schedules, leave, and specialties
3. Medical history and specialist referrals
4. Prescriptions, prescription items, medicines, and inventory
5. Invoices and payment transactions
6. Identity access management, user sessions, notifications, and audit logs

## Main Business Constraints

- A patient can book appointments; each appointment belongs to one patient and
  one doctor.
- Doctor specialization is total and disjoint: every doctor is either a
  `GENERAL_PRACTITIONER` or a `SPECIALIST`.
- Only a `GENERAL_PRACTITIONER` can provide telemedicine appointments.
- A `SPECIALIST` can have multiple specialties.
- Medical history is associated with the patient.
- A general practitioner creates referrals that target a specialty.
- A telemedicine appointment uses exactly one telemedicine session.
- A completed appointment may create one prescription, which contains
  prescription items linked to medicines.
- Every completed appointment generates exactly one invoice.
- An invoice may receive multiple payment transactions until it is paid.

## Chen EER Notation

- Rectangle: entity
- Diamond: relationship
- Oval: attribute
- Underlined attribute: primary key
- `d` circle: disjoint specialization
- Cardinalities such as `(1,1)`, `(0,1)`, `(0,N)`, and `(1,N)` show
  participation constraints.

## View the Diagram

- [Open the editable Draw.io source](healthcare_clinic_telemedicine_portal_eer.drawio)
- [Open the SVG preview](healthcare_clinic_telemedicine_portal_eer_preview.svg)

The Draw.io file is the source of truth for future edits. The SVG file is a
read-only visual preview.
