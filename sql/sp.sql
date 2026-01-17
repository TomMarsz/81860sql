-- ============================================
-- STORED PROCEDURES
-- ============================================

-- Procedimiento que crea un nuevo pedido
DELIMITER //
CREATE PROCEDURE sp_create_order(
    IN p_customer_id INT,
    IN p_product_id INT,
    IN p_quantity INT
)
BEGIN
    DECLARE v_order_id INT;
    DECLARE v_unit_price DECIMAL(10,2);
    DECLARE v_current_stock INT;
    
    -- Start transaction
    START TRANSACTION;
    
    -- Chequea el precio y stock del producto
    SELECT price, stock 
    INTO v_unit_price, v_current_stock
    FROM products
    WHERE product_id = p_product_id;
    
    -- Chequea disponibilidad de stock
    IF v_current_stock < p_quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient stock for this product';
    END IF;
    
    -- Crea el pedido
    INSERT INTO orders (customer_id, total_amount)
    VALUES (p_customer_id, p_quantity * v_unit_price);
    
    SET v_order_id = LAST_INSERT_ID();
    
    -- Agrega el item al pedido
    INSERT INTO order_items (order_id, product_id, quantity, unit_price)
    VALUES (v_order_id, p_product_id, p_quantity, v_unit_price);
    
    -- Hace update del stock del producto
    UPDATE products
    SET stock = stock - p_quantity
    WHERE product_id = p_product_id;
    
    COMMIT;
    
    -- Retorna el ID del nuevo pedido
    SELECT v_order_id AS new_order_id;
END //
DELIMITER ;

-- Procedimiento para agregar item a pedido existente
DELIMITER //
CREATE PROCEDURE sp_add_order_item(
    IN p_order_id INT,
    IN p_product_id INT,
    IN p_quantity INT
)
BEGIN
    DECLARE v_unit_price DECIMAL(10,2);
    DECLARE v_current_stock INT;
    DECLARE v_item_total DECIMAL(10,2);
    
    START TRANSACTION;
    
    -- Obtiene precio y stock del producto
    SELECT price, stock
    INTO v_unit_price, v_current_stock
    FROM products
    WHERE product_id = p_product_id;
    
    -- Chequea disponibilidad de stock
    IF v_current_stock < p_quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient stock for this product';
    END IF;
    
    -- Calcula total del item
    SET v_item_total = p_quantity * v_unit_price;
    
    -- Inserta el item en el pedido
    INSERT INTO order_items (order_id, product_id, quantity, unit_price)
    VALUES (p_order_id, p_product_id, p_quantity, v_unit_price);
    
    -- Hace update del total del pedido
    UPDATE orders
    SET total_amount = total_amount + v_item_total
    WHERE order_id = p_order_id;
    
    -- Hace update del stock del producto
    UPDATE products
    SET stock = stock - p_quantity
    WHERE product_id = p_product_id;
    
    COMMIT;
END //
DELIMITER ;

-- Procedimiento para reabastecer stock de un producto
DELIMITER //
CREATE PROCEDURE sp_restock_product(
    IN p_product_id INT,
    IN p_quantity INT
)
BEGIN
    IF p_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Restock quantity must be positive';
    END IF;
    
    UPDATE products
    SET stock = stock + p_quantity
    WHERE product_id = p_product_id;
    
    SELECT CONCAT('Product restocked. New stock: ', stock) AS result
    FROM products
    WHERE product_id = p_product_id;
END //
DELIMITER ;

-- Procedimiento para obtener el historial de pedidos de un cliente
DELIMITER //
CREATE PROCEDURE sp_get_customer_orders(
    IN p_customer_id INT
)
BEGIN
    SELECT 
        o.order_id,
        o.order_date,
        o.total_amount,
        COUNT(oi.id) as total_items
    FROM orders o
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id = p_customer_id
    GROUP BY o.order_id, o.order_date, o.total_amount
    ORDER BY o.order_date DESC;
END //
DELIMITER ;

-- Procedimiento para obtener productos por categoría con stock mínimo
DELIMITER //
CREATE PROCEDURE sp_get_products_by_category(
    IN p_category_id INT,
    IN p_min_stock INT
)
BEGIN
    SELECT 
        product_id,
        name,
        price,
        stock
    FROM products
    WHERE category_id = p_category_id
    AND stock >= p_min_stock
    ORDER BY name;
END //
DELIMITER ;

