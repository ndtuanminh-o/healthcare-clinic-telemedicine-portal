# Healthcare Clinic & Telemedicine Portal

Database project for **INT1313 - Database Systems**, Semester 1, Academic
Year 2026-2027.

## Project Identity

- **Project:** #5 — Healthcare Clinic & Telemedicine Portal
- **Team:** G5 — Pingo
- **Documentation language:** English

## Team

| Student ID | Member | Github nickname |
|---|---|---|
| N25DCAT086 | Ho Thi Truc Linh | linh-h-annanie |
| N25DCAT087 | Huynh Mai Tri Loc | halo16-04 |
| N25DCAT089 | Nguyen Dang Tuan Minh | ndtuanminh-o
 |

## Project Overview

The project designs a relational database for a healthcare clinic and
telemedicine portal. It centralizes patient information, doctor management,
appointments, clinical records, prescriptions, medicine inventory, billing,
notifications, and access control.

The system supports both in-person and telemedicine appointments. Only
`GENERAL_PRACTITIONER` doctors can provide telemedicine, while a
`SPECIALIST` may be registered with multiple specialties.

## Phase 1 Deliverables

Phase 1 contains the scope, business rules, and one unified connected Chen EER
model:

- [Project scope](phase%201/project_scope.md)
- [Business rules](phase%201/business_rules.md)
- [EER documentation](phase%201/EER/README.md)
- [Editable EER source](phase%201/EER/healthcare_clinic_telemedicine_portal_eer.drawio)
- [EER SVG preview](phase%201/EER/healthcare_clinic_telemedicine_portal_eer_preview.svg)

### EER coverage

The unified EER model covers:

* **Patients and appointments:** Patient demographic profiles, unified scheduling, and consultation channel management (in-person clinic visits and remote telemedicine sessions).
* **Doctor specialization hierarchy and duty shifts:** General Practitioner (`GENERAL_PRACTITIONER`) and Specialist (`SPECIALIST`) disjoint specialization, clinical room allocations, specialty domains, and shift schedules (`DOCTOR_SCHEDULE`).
* **Clinical encounters and documentation:** Diagnostic medical records (`MEDICAL_RECORD`) linked to attending doctors, clinical findings, and treatment plans.
* **Digital pharmacy pipeline:** Digital prescriptions (`DIGITAL_PRESCRIPTION`), prescription line items (`PRESCRIPTION_ITEM`), and pharmaceutical catalog tracking with real-time stock levels (`MEDICINE`).
* **Billing and settlement:** Consolidated consultation and medication invoices (`INVOICE`) and payment transaction tracking (`PAYMENT`).

Important constraints include mandatory invoicing for completed appointments,
exactly one telemedicine session for a telemedicine appointment, inventory
validation when issuing prescriptions, and soft deletion for core records.
Medicine batches and expiry-date validation are outside the project scope.

## Repository Structure

```text
.
├── docs/
│   └── project-identity.md
├── phase 1/
│   ├── EER/
│   │   ├── README.md
│   │   ├── healthcare_clinic_telemedicine_portal_eer.drawio
│   │   └── healthcare_clinic_telemedicine_portal_eer_preview.svg
│   ├── business_rules.md
│   └── project_scope.md
├── .gitignore
└── README.md
```
