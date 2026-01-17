-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger para actualizar el total del pedido cuando se inserta un nuevo ítem
DELIMITER //
CREATE TRIGGER trg_after_order_item_insert
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    UPDATE orders
    SET total_amount = (
        SELECT SUM(quantity * unit_price)
        FROM order_items
        WHERE order_id = NEW.order_id
    )
    WHERE order_id = NEW.order_id;
END //
DELIMITER ;

-- Trigger para actualizar el total del pedido cuando se actualiza un ítem
DELIMITER //
CREATE TRIGGER trg_after_order_item_update
AFTER UPDATE ON order_items
FOR EACH ROW
BEGIN
    UPDATE orders
    SET total_amount = (
        SELECT SUM(quantity * unit_price)
        FROM order_items
        WHERE order_id = NEW.order_id
    )
    WHERE order_id = NEW.order_id;
END //
DELIMITER ;

-- Trigger para actualizar el total del pedido cuando se elimina un ítem
DELIMITER //
CREATE TRIGGER trg_after_order_item_delete
AFTER DELETE ON order_items
FOR EACH ROW
BEGIN
    UPDATE orders
    SET total_amount = COALESCE((
        SELECT SUM(quantity * unit_price)
        FROM order_items
        WHERE order_id = OLD.order_id
    ), 0)
    WHERE order_id = OLD.order_id;
END //
DELIMITER ;

-- Trigger para validar y ajustar stock al insertar un ítem de pedido
DELIMITER //
CREATE TRIGGER trg_before_order_item_insert
BEFORE INSERT ON order_items
FOR EACH ROW
BEGIN
    DECLARE v_current_stock INT;
    
    -- Traer stock actual
    SELECT stock INTO v_current_stock
    FROM products
    WHERE product_id = NEW.product_id;
    
    -- Chequear disponibilidad
    IF v_current_stock < NEW.quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient stock for this product';
    END IF;
    
    -- Reducir stock
    UPDATE products
    SET stock = stock - NEW.quantity
    WHERE product_id = NEW.product_id;
END //
DELIMITER ;

-- Trigger para ajustar stock al actualizar un ítem de pedido
DELIMITER //
CREATE TRIGGER trg_before_order_item_update
BEFORE UPDATE ON order_items
FOR EACH ROW
BEGIN
    DECLARE v_current_stock INT;
    DECLARE v_stock_difference INT;
    
    -- Calcular diferencia de stock
    SET v_stock_difference = NEW.quantity - OLD.quantity;
    
    IF v_stock_difference != 0 THEN
        -- Traer stock actual
        SELECT stock INTO v_current_stock
        FROM products
        WHERE product_id = NEW.product_id;
        
        -- Chequear disponibilidad si se incrementa la cantidad
        IF v_stock_difference > 0 AND v_current_stock < v_stock_difference THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient stock to increase order quantity';
        END IF;
        
        -- Ajustar stock
        UPDATE products
        SET stock = stock - v_stock_difference
        WHERE product_id = NEW.product_id;
    END IF;
END //
DELIMITER ;

-- Trigger para restaurar stock al eliminar un ítem de pedido
DELIMITER //
CREATE TRIGGER trg_after_order_item_delete_restore_stock
AFTER DELETE ON order_items
FOR EACH ROW
BEGIN
    UPDATE products
    SET stock = stock + OLD.quantity
    WHERE product_id = OLD.product_id;
END //
DELIMITER ;

-- Trigger para prevenir stock negativo en productos
DELIMITER //
CREATE TRIGGER trg_before_product_update
BEFORE UPDATE ON products
FOR EACH ROW
BEGIN
    IF NEW.stock < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Stock cannot be negative';
    END IF;
    
    IF NEW.price < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Price cannot be negative';
    END IF;
END //
DELIMITER ;

-- Trigger para prevenir stock negativo al insertar un producto
DELIMITER //
CREATE TRIGGER trg_before_product_insert
BEFORE INSERT ON products
FOR EACH ROW
BEGIN
    IF NEW.stock < 0 THEN
        SET NEW.stock = 0;
    END IF;
    
    IF NEW.price < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Price cannot be negative';
    END IF;
