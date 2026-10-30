DROP TRIGGER IF EXISTS trg_prescription_item_insert;
DROP TRIGGER IF EXISTS trg_prescription_item_update;
DROP TRIGGER IF EXISTS trg_prescription_item_delete;

DELIMITER //

CREATE TRIGGER trg_prescription_item_insert
AFTER INSERT ON PRESCRIPTION_ITEM
FOR EACH ROW
BEGIN
    INSERT INTO PRESCRIPTION_AUDIT (prescription_id, medicine_id, action, new_quantity)
    VALUES (NEW.prescription_id, NEW.medicine_id, 'INSERT', NEW.quantity);
END//

CREATE TRIGGER trg_prescription_item_update
AFTER UPDATE ON PRESCRIPTION_ITEM
FOR EACH ROW
BEGIN
    INSERT INTO PRESCRIPTION_AUDIT (prescription_id, medicine_id, action, old_quantity, new_quantity)
    VALUES (NEW.prescription_id, NEW.medicine_id, 'UPDATE', OLD.quantity, NEW.quantity);
END//

CREATE TRIGGER trg_prescription_item_delete
AFTER DELETE ON PRESCRIPTION_ITEM
FOR EACH ROW
BEGIN
    INSERT INTO PRESCRIPTION_AUDIT (prescription_id, medicine_id, action, old_quantity)
    VALUES (OLD.prescription_id, OLD.medicine_id, 'DELETE', OLD.quantity);
END//

DELIMITER ;
