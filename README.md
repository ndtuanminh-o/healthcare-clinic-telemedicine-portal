<div align="center">

# Healthcare Clinic & Telemedicine Portal
### Relational Database Engineering & System Design

[![Course](https://img.shields.io/badge/Course-INT1313%20Database%20Systems-0052CC?style=for-the-badge&logo=postgresql&logoColor=white)](https://ptithcm.edu.vn)
[![Institution](https://img.shields.io/badge/Institution-PTIT%20HCM-DC2626?style=for-the-badge)](https://ptithcm.edu.vn)
[![Academic Year](https://img.shields.io/badge/Academic%20Year-2026--2027-10B981?style=for-the-badge)]()
[![Status](https://img.shields.io/badge/Status-Phase%201%20%26%202%20Complete-8B5CF6?style=for-the-badge)]()

<br/>

**[ English ](README.md)** &nbsp;|&nbsp; **[ Tiếng Việt ](README.vi.md)**

<br/>

An industrial-grade relational database management system coordinating on-premise outpatient clinic consultations and remote telemedicine appointments.

</div>

---

## 1. Project Information

| Property | Specification |
| :--- | :--- |
| **Course** | INT1313 - Database Systems (Semester 1, Academic Year 2026-2027) |
| **Institution** | Posts and Telecommunications Institute of Technology (PTIT HCM) |
| **Topic ID** | Topic #05: Healthcare Clinic & Telemedicine Portal |
| **Team Name** | G5 (Pingo) |

### Team Members

| Student ID | Full Name | Role | GitHub | Contact Email |
| :--- | :--- | :--- | :--- | :--- |
| **N25DCAT089** | Nguyễn Đăng Tuấn Minh | EER Lead & Database Modeling | [@ndtuanminh-o](https://github.com/ndtuanminh-o) | `nd.tuanminh.work@gmail.com` |
| **N25DCAT086** | Hồ Thị Trúc Linh | Requirements Analysis & Scope | [@linh-h-annanie](https://github.com/linh-h-annanie) | `n25dcat086@student.ptithcm.edu.vn` |
| **N25DCAT087** | Huỳnh Mai Trí Lộc | Relational Mapping & Schema | [@halo16-04](https://github.com/halo16-04) | `n25dcat087@student.ptithcm.edu.vn` |

---

## 2. System Architecture & Core Clinical Modules

| Clinical Domain | Architectural Design & Scope |
| :--- | :--- |
| **Physician Specialization** | `DOCTOR` superclass with Total (`===`) and Disjoint (`d`) specialization into `GENERAL_PRACTITIONER` (physical room exams) and `SPECIALIST` (virtual care and departmental care). |
| **Rostering & Shift Slots** | `DOCTOR_SCHEDULE` tracking duty dates (`work_date`), working intervals (`[start_time, end_time]`), and real-time reservation state (`slot_status`). |
| **Dual-Channel Appointments** | `APPOINTMENT` routing either `In-Person` visits or `Telemedicine` encounters with encrypted video channel integration (`BR-05`). |
| **Clinical Documentation** | `APPOINTMENT` (1:1) documents encounter into `MEDICAL_RECORD`, preserving mandatory diagnoses, specialist supervision, and longitudinal patient medical history. |
| **Formulary & Dispensary** | Electronic prescriptions (`DIGITAL_PRESCRIPTION`) linked to prescription line items (`PRESCRIPTION_ITEM`) with atomic stock decrement triggers (`BR-09`). |
| **Consolidated Fiscal Ledger** | Single unified `INVOICE` per encounter (1:1) summing consultation fees and line-item medication costs, settled via cash, card, insurance, or transfer. |

---

## 3. Project Deliverables & Milestone Roadmap

| Milestone | Focus & Methodology | Status | Deliverable Links |
| :---: | :--- | :---: | :--- |
| **Phase 1** | **Conceptual Design (EER)**<br/>ISO/IEC/IEEE 29148 Requirements & Elmasri EER Modeling | **Done** | • [Project Scope](phase%201/project_scope.md)<br/>• [Business Rules (BR-01 to BR-12)](phase%201/business_rules.md)<br/>• [EER Documentation (EN)](phase%201/eer/EER_Diagram_EN.md)<br/>• [EER Documentation (VI)](phase%201/eer/EER_Diagram_VI.md) |
| **Phase 2** | **Logical & Physical Design**<br/>ISO/IEC 11179 Data Dictionary & IE Crow's Foot Schema | **Done** | • [Physical Schema Mapping](phase%202/relational_schema_mapping/physical_schema_diagram.md)<br/>• [Data Dictionary](phase%202/data_dictionary.md)<br/>• [Normalization Proofs (1NF-BCNF)](phase%202/normalization_verification.md) |
| **Phase 3** | **Implementation & SQL Rigor**<br/>DDL Scripts, Triggers, Views & Analytical Queries | **Planned** | • SQL DDL Scripts (Tables, Constraints, Indexes)<br/>• Mock DML Data Insertion<br/>• 10+ Complex Analytical Queries |
| **Phase 4** | **Integration & Defense**<br/>Application Demo & Live Group Presentation | **Planned** | • UI/Backend Integration (Python/Flask or Node.js)<br/>• Technical Documentation & Report<br/>• Individual SQL Defense |

---

## 4. Repository Structure

```text
.
├── docs/
│   ├── project-identity.md
│   └── mcp-plan.md
├── phase 1/
│   ├── eer/
│   │   ├── EER_Diagram_EN.md
│   │   └── EER_Diagram_VI.md
│   ├── business_rules.md
│   └── project_scope.md
├── phase 2/
│   ├── relational_schema_mapping/
│   │   └── physical_schema_diagram.md
│   ├── data_dictionary.md
│   └── normalization_verification.md
├── .gitignore
├── README.md
└── README.vi.md
```