END //
DELIMITER ;

-- Trigger para validar email en cliente al insertar
DELIMITER //
CREATE TRIGGER trg_before_customer_insert
BEFORE INSERT ON customers
FOR EACH ROW
BEGIN
    IF NEW.email IS NOT NULL AND NEW.email NOT LIKE '%_@_%._%' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid email format';
    END IF;
END //
DELIMITER ;

-- Trigger para validar email en cliente al actualizar
DELIMITER //
CREATE TRIGGER trg_before_customer_update
BEFORE UPDATE ON customers
FOR EACH ROW
BEGIN
    IF NEW.email IS NOT NULL AND NEW.email NOT LIKE '%_@_%._%' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid email format';
    END IF;
END //
DELIMITER ;

-- Trigger para auditar eliminaciones en clientes
DELIMITER //
CREATE TRIGGER trg_audit_customer_delete
AFTER DELETE ON customers
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (table_name, action_type, user_responsible)
    VALUES ('customers', 'DELETE', USER());
END //
DELIMITER ;

-- Trigger para validar calificaciones en reseñas de productos
DELIMITER //
CREATE TRIGGER trg_before_review_insert
BEFORE INSERT ON product_reviews
FOR EACH ROW
BEGIN
    IF NEW.rating < 1 OR NEW.rating > 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: La calificación debe estar entre 1 y 5.';
    END IF;
END //
DELIMITER ;


-- ============================================
-- EXAMPLES
-- ============================================

-- ESCENARIO 1: Inserción de un nuevo ítem
-- Este escenario activa 'trg_before_order_item_insert' para validar y descontar stock, 
-- y 'trg_after_order_item_insert' para recalcular el total_amount en la tabla orders.
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (1, 2, 1, 5200.00);


-- ESCENARIO 2: Actualización de cantidad en un ítem existente
-- Este escenario activa 'trg_before_order_item_update' para ajustar la diferencia de stock 
-- (suma o resta según corresponda) y 'trg_after_order_item_update' para actualizar el total del pedido.
UPDATE order_items 
SET quantity = 5 
WHERE id = 1;


-- ESCENARIO 3: Eliminación de un ítem de la orden
-- Este escenario activa 'trg_after_order_item_delete_restore_stock' para devolver los productos al inventario 
-- y 'trg_after_order_item_delete' para restar el monto del total de la orden (o ponerlo en 0 si era el último ítem).
DELETE FROM order_items WHERE id = 1;


-- ESCENARIO 4: Validación de integridad de datos (Email)
-- Este escenario intenta insertar un formato de correo incorrecto. Activará 'trg_before_customer_insert',
-- el cual disparará un error (SIGNAL SQLSTATE) impidiendo que el registro se guarde en la base de datos.
INSERT INTO customers (name, email, phone)
VALUES ('Test User', 'invalid-email', '+54-911-0000-0000');


-- ESCENARIO 5: Validación de reglas de negocio (Stock y Precio)
-- Al intentar actualizar un producto con valores negativos, 'trg_before_product_update'
-- detendrá la operación para asegurar que el stock y el precio sean siempre coherentes.
UPDATE products 
SET stock = -10 
WHERE product_id = 2;

-- ESCENARIO 6: Auditoría de eliminaciones
-- Al eliminar un cliente, 'trg_audit_customer_delete' registrará automáticamente la acción
-- en la tabla audit_logs, permitiendo rastrear quién realizó la eliminación y cuándo.
DELETE FROM customers 
WHERE customer_id = 3;

-- ESCENARIO 7: Validación de calificaciones en reseñas de productos
-- Al intentar insertar una reseña con una calificación fuera del rango permitido,
-- 'trg_before_review_insert' impedirá la inserción y generará un error.
INSERT INTO product_reviews (product_id, customer_id, rating, comment)
VALUES (1, 1, 6, 'Excelente producto!');
-- El valor de 'rating' está fuera del rango permitido (1-5)
-- y activará el trigger que genera un error.