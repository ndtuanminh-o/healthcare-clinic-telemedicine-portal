[business_rules.md](https://github.com/user-attachments/files/31456500/business_rules.md)
# Business Rules

## Appointment and Doctor Rules

- **BR-001:** A patient or doctor cannot have two active (`Scheduled`)
  appointments whose time periods overlap.
- **BR-002:** Every appointment must reference exactly one active patient and
  one active doctor. `start_datetime` must be earlier than `end_datetime`.
- **BR-003:** Only a `GENERAL_PRACTITIONER` may be assigned to a
  `Telemedicine` appointment. A Specialist may only be assigned to an
  `In-person` appointment.
- **BR-004:** An appointment must fall within the assigned doctor's schedule and
  must not fall on a registered leave date.
- **BR-005:** A Specialist may have one or more registered specialties through
  `DOCTOR_SPECIALTY`. Specialist care must be within a registered specialty.
- **BR-006:** A referral may be created by a General Practitioner when
  specialist care is required. It must specify a target specialty and a
  non-empty reason.
- **BR-007:** An appointment starts as `Scheduled` and may transition to
  `Completed` or `Cancelled`. A cancelled appointment requires a cancellation
  reason. Cancelled appointments cannot become completed, and completed
  appointments cannot become cancelled.

## Clinical and Prescription Rules

- **BR-008:** A prescription may be created only for a `Completed` appointment.
- **BR-009:** Every prescription item must reference an existing medicine. The
  same medicine may appear at most once in one prescription, and quantity must
  be greater than zero.
- **BR-010:** The system must reject issuing a prescription when inventory is
  lower than the requested quantity.
- **BR-011:** Issuing a prescription deducts each item quantity from inventory
  atomically.
- **BR-012:** When inventory reaches or falls below `reorder_level`, the system
  creates a notification for the Pharmacist and Administrator.
- **BR-013:** An issued prescription and its items cannot be edited or deleted.

## Billing Rules

- **BR-014:** Every `Completed` appointment must have exactly one invoice.
  `Scheduled` and `Cancelled` appointments must not have invoices.
- **BR-015:** The sum of payments for an invoice must not exceed
  `total_amount`. The invoice becomes `Paid` when the sum equals `total_amount`.
- **BR-016:** An unpaid invoice may become `Overdue` after `due_date`. A paid
  invoice cannot become overdue.

## Security and System Rules

- **BR-017:** Inserts, updates, and soft deletes affecting sensitive patient,
  clinical, prescription, appointment, and billing data must create an audit
  log record.
- **BR-018:** An account is temporarily locked after more than five consecutive
  failed login attempts. A successful login resets the counter.
- **BR-019:** A user session expires after 30 minutes without activity.
- **BR-020:** A failed notification may be retried up to three times. After the
  third failure its status is recorded as `Failed`.
- **BR-021:** Core records must not be physically deleted. Soft deletion sets
  `deleted_at` and changes the record status to `Inactive` where applicable.



