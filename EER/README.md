# Healthcare Clinic & Telemedicine Portal — EER

## Purpose

This folder contains the official Phase 1 Enhanced Entity-Relationship model
for the Healthcare Clinic & Telemedicine Portal. The model is presented on one
connected Chen-notation canvas so that shared entities and constraints can be
reviewed consistently.

The diagram is organized into six connected areas:

1. Patient, appointments, and telemedicine sessions
2. Doctor specialization, schedules, leave, and specialties
3. Medical history and specialist referrals
4. Prescriptions, prescription items, medicines, and inventory
5. Invoices and payment transactions
6. Identity access management, user sessions, notifications, and audit logs

## Key Rules Represented

- A patient can book appointments; each appointment belongs to one patient and
  one doctor.
- Doctor specialization is total and disjoint: every doctor is either a
  `GENERAL_PRACTITIONER` or a `SPECIALIST`.
- Only a `GENERAL_PRACTITIONER` can provide telemedicine appointments.
- A specialist can have multiple specialties through the
  `HAS_SPECIALTY` relationship.
- A patient owns medical history records. A general practitioner creates
  referrals that target a specialty.
- A telemedicine appointment uses exactly one telemedicine session.
- A completed appointment may create a prescription, which contains
  prescription items linked to medicines.
- Every completed appointment generates exactly one invoice.
- An invoice can receive multiple payment transactions until the invoice is
  fully paid.
- User accounts can have multiple roles, sessions, notifications, and audit
  log records according to the IAM scope.

## Chen EER Notation

- Rectangle: entity
- Diamond: relationship
- Oval: attribute
- Underlined attribute: primary key
- `d` circle: disjoint specialization
- `(1,1)`, `(0,1)`, `(0,N)`, and `(1,N)`: minimum and maximum
  participation/cardinality
- `(Ref)`: a reference entity reused to show a relationship in a focused area

## Files

- [Editable Draw.io EER source](healthcare_clinic_telemedicine_portal_eer.drawio)
- [SVG visual preview](healthcare_clinic_telemedicine_portal_eer_preview.svg)

The Draw.io file is the authoritative editable source. The SVG preview is
included for quick viewing on GitHub and in project documentation.
