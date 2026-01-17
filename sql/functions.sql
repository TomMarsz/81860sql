-- ============================================
-- FUNCTIONS
-- ============================================

-- Función para calcular el total de un pedido
DELIMITER //
CREATE FUNCTION fn_calculate_order_total(p_order_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(10,2);
    
    SELECT COALESCE(SUM(quantity * unit_price), 0)
    INTO v_total
    FROM order_items
    WHERE order_id = p_order_id;
    
    RETURN v_total;
END //
DELIMITER ;

-- Función para verificar disponibilidad de stock
DELIMITER //
CREATE FUNCTION fn_check_stock_availability(p_product_id INT, p_quantity INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_current_stock INT;
    
    SELECT stock INTO v_current_stock
    FROM products
    WHERE product_id = p_product_id;
    
    RETURN v_current_stock >= p_quantity;
END //
DELIMITER ;

-- Función para obtener el gasto total de un cliente
DELIMITER //
CREATE FUNCTION fn_customer_total_spent(p_customer_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(10,2);
    
    SELECT COALESCE(SUM(total_amount), 0)
    INTO v_total
    FROM orders
    WHERE customer_id = p_customer_id;
    
    RETURN v_total;
END //
DELIMITER ;

-- Función para obtener el estado de stock de un producto
DELIMITER //
CREATE FUNCTION fn_stock_status(p_product_id INT)
RETURNS VARCHAR(20)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_stock INT;
    DECLARE v_status VARCHAR(20);
    
    SELECT stock INTO v_stock
    FROM products
    WHERE product_id = p_product_id;
    
    IF v_stock < 10 THEN
        SET v_status = 'Low Stock';
    ELSEIF v_stock < 30 THEN
        SET v_status = 'Normal';
    ELSE
        SET v_status = 'High Stock';
    END IF;
    
    RETURN v_status;
END //
DELIMITER ;

-- Función para obtener el valor total del inventario por categoría
DELIMITER //
CREATE FUNCTION fn_category_inventory_value(p_category_id INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total_value DECIMAL(12,2);
    
    SELECT COALESCE(SUM(price * stock), 0)
    INTO v_total_value
    FROM products
    WHERE category_id = p_category_id;
    
    RETURN v_total_value;
END //
DELIMITER ;

-- Funcion para aplicar un descuento a un monto dado
DELIMITER //
CREATE FUNCTION fn_apply_discount(p_amount DECIMAL(10,2), p_discount_id INT) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_percentage DECIMAL(5,2);
    SELECT percentage_off INTO v_percentage FROM discounts WHERE discount_id = p_discount_id AND active = TRUE;
    IF v_percentage IS NULL THEN RETURN p_amount; END IF;
    RETURN p_amount - (p_amount * (v_percentage / 100));
END //
DELIMITER ;

-- Funcion para obtener el costo de envío según el método seleccionado
DELIMITER //
CREATE FUNCTION fn_get_shipping_cost(p_method_name VARCHAR(100))
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_cost DECIMAL(10,2);
    SELECT cost INTO v_cost FROM shipping_methods WHERE name = p_method_name LIMIT 1;
    RETURN COALESCE(v_cost, 0);
END //
DELIMITER ;


-- ============================================
-- EXAMPLES
-- ============================================

-- Trae el total de un pedido
SELECT fn_calculate_order_total(1) as order_total;

-- Verifica disponibilidad de stock
SELECT fn_check_stock_availability(1, 5) as has_stock;

-- Trae el gasto total de un cliente
SELECT fn_customer_total_spent(1) as total_spent;

-- Trae el estado de stock de productos
SELECT name, stock, fn_stock_status(product_id) as status
FROM products;

-- Trae el valor total del inventario por categoría
SELECT 
    c.name,
    fn_category_inventory_value(c.category_id) as inventory_value
FROM categories c;

-- Aplica un descuento a un monto dado
SELECT fn_apply_discount(1000.00, 1) as discounted_amount;

-- Obtiene el costo de envío según el método seleccionado
SELECT fn_get_shipping_cost('Envío Estándar a Domicilio') as shipping
