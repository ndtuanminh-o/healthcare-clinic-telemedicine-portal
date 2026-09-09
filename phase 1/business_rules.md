[Business_Rules_and_Constraints_EN.md](https://github.com/user-attachments/files/32011254/1.2_Business_Rules_and_Constraints_EN.md)
# Business Rules & Constraints

To maintain database consistency and eliminate erroneous data states, the system enforces twelve declarative and procedural business rules (BR-01 through BR-12) classified by structural integrity level:

## Business Rules Summary Matrix

| Rule ID | Rule Name | Formal Business Specification | Enforcement |
| :--- | :--- | :--- | :--- |
| **BR-01** | No Overlap Booking | A patient or doctor cannot have two active appointments with overlapping time intervals `[start_time, end_time]` on the same date (`appointment_date`). | DB Trigger / `EXCLUDE USING gist` |
| **BR-02** | Doctor Shift Alignment | Appointments must strictly fall within registered active duty shifts in `DOCTOR_SCHEDULE`. | DB Trigger & Lookup |
| **BR-03** | Valid State Progression | Appointment status transitions forward: `Scheduled` → `In-Progress` → `Completed`, or `Scheduled` → `Cancelled`. Backward or skipped transitions are rejected. | `CHECK` & State Trigger |
| **BR-04** | Doctor Specialization | Every doctor is strictly either a General Practitioner (with clinic room) or a Specialist (with specialty area). Disjoint (`d`) and Total (`===`) constraints apply. | EER Hierarchy & `CHECK` |
| **BR-05** | Telemedicine Channel | When `consultation_type = 'Telemedicine'`, telemedicine video link must be verified before entering `In-Progress`. | `CHECK` / Trigger |
| **BR-06** | Medical Record Integrity | Medical records require an active patient, consulting physician, and mandatory clinical diagnosis (`NOT NULL`). | FK & `NOT NULL` |
| **BR-07** | Prescription Uniqueness | At most one digital prescription is generated per completed clinical encounter (1:0..1 constraint). | `UNIQUE` Foreign Key |
| **BR-08** | Prescription Item Validity | Prescription items must reference active medicines with positive quantity (`quantity > 0`), duration (`duration_days > 0`), and dosage instructions. | Relational Schema / `CHECK` |
| **BR-09** | Real-Time Stock Decrement | Prescribing expired drugs is blocked. Changing prescription to `'Issued'` atomically decrements medicine stock. | `AFTER UPDATE` Trigger |
| **BR-10** | Prescription Immutability | Once marked `'Issued'`, prescriptions and their associated line items become strictly read-only. | `BEFORE UPDATE/DELETE` Trigger |
| **BR-11** | Single Consolidated Invoice | Each appointment generates exactly one invoice (1:1). Total bill = Consultation fee + Sum of medication costs. | `UNIQUE FK` & Trigger |
| **BR-12** | Payment Settlement | Invoices track settlement status (`Unpaid`, `Paid`, `Refunded`). Payments cannot exceed the total invoice balance. | `CHECK` & Trigger Rollback |

---

