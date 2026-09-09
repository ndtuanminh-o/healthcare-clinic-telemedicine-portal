# Healthcare Clinic & Telemedicine Portal

Database project for **INT1313 - Database Systems**, Semester 1, Academic Year 2026–2027.  
Posts and Telecommunications Institute of Technology (PTIT).

---

## Project Identity

- **Topic:** #05 — Healthcare Clinic & Telemedicine Portal
- **Team:** G5 — Pingo
- **Documentation Language:** English

### Team Members

| Student ID | Full Name | GitHub | Email |
| :--- | :--- | :--- | :--- |
| **N25DCAT086** | Hồ Thị Trúc Linh | [@linh-h-annanie](https://github.com/linh-h-annanie) | `n25dcat086@student.ptithcm.edu.vn` |
| **N25DCAT087** | Huỳnh Mai Trí Lộc | [@halo16-04](https://github.com/halo16-04) | `n25dcat087@student.ptithcm.edu.vn` |
| **N25DCAT089** | Nguyễn Đăng Tuấn Minh | [@ndtuanminh-o](https://github.com/ndtuanminh-o) | `n25dcat089@student.ptithcm.edu.vn` |

---

## Project Overview

This project designs a relational database management system for a healthcare facility combining **in-person clinic consultations** and **remote telemedicine appointments**.

### Key Clinical Domains
- **Patients & Medical History:** Centralized demographics, diagnoses, and medical histories with soft-delete audit trails.
- **Doctor Specialization:** `DOCTOR` superclass specialized into `GENERAL_PRACTITIONER` (clinic rooms, in-person examination) and `SPECIALIST` (specialty fields, video telemedicine consultations).
- **Appointments & Rostering:** Shift scheduling (`DOCTOR_SCHEDULE`) and dual-mode appointment routing (`In-Person` vs. `Tele`).
- **Digital Pharmacy & Inventory:** Electronic prescriptions, line-item dosages, and real-time stock tracking with reorder thresholds.
- **Billing & Payments:** Consolidated invoice per appointment combining consultation fee and prescribed medication costs, settled via multi-channel payments.

---

## Project Deliverables

### Phase 1: Conceptual Design (EER)
- [Project Scope](phase%201/project_scope.md): System boundaries and functional specifications.
- [Business Rules](phase%201/business_rules.md): 12 business rules (BR-01 through BR-12).
- [EER Documentation](phase%201/eer/EER_Diagram_EN.md): Conceptual entity-relationship specifications and Mermaid model.
- [EER Visual Diagram](phase%201/eer/er_diagram_cropped.png): High-resolution conceptual diagram.

### Phase 2: Logical & Physical Relational Design (In Progress)
- [Physical Schema Documentation](phase%202/relational_schema_mapping/physical_schema_diagram.md): Physical relational schema specification and Mermaid ER diagram.
- [Physical Schema Diagram](phase%202/relational_schema_mapping/schema.png): Industrial relational schema (IE Crow's Foot notation).
- [Data Dictionary](phase%202/data_dictionary.md): ISO/IEC 11179 standardized metadata catalog.
- [Normalization Verification](phase%202/normalization_verification.md): Functional dependency analysis and normalization verification.

---

## Repository Structure

```text
.
├── docs/
│   └── project-identity.md
├── phase 1/
│   ├── eer/
│   │   ├── EER_Diagram_EN.md
│   │   └── er_diagram_cropped.png
│   ├── business_rules.md
│   └── project_scope.md
├── phase 2/
│   ├── relational_schema_mapping/
│   │   ├── physical_schema_diagram.md
│   │   └── schema.png
│   ├── data_dictionary.md
│   └── normalization_verification.md
├── .gitignore
└── README.md
```
