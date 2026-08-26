# Healthcare Clinic & Telemedicine Portal

Database project for **INT1313 - Database Systems**, Semester 1, Academic
Year 2026-2027.

## Project Identity

- **Project:** #5 — Healthcare Clinic & Telemedicine Portal
- **Team:** G5 — Pingo
- **Phase:** Phase 1 — Problem Statement and Conceptual Design
- **Modeling notation:** Chen Enhanced Entity-Relationship (EER)
- **Documentation language:** English

## Team

| Student ID | Member | Responsibility |
|---|---|---|
| N25DCAT086 | Ho Thi Truc Linh | Problem statement and project scope |
| N25DCAT087 | Huynh Mai Tri Loc | Business rules |
| N25DCAT089 | Nguyen Dang Tuan Minh | Git management and EER diagram |

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
- [Phase 1 project report](phase%201/Project_Report_Phase_1.pdf)

### EER coverage

The unified EER model covers:

1. Patients, appointments, and telemedicine sessions
2. Doctors, GP/Specialist specialization, schedules, leave, and specialties
3. Medical history and GP referrals to specialties
4. Prescriptions, prescription items, medicines, and inventory
5. Invoices and payment transactions
6. User accounts, roles, sessions, notifications, and audit logs

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
│   ├── project_scope.md
│   └── Project_Report_Phase_1.pdf
├── .gitignore
└── README.md
```

## Git Workflow

- `main` is the stable submission branch.
- Use a focused branch for each change, such as `docs/update-readme` or
  `eer/refine-diagram`.
- Review changes before merging them into `main`.
- Keep documentation and database identifiers in English and use lowercase
  `snake_case` for identifiers where applicable.
