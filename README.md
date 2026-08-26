# Healthcare Clinic & Telemedicine Portal

Database project for INT1313 - Database Systems, Semester 1, Academic Year 2026-2027.

## Project Identity

- **Project ID:** 5
- **Team:** G5
- **Team Name:** Pingo
- **Project Title:** Healthcare Clinic & Telemedicine Portal
- **Design notation:** Chen Enhanced Entity-Relationship (EER)
- **Documentation language:** English

## Team Members and Responsibilities

| Student ID | Member | Responsibility |
|---|---|---|
| N25DCAT086 | Ho Thi Truc Linh | Problem statement and project scope |
| N25DCAT087 | Huynh Mai Tri Loc | Business rules |
| N25DCAT089 | Nguyen Dang Tuan Minh | Git management and EER diagram |

## Phase 1

Phase 1 defines the project scope, business rules, and the database's unified
Chen EER model:

- [Project Scope](phase%201/project_scope.md)
- [Business Rules](phase%201/business_rules.md)
- [EER documentation](phase%201/EER/README.md)
- [Editable EER source](phase%201/EER/healthcare_clinic_telemedicine_portal_eer.drawio)
- [EER visual preview](phase%201/EER/healthcare_clinic_telemedicine_portal_eer_preview.svg)
- [Phase 1 Project Report (PDF)](phase%201/Project_Report_Phase_1.pdf)

### EER overview

The EER is maintained as one connected diagram. It covers patient booking and
telemedicine, doctor specialization and scheduling, medical history and
referrals, prescriptions and inventory, invoices and payments, and identity
access management with sessions, notifications, and audit logs. The editable
Draw.io file is the source of truth; the SVG is provided for quick review.

## Development Workflow

- `main` contains stable, submission-ready versions.
- `develop` is used to integrate reviewed work.
- Work is developed in focused feature or documentation branches and merged
  through pull requests.
- Project documentation and database identifiers use English and lowercase
  `snake_case` where applicable.
