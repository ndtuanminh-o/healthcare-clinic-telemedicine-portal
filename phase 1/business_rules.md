[1.2_Business_Rules_and_Constraints_EN.md](https://github.com/user-attachments/files/32011254/1.2_Business_Rules_and_Constraints_EN.md)
# 1.2 Business Rules & Constraints

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

## Detailed Specifications

### BR-01: No Overlap Booking
* **Description:** A patient or doctor cannot have two active (non-cancelled) appointments with overlapping time intervals on the same calendar day.
* **Formal Specification:**
  $$\forall a_1, a_2 \in \text{APPOINTMENT} \quad (a_1 \neq a_2 \land a_1.\text{appointment\_date} = a_2.\text{appointment\_date} \land a_1.\text{status} \neq \text{'Cancelled'} \land a_2.\text{status} \neq \text{'Cancelled'}):$$
  $$(a_1.\text{doctor\_id} = a_2.\text{doctor\_id} \lor a_1.\text{patient\_id} = a_2.\text{patient\_id}) \implies [a_1.\text{start\_time}, a_1.\text{end\_time}) \cap [a_2.\text{start\_time}, a_2.\text{end\_time}) = \emptyset$$
* **Enforcement:** DB Trigger / PostgreSQL `EXCLUDE USING gist`.

### BR-02: Doctor Shift Alignment
* **Description:** Appointments must strictly fall within registered duty shifts in `DOCTOR_SCHEDULE`.
* **Formal Specification:**
  $$\forall a \in \text{APPOINTMENT}, \exists s \in \text{DOCTOR\_SCHEDULE}:$$
  $$(s.\text{doctor\_id} = a.\text{doctor\_id} \land s.\text{work\_date} = a.\text{appointment\_date} \land s.\text{start\_time} \le a.\text{start\_time} \land s.\text{end\_time} \ge a.\text{end\_time} \land s.\text{slot\_status} \ne \text{'Blocked'})$$
* **Enforcement:** DB Trigger & Lookup verification.

### BR-03: Valid State Progression
* **Description:** Appointment status must follow valid state transitions:
  * `Scheduled` $\longrightarrow$ `In-Progress` $\longrightarrow$ `Completed`
  * `Scheduled` $\longrightarrow$ `Cancelled`
* **Enforcement:** `CHECK` constraint & Database Transition Trigger.

### BR-04: Doctor Specialization
* **Description:** Every doctor belongs strictly to either `GENERAL_PRACTITIONER` or `SPECIALIST` (Disjoint 'd' and Total '===' specialization).
* **Enforcement:** EER Hierarchy mapping (Option 8.4a) with shared surrogate PK/FK and `CHECK (doctor_type IN ('GP', 'Specialist'))`.

### BR-05: Telemedicine Channel
* **Description:** If `consultation_type = 'Telemedicine'`, a valid video conference link (`telemedicine_video_link`) must be present before the appointment transitions to `In-Progress`.
* **Enforcement:** `CHECK ((consultation_type = 'In-Person') OR (consultation_type = 'Telemedicine' AND telemedicine_video_link IS NOT NULL))`.

### BR-06: Medical Record Integrity
* **Description:** Medical records require an active patient, consulting physician, and mandatory clinical diagnosis.
* **Enforcement:** `patient_id NOT NULL`, `appointment_id UNIQUE NOT NULL`, `diagnosis TEXT NOT NULL`.

### BR-07: Prescription Uniqueness
* **Description:** At most one digital prescription is issued per medical record / clinical consultation (1:0..1 cardinality).
* **Enforcement:** `record_id CHAR(36) NOT NULL UNIQUE REFERENCES MEDICAL_RECORD(record_id)`.

### BR-08: Prescription Item Validity
* **Description:** Prescription items must specify positive medication quantity and duration along with dosage instructions.
* **Enforcement:** `CHECK (quantity > 0 AND duration_days > 0 AND unit_price_at_prescription >= 0)`.

### BR-09: Real-Time Stock Decrement
* **Description:** Prescribing expired medications is blocked. Setting prescription status to `'Issued'` atomically deducts medication inventory.
* **Enforcement:** `AFTER UPDATE OF status ON DIGITAL_PRESCRIPTION` trigger decrementing `MEDICINE.stock_quantity`.

### BR-10: Prescription Immutability
* **Description:** Once marked `'Issued'` or `'Dispensed'`, prescriptions and line items become strictly immutable and cannot be updated or deleted.
* **Enforcement:** `BEFORE UPDATE OR DELETE` triggers on `DIGITAL_PRESCRIPTION` and `PRESCRIPTION_ITEM`.

### BR-11: Single Consolidated Invoice
* **Description:** Exactly one invoice per completed appointment. Total amount equals consultation fee plus total cost of prescribed items.
* **Formal Specification:**
  $$TotalAmount = Fee_{Consultation} + \sum_{i \in Items} (Quantity_i \times UnitPrice_i)$$
* **Enforcement:** `appointment_id UNIQUE` foreign key in `INVOICE` & automated calculation trigger.

### BR-12: Payment Settlement
* **Description:** Tracks settlement status (`Unpaid`, `Paid`, `Refunded`). Payments cannot exceed total invoice balance.
* **Enforcement:** `CHECK (total_amount >= 0)` & payment verification trigger rollback.
