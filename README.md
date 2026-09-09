# Healthcare Clinic & Telemedicine Portal

[![Course](https://img.shields.io/badge/Course-INT1313%20Database%20Systems-blue.svg)](https://portal.ptit.edu.vn/)
[![Institution](https://img.shields.io/badge/Institution-PTIT%20HCM-red.svg)](https://ptithcm.edu.vn/)
[![Topic](https://img.shields.io/badge/Topic-%2305%20Clinic%20%26%20Telemedicine-success.svg)](#project-overview)
[![Team](https://img.shields.io/badge/Team-G5%20--%20Pingo-orange.svg)](#team-members)
[![Status](https://img.shields.io/badge/Status-Phase%201%20%26%202%20Completed-brightgreen.svg)](#project-deliverables)

Database engineering project for **INT1313 - Database Systems**, Semester 1, Academic Year 2026-2027 at Posts and Telecommunications Institute of Technology (PTIT).

---

## Table of Contents
- [Project Identity](#project-identity)
- [Team Members](#team-members)
- [Project Overview](#project-overview)
- [Project Deliverables](#project-deliverables)
  - [Phase 1: Conceptual Design (EER)](#phase-1-conceptual-design-eer)
  - [Phase 2: Logical & Physical Relational Design](#phase-2-logical--physical-relational-design)
- [Relational Architecture Highlights](#relational-architecture-highlights)
- [Entity & Schema Quick Reference](#entity--schema-quick-reference)
- [Repository Structure](#repository-structure)

---

## Project Identity

- **Project ID:** Topic #05 — Healthcare Clinic & Telemedicine Portal
- **Team Name:** G5 — Pingo
- **Institution:** Posts and Telecommunications Institute of Technology (PTIT)
- **Course:** INT1313 - Database Systems (CSDL)
- **Academic Year:** Semester 1, 2026–2027
- **Primary Documentation Language:** English

---

## Team Members

| Student ID | Full Name | GitHub Username | Academic Email |
| :--- | :--- | :--- | :--- |
| **N25DCAT086** | Hồ Thị Trúc Linh | [@linh-h-annanie](https://github.com/linh-h-annanie) | `n25dcat086@student.ptithcm.edu.vn` |
| **N25DCAT087** | Huỳnh Mai Trí Lộc | [@halo16-04](https://github.com/halo16-04) | `n25dcat087@student.ptithcm.edu.vn` |
| **N25DCAT089** | Nguyễn Đặng Tuấn Minh | [@ndtuanminh-o](https://github.com/ndtuanminh-o) | `n25dcat089@student.ptithcm.edu.vn` |

---

## Project Overview

The **Healthcare Clinic & Telemedicine Portal** project designs and implements an enterprise-grade relational database model for a modern healthcare facility that seamlessly unites **in-person clinic consultations** and **remote digital telemedicine appointments**.

### Core Clinical & Business Workflows
1. **Patient & Medical History:** Centralized registration, demographic data, and chronological medical history records with non-destructive audit trails.
2. **Doctor Hierarchy & Rostering:** Superclass `DOCTOR` specialized into `GENERAL_PRACTITIONER` and `SPECIALIST` using relational identity inheritance (Option 8.4a), coupled with weekly shift schedules (`DOCTOR_SCHEDULE`).
3. **Dual Care-Delivery Encounters:** Unified consultation management supporting:
   - **In-Person Consultations:** Physical on-premise clinical visits directed to designated clinic rooms.
   - **Telemedicine Consultations:** Remote video appointments conducted by medical specialists via secure teleconsultation room links.
4. **Digital Pharmacy & Real-Time Dispensary:** Digital prescription authoring (`DIGITAL_PRESCRIPTION`), line-item dosage mapping (`PRESCRIPTION_ITEM`), and real-time inventory decrementing with automated reorder thresholds (`MEDICINE`).
5. **Consolidated Billing & Settlements:** Automated generation of a single consolidated invoice (`INVOICE`) per clinical encounter combining physician consultation fees and prescription medication costs, supported by flexible multi-channel transactions (`PAYMENT`).

---

## Project Deliverables

### Phase 1: Conceptual Design (EER)

Phase 1 establishes the system scope, declarative/procedural business rules, and the complete Enhanced Entity-Relationship (EER) model using standard Chen notation:

* 📄 **[Project Scope](phase%201/project_scope.md):** In-depth functional boundaries, system domains, and subsystem interfaces.
* 📜 **[Business Rules & Constraints](phase%201/business_rules.md):** Formal specification of 12 foundational rules (BR-01 through BR-12) covering scheduling, specialization, inventory triggers, and billing integrity.
* 📐 **[EER Conceptual Documentation](phase%201/eer/EER_Diagram_EN.md):** Detailed specification of all entities, weak entities, relationship diamonds, cardinalities, and specialization hierarchies.
* 🖼️ **[EER Visual Diagram](phase%201/eer/er_diagram_cropped.png):** High-resolution diagram of the complete conceptual model.

### Phase 2: Logical & Physical Relational Design

Phase 2 transforms the conceptual EER schema into an industrial, fully normalized (3NF/BCNF) relational schema adhering to ISO/IEC 19505 (IE Crow's Foot Notation) and ISO/IEC 11179 metadata standards:

* 📊 **[Physical Schema Specification](phase%202/relational_schema_mapping/physical_schema_diagram.md):** Exhaustive technical documentation of the 12 relational tables, data types, primary keys, foreign keys, unique constraints, and executable Mermaid code.
* 🖼️ **[Physical Schema Diagram](phase%202/relational_schema_mapping/schema.png):** Industrial relational physical model with zero-crossing layout and IE Crow's Foot notation.
* 📚 **[Data Dictionary](phase%202/data_dictionary.md):** Standardized 6-column metadata catalog (Attribute, Data Type, Key, Nullable, Default, Integrity Rules) according to ISO/IEC 11179.
* 🧪 **[Normalization Verification](phase%202/normalization_verification.md):** Proof of functional dependency resolution, 1NF to 3NF/BCNF normalization proofs, and relational integrity matrices.

---

## Relational Architecture Highlights

```
                      ┌────────────────────────────┐
                      │    DOCTOR (Superclass)     │
                      │    PK: doctor_id           │
                      └─────────────┬──────────────┘
                                    │
               ┌────────────────────┴────────────────────┐
               ▼ (1:1 PK=FK)                             ▼ (1:1 PK=FK)
┌──────────────────────────────┐          ┌──────────────────────────────┐
│     GENERAL_PRACTITIONER     │          │          SPECIALIST          │
│ PK,FK: doctor_id             │          │ PK,FK: doctor_id             │
│ clinic_room : VARCHAR(20)    │          │ specialty_area : VARCHAR(50) │
│ consultation_fee : DECIMAL   │          │ telemedicine_fee : DECIMAL   │
└──────────────────────────────┘          └──────────────────────────────┘
```

* **Disjoint Specialization Inheritance (Option 8.4a):**
  Specialization is mapped using shared primary keys (`PK, FK: doctor_id`), enforcing a strict 1:1 identity inheritance without nullable attribute bloat.
* **Unified Appointment Association:**
  `APPOINTMENT.doctor_id` references the `DOCTOR` superclass directly, allowing both General Practitioners and Specialists to accept bookings through a unified relation.
* **Strict 1:0..1 Relational Enforcement:**
  Both `DIGITAL_PRESCRIPTION(appt_id)` and `INVOICE(appt_id)` utilize `UNIQUE FK` constraints, preventing duplicate prescriptions or redundant invoices for any single appointment encounter.
* **Real-Time Inventory Tracking:**
  The `MEDICINE` relation maintains active `stock_quantity` and `reorder_level` counters, facilitating atomic stock decrementing when prescriptions transition to `'Issued'`.
* **Regulatory Soft-Delete Pattern:**
  Core legal records (`PATIENT`, `DOCTOR`) utilize nullable `deleted_at: DATETIME` timestamps to preserve medical audit trails and historical prescriptions without physical record destruction.

---

## Entity & Schema Quick Reference

| # | Entity / Table | Primary Key | Foreign Keys | Key Attributes & Domain Purpose |
| :-: | :--- | :--- | :--- | :--- |
| 1 | `PATIENT` | `patient_id` | - | Patient demographic profile, phone (UQ), soft-delete (`deleted_at`). |
| 2 | `MEDICAL_HISTORY` | `record_id` | `patient_id`, `doctor_id` | Clinical history, prior diagnoses, diagnostic impressions. |
| 3 | `DOCTOR` | `doctor_id` | - | Physician superclass, license number (UQ), status, role discriminator. |
| 4 | `GENERAL_PRACTITIONER` | `doctor_id` (PK, FK) | `doctor_id` | Subclass for physical clinic consultations, `clinic_room`, `consultation_fee`. |
| 5 | `SPECIALIST` | `doctor_id` (PK, FK) | `doctor_id` | Subclass for specialty consultations, `specialty_area`, `telemedicine_fee`. |
| 6 | `DOCTOR_SCHEDULE` | `schedule_id` | `doctor_id` | Weekly roster shift recurrence (`day_of_week`, `start_time`, `end_time`). |
| 7 | `APPOINTMENT` | `appt_id` | `patient_id`, `doctor_id` | Dual-mode encounter (`In-Person`, `Tele`), video room URL, status state machine. |
| 8 | `DIGITAL_PRESCRIPTION` | `prescription_id` | `appt_id` (UQ) | Prescription header, issue timestamp, lifecycle status (`Draft`, `Issued`). |
| 9 | `PRESCRIPTION_ITEM` | `item_id` | `prescription_id`, `med_id` | Associative line item resolving M:N relationship, `quantity (>0)`, `dosage`. |
| 10 | `MEDICINE` | `med_id` | - | Pharmaceutical catalog, active stock tracking (`stock_quantity`), `reorder_level`. |
| 11 | `INVOICE` | `invoice_id` | `appt_id` (UQ) | Consolidated encounter billing header (`total_amount`), payment status (`Unpaid`, `Paid`). |
| 12 | `PAYMENT` | `payment_id` | `invoice_id` | Fiscal transaction settlement (`amount_paid`), payment method channel. |

---

## Repository Structure

```text
.
├── docs/
│   └── project-identity.md                       # Official project and team identity documentation
├── phase 1/
│   ├── eer/
│   │   ├── EER_Diagram_EN.md                     # Enhanced Entity-Relationship conceptual specification
│   │   └── er_diagram_cropped.png                # High-resolution conceptual EER diagram preview
│   ├── business_rules.md                         # 12 formal business rules and constraints (BR-01..BR-12)
│   └── project_scope.md                          # Functional scope, boundary definitions, and use cases
├── phase 2/
│   ├── relational_schema_mapping/
│   │   ├── physical_schema_diagram.md            # Physical relational schema specification & Mermaid source
│   │   └── schema.png                            # Industrial relational physical schema diagram
│   ├── data_dictionary.md                        # ISO/IEC 11179 standardized data dictionary catalog
│   └── normalization_verification.md             # Functional dependencies, 1NF-3NF/BCNF normalization proof
├── .gitignore                                    # Git exclusion rules
└── README.md                                     # Main repository architecture and navigation portal
```

---

## References

1. **Elmasri, R., & Navathe, S. B.** (2015). *Fundamentals of Database Systems* (7th ed.). Pearson.
2. **ISO/IEC 19505:2012:** *Information technology — Object Management Group Unified Modeling Language (OMG UML)*.
3. **ISO/IEC 11179:** *Information technology — Metadata registries (MDR)*.
4. **ANSI/IEEE Std 830-1998:** *IEEE Recommended Practice for Software Requirements Specifications*.
