CREATE TABLE IF NOT EXISTS PRESCRIPTION_AUDIT (
    audit_id        INT AUTO_INCREMENT PRIMARY KEY,
    prescription_id CHAR(36) NOT NULL,
    medicine_id     CHAR(36) NOT NULL,
    action          ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    old_quantity    INT NULL,
    new_quantity    INT NULL,
    changed_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_audit_prescription (prescription_id, changed_at)
);