-- Procedimiento para actualizar el precio de un producto
DELIMITER //
CREATE PROCEDURE sp_update_product_price(
    IN p_product_id INT,
    IN p_new_price DECIMAL(10,2)
)
BEGIN
    IF p_new_price < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Price cannot be negative';
    END IF;
    
    UPDATE products
    SET price = p_new_price
    WHERE product_id = p_product_id;
    
    SELECT 
        product_id,
        name,
        price as new_price
    FROM products
    WHERE product_id = p_product_id;
END //
DELIMITER ;

-- Procedimiento para obtener reporte de ventas por rango de fechas
DELIMITER //
CREATE PROCEDURE sp_sales_report(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    SELECT 
        DATE(o.order_date) as sale_date,
        COUNT(DISTINCT o.order_id) as total_orders,
        SUM(oi.quantity) as total_items_sold,
        SUM(oi.quantity * oi.unit_price) as total_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE DATE(o.order_date) BETWEEN p_start_date AND p_end_date
    GROUP BY DATE(o.order_date)
    ORDER BY sale_date DESC;
END //
DELIMITER ;

-- Procedimiento para cancelar un pedido y restaurar stock
DELIMITER //
CREATE PROCEDURE sp_cancel_order(
    IN p_order_id INT
)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_product_id INT;
    DECLARE v_quantity INT;
    
    DECLARE cur CURSOR FOR 
        SELECT product_id, quantity 
        FROM order_items 
        WHERE order_id = p_order_id;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    START TRANSACTION;
    
    -- Restablece el stock de los productos en el pedido
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_product_id, v_quantity;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        UPDATE products
        SET stock = stock + v_quantity
        WHERE product_id = v_product_id;
    END LOOP;
    CLOSE cur;
    
    -- Delete de la orden y sus items
    DELETE FROM orders WHERE order_id = p_order_id;
    
    COMMIT;
    
    SELECT CONCAT('Order ', p_order_id, ' cancelled and stock restored') AS result;
END //
DELIMITER ;

-- Procedimiento para alertar sobre productos con bajo stock
DELIMITER //
CREATE PROCEDURE sp_low_stock_alert(
    IN p_threshold INT
)
BEGIN
    SELECT 
        p.product_id,
        p.name,
        c.name as category,
        s.name as supplier,
        p.stock,
        s.email as supplier_email,
        s.phone as supplier_phone
    FROM products p
    JOIN categories c ON p.category_id = c.category_id
    JOIN suppliers s ON p.supplier_id = s.supplier_id
    WHERE p.stock < p_threshold
    ORDER BY p.stock ASC;
END //
DELIMITER ;

-- Procedimiento para procesar una devolución
DELIMITER //
CREATE PROCEDURE sp_process_return(
    IN p_order_id INT,
    IN p_reason TEXT
)
BEGIN
    START TRANSACTION;
    -- Registrar la devolución
    INSERT INTO returns (order_id, reason, status) VALUES (p_order_id, p_reason, 'Approved');
    
    -- Devolver stock de todos los productos de esa orden
    UPDATE products p
    JOIN order_items oi ON p.product_id = oi.product_id
    SET p.stock = p.stock + oi.quantity
    WHERE oi.order_id = p_order_id;
    
    COMMIT;
END //
DELIMITER ;

-- Procedimiento para agregar un producto a la lista de deseos
DELIMITER //
CREATE PROCEDURE sp_add_to_wishlist(
    IN p_customer_id INT,
    IN p_product_id INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM wishlist WHERE customer_id = p_customer_id AND product_id = p_product_id) THEN
        INSERT INTO wishlist (customer_id, product_id, added_date) VALUES (p_customer_id, p_product_id, CURDATE());
    END IF;
END //
DELIMITER ;


-- ============================================
-- EXAMPLES
-- ============================================

-- Crea una nueva orden
CALL sp_create_order(1, 5, 2);

-- Agrega un item a una orden existente
CALL sp_add_order_item(1, 7, 1);

-- Restockea un producto
CALL sp_restock_product(1, 50);

-- Obtiene el historial de pedidos de un cliente
CALL sp_get_customer_orders(1);

-- Obtiene productos por categoría con stock mínimo
CALL sp_get_products_by_category(1, 10);

-- Realiza update del precio de un producto
CALL sp_update_product_price(1, 5000.00);

-- Traer reporte de ventas en un rango de fechas
CALL sp_sales_report('2025-01-01', '2025-01-31');

-- Cancela un pedido y restaura el stock
CALL sp_cancel_order(11);

-- Obtiene productos con bajo stock
CALL sp_low_stock_alert(15);

-- Procesa una devolución
CALL sp_process_return(2, 'Producto defectuoso');

-- Agrega un producto a la lista de deseos
CALL sp_add_to_wishlist(1, 3);