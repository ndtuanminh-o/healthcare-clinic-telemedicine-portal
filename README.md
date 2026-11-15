# Healthcare Clinic & Telemedicine Portal

Database project for **INT1313 - Database Systems**, Semester 1, Academic Year 2026-2027.  
Posts and Telecommunications Institute of Technology (PTIT).

---

## Project Identity

- **Topic:** #05: Healthcare Clinic & Telemedicine Portal
- **Team:** G5 (Pingo)
- **Instructor / Supervisor:** ThS. Lê Hà Thanh (`lehathanh@ptithcm.edu.vn`)

### Project Team & Personnel

| Role / Student ID | Full Name | GitHub / Affiliation | Email |
| :--- | :--- | :--- | :--- |
| **Instructor** | ThS. Lê Hà Thanh | Giảng viên hướng dẫn | `lehathanh@ptithcm.edu.vn` |
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
- [Project Scope](phase%201/project_scope.md)
- [Business Rules](phase%201/business_rules.md)
- [EER Documentation & Diagram](phase%201/eer/EER_Diagram_EN.md) ([PNG](phase%201/eer/eer_diagram.png) | [SVG](phase%201/eer/eer_diagram.svg))

### Phase 2: Logical & Physical Relational Design
- [Physical Schema Documentation & Diagram](phase%202/relational_schema_mapping/physical_schema_diagram.md) ([PNG](phase%202/relational_schema_mapping/physical_schema_diagram.png) | [SVG](phase%202/relational_schema_mapping/physical_schema_diagram.svg))
- [Data Dictionary](phase%202/data_dictionary.md)
- [Normalization Verification](phase%202/normalization_verification.md)

### Phase 3: Physical Implementation & Advanced SQL
- [01 Schema DDL (11 Tables & Views)](phase%203/01_schema.sql)
- [02 Business Triggers & Views](phase%203/02_trigger_and_view.sql)
- [03 Master Mock Data Script (Manual Import)](phase%203/03_mock_data.sql)
- [03.1 Doctor Schedule Extension Script](phase%203/03_1_schedule_extension.sql)
- [04 Analytical Queries (10 Self-Contained Queries)](phase%203/04_advanced_queries.sql)
- [Query Test Cases & Validation](phase%203/test_case.md)

### Phase 4: Web Application & Management Portal
- **Stack:** Python 3 (Flask), MySQL (`mysql-connector-python`), Vanilla JS, CSS3.
- **Features:**
  - Appointment Booking with conflict prevention & auto patient registration (`/booking`).
  - Doctor Clinical Desk: diagnosis documentation, electronic prescription with inventory deduction, and audit logging (`/doctor`).
  - Analytics Dashboard: real-time visualizations for Q01, Q06, Q09, and Q10 (`/dashboard`).

---

## Quickstart

### 1. Database Setup (MySQL 8.0)
Load schema, mock data, and triggers manually via **MySQL Workbench** or **MySQL CLI** in sequential order:

#### Sequential Import Order
1. `phase 3/01_schema.sql` (Creates database `healthcare_clinic_v2`, 11 base tables, constraints, and audit log)
2. `phase 3/02_trigger_and_view.sql` (Creates business triggers BR-01..BR-09 and analytical views)
3. `phase 3/03_mock_data.sql` (Loads full master mock data dataset with UTF-8 encoding)
4. `phase 3/03_1_schedule_extension.sql` (Generates extended doctor schedule slots)
5. *(Optional for Phase 4 web app audit)*: `phase 4/database/prescription_audit.sql` and `phase 4/database/prescription_audit_triggers.sql`

#### Option A: MySQL Workbench (Recommended)
1. Open MySQL Workbench and connect to your local MySQL instance (port `3306`).
2. Open each SQL script sequentially (`File` -> `Open SQL Script...` or `Ctrl + Shift + O`).
3. Click the ⚡ **Execute** button (or `Ctrl + Shift + Enter`) for each script in the order above.

#### Option B: MySQL Command Line (CLI)
Execute the following commands sequentially from the project root:
```bash
mysql -u root -p --default-character-set=utf8mb4 < "phase 3/01_schema.sql"
mysql -u root -p --default-character-set=utf8mb4 healthcare_clinic_v2 < "phase 3/02_trigger_and_view.sql"
mysql -u root -p --default-character-set=utf8mb4 healthcare_clinic_v2 < "phase 3/03_mock_data.sql"
mysql -u root -p --default-character-set=utf8mb4 healthcare_clinic_v2 < "phase 3/03_1_schedule_extension.sql"
```

### 2. Run Web Application
```bash
pip install flask mysql-connector-python
cd "phase 4"
python app.py
```
Open [http://localhost:5000](http://localhost:5000) in your browser:
- **Booking Portal:** `http://localhost:5000/booking`
- **Doctor Consultation:** `http://localhost:5000/doctor`
- **Analytics Dashboard:** `http://localhost:5000/dashboard`

---

## Repository Structure

```text
.
├── docs/
│   ├── project-identity.md
│   ├── G5.pdf
│   └── Tutorial.pdf
├── phase 1/
│   ├── eer/
│   │   ├── EER_Diagram_EN.md
│   │   ├── eer_diagram.png
│   │   └── eer_diagram.svg
│   ├── business_rules.md
│   └── project_scope.md
├── phase 2/
│   ├── relational_schema_mapping/
│   │   ├── physical_schema_diagram.md
│   │   ├── physical_schema_diagram.png
│   │   └── physical_schema_diagram.svg
│   ├── data_dictionary.md
│   └── normalization_verification.md
├── phase 3/
│   ├── 01_schema.sql
│   ├── 02_trigger_and_view.sql
│   ├── 03_mock_data.sql
│   ├── 03_1_schedule_extension.sql
│   ├── 04_advanced_queries.sql
│   ├── query_results/
│   └── test_case.md
├── phase 4/
│   ├── database/
│   │   ├── prescription_audit.sql
│   │   └── prescription_audit_triggers.sql
│   ├── routes/
│   │   ├── appointment_routes.py
│   │   ├── clinical_routes.py
│   │   ├── dashboard_routes.py
│   │   └── prescription_routes.py
│   ├── static/
│   │   ├── css/
│   │   └── js/
│   ├── templates/
│   │   ├── booking.html
│   │   ├── dashboard.html
│   │   └── doctor.html
│   ├── app.py
│   ├── config.py
│   └── db.py
├── .gitignore
└── README.md
```

---

## References & Academic Sources

1. **Course Textbook:**
   - Ramez Elmasri and Shamkant B. Navathe. *Fundamentals of Database Systems* (7th Edition), Pearson, 2016.

2. **Course Lectures & Curriculum:**
   - Le Ha Thanh, M.Sc. *Database Systems Course Curriculum & Lecture Notes*, Department of Information Technology, Posts and Telecommunications Institute of Technology (PTIT), 2026.

3. **Synthetic Clinical Data Methodology:**
   - [Synthea™ Patient Generator](https://github.com/synthetichealth/synthea) (Synthetic Health): Jason Walonoski et al. *"Synthea: An approach, method, and software mechanism for generating realistic synthetic patients"*, Journal of the American Medical Informatics Association (JAMIA), Vol. 25, Issue 3, pp. 250–258, 2018.

