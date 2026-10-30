# Healthcare Clinic & Telemedicine Portal

Database project for **INT1313 - Database Systems**, Semester 1, Academic Year 2026-2027.  
Posts and Telecommunications Institute of Technology (PTIT).

---

## Project Identity

- **Topic:** #05: Healthcare Clinic & Telemedicine Portal
- **Team:** G5 (Pingo)

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
- [Project Scope](phase%201/project_scope.md)
- [Business Rules](phase%201/business_rules.md)
- [EER Documentation](phase%201/eer/EER_Diagram_EN.md)

### Phase 2: Logical & Physical Relational Design
- [Physical Schema Documentation](phase%202/relational_schema_mapping/physical_schema_diagram.md)
- [Data Dictionary](phase%202/data_dictionary.md)
- [Normalization Verification](phase%202/normalization_verification.md)

### Phase 3: Physical Implementation & Advanced SQL
- [01 Schema DDL (11 Tables & Views)](phase%203/01_schema.sql)
- [02 Business Triggers & Views](phase%203/02_trigger_and%20_view.sql)
- [03 Mock Data Scripts (11 Tables)](phase%203/03_mock_data/)
- [04 Analytical Queries (10 CTE & Window Function Queries)](phase%203/04_advanced_queries.sql)
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
Populate schema, mock data, and triggers automatically with UTF-8:
```bash
python load_data.py <your_mysql_password>
```
*Or manual import via MySQL CLI:*
```bash
mysql -u root -p --default-character-set=utf8mb4 -e "CREATE DATABASE IF NOT EXISTS healthcare_clinic_v2 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p --default-character-set=utf8mb4 healthcare_clinic_v2 < "phase 3/01_schema.sql"
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
│   └── project-identity.md
├── phase 1/
│   ├── eer/
│   │   └── EER_Diagram_EN.md
│   ├── business_rules.md
│   └── project_scope.md
├── phase 2/
│   ├── relational_schema_mapping/
│   │   └── physical_schema_diagram.md
│   ├── data_dictionary.md
│   └── normalization_verification.md
├── phase 3/
│   ├── 01_schema.sql
│   ├── 02_trigger_and _view.sql
│   ├── 03_mock_data/
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
├── load_data.py
├── .gitignore
└── README.md
```
