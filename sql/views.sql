-- ============================================
-- VIEWS
-- ============================================

-- Vista para mostrar los pedidos de los clientes con detalles de productos
CREATE VIEW vw_customer_orders AS
SELECT 
    o.order_id,
    c.customer_id,
    c.name AS customer_name,
    c.email AS customer_email,
    o.order_date,
    o.total_amount,
    oi.product_id,
    p.name AS product_name,
    oi.quantity,
    oi.unit_price
FROM 
    orders o
JOIN
    customers c ON o.customer_id = c.customer_id
JOIN  
    order_items oi ON o.order_id = oi.order_id
JOIN
    products p ON oi.product_id = p.product_id;

-- Vista para mostrar el inventario de productos con sus categorías y proveedores
CREATE VIEW vw_product_inventory AS
SELECT
    p.product_id,
    p.name AS product_name,
    c.name AS category_name,
    s.name AS supplier_name,
    p.price,
    p.stock
FROM
    products p
JOIN
    categories c ON p.category_id = c.category_id
JOIN
    suppliers s ON p.supplier_id = s.supplier_id;

-- Vista para mostrar proveedores con sus productos
CREATE VIEW vw_supplier_products AS
SELECT
    s.supplier_id,
    s.name AS supplier_name,
    p.product_id,
    p.name AS product_name,
    p.price,
    p.stock
FROM
    suppliers s 
JOIN
    products p ON s.supplier_id = p.supplier_id;

-- Vista para mostrar categorías con sus productos
CREATE VIEW vw_category_products AS
SELECT
    c.category_id,
    c.name AS category_name,
    p.product_id,
    p.name AS product_name,
    p.price,
    p.stock
FROM
    categories c
JOIN
    products p ON c.category_id = p.category_id;

-- Vista para mostrar resumen de pedidos con total calculado
CREATE VIEW vw_order_summary AS
SELECT
    o.order_id,
    c.customer_id,
    c.name AS customer_name,
    o.order_date,
    SUM(oi.quantity * oi.unit_price) AS calculated_total_amount
FROM
    orders o
JOIN
    customers c ON o.customer_id = c.customer_id
JOIN
    order_items oi ON o.order_id = oi.order_id
GROUP BY
    o.order_id, c.customer_id, c.name, o.order_date;

-- Vista para mostrar productos con bajo stock
CREATE VIEW vw_low_stock_products AS
SELECT
    p.product_id,
    p.name AS product_name,
    c.name AS category_name,
    s.name AS supplier_name,
    p.price,
    p.stock
FROM
    products p
JOIN
    categories c ON p.category_id = c.category_id
JOIN
    suppliers s ON p.supplier_id = s.supplier_id
WHERE
    p.stock < 10;

 -- Vista para mostrar cantidad de pedidos realizados por cliente
CREATE VIEW vw_customer_order_counts AS
SELECT
    c.customer_id,
    c.name AS customer_name,
    COUNT(o.order_id) AS total_orders 
FROM
    customers c
LEFT JOIN
    orders o ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id, c.name;

-- Vista para mostrar cantidad de productos por proveedor
CREATE VIEW vw_supplier_product_counts AS
SELECT
    s.supplier_id,
    s.name AS supplier_name,
    COUNT(p.product_id) AS total_products
FROM
    suppliers s
LEFT JOIN
    products p ON s.supplier_id = p.supplier_id
GROUP BY
    s.supplier_id, s.name;

-- Vista para mostrar cantidad de productos por categoría
CREATE VIEW vw_category_product_counts AS
SELECT
    c.category_id,
    c.name AS category_name,
    COUNT(p.product_id) AS total_products
FROM
    categories c
LEFT JOIN
    products p ON c.category_id = p.category_id
GROUP BY
    c.category_id, c.name;

-- Vista para mostrar ventas mensuales
CREATE VIEW vw_monthly_sales AS
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
    SUM(oi.quantity * oi.unit_price) AS total_sales
FROM
    orders o
JOIN
    order_items oi ON o.order_id = oi.order_id
GROUP BY
    DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY
    order_month;

-- Vista para mostrar los productos más vendidos
CREATE VIEW vw_top_selling_products AS
SELECT
    p.product_id,
    p.name AS product_name,
    SUM(oi.quantity) AS total_quantity_sold
FROM
    products p
JOIN
    order_items oi ON p.product_id = oi.product_id
GROUP BY
    p.product_id, p.name
HAVING
    total_quantity_sold > 0
ORDER BY
    total_quantity_sold DESC
LIMIT 10;

-- Vista para mostrar detalles completos de los ítems de los pedidos
CREATE VIEW vw_detailed_order_items AS
SELECT
    o.order_id,
    c.customer_id,
    c.name AS customer_name,
    o.order_date,
    oi.product_id,
    p.name AS product_name,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price) AS total_price
FROM
    orders o
JOIN
    customers c ON o.customer_id = c.customer_id
JOIN
    order_items oi ON o.order_id = oi.order_id
JOIN
    products p ON oi.product_id = p.product_id;

-- Vista para mostrar el desempeño de ventas por empleado
CREATE VIEW vw_employee_sales_performance AS
SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    o.name AS office_name,
    COUNT(ord.order_id) AS total_orders_handled,
    SUM(ord.total_amount) AS total_revenue_generated
FROM 
    employees e
JOIN 
    offices o ON e.office_id = o.office_id
LEFT JOIN 
    orders ord ON e.employee_id = ord.employee_id
GROUP BY 
    e.employee_id;

-- Vista para mostrar el resumen de calificaciones de productos
CREATE VIEW vw_product_rating_summary AS
SELECT 
    p.product_id,
    p.name AS product_name,
    AVG(pr.rating) AS average_rating,
    COUNT(pr.review_id) AS total_reviews
FROM 
    products p
LEFT JOIN 
    product_reviews pr ON p.product_id = pr.product_id
GROUP BY 
    p.product_id;

-- Vista para mostrar los productos más agregados a listas de deseos
CREATE VIEW vw_most_wishlisted_products AS
SELECT 
    p.name AS product_name,
    COUNT(w.wishlist_id) AS times_added_to_wishlist
FROM 
    products p
JOIN 
    wishlist w ON p.product_id = w.product_id
GROUP BY 
    p.product_id
ORDER BY 
    times_added_to_wishlist DESC;

-- ============================================
-- EXAMPLES
-- ============================================

-- Vista para mostrar los pedidos de los clientes con detalles de productos
SELECT * FROM vw_customer_orders WHERE customer_id = 1;

-- Vista para mostrar el inventario de productos con sus categorías y proveedores
SELECT * FROM vw_product_inventory WHERE stock < 20;

-- Vista para mostrar proveedores con sus productos
SELECT * FROM vw_supplier_products WHERE supplier_id = 2;

-- Vista para mostrar categorías con sus productos
SELECT * FROM vw_category_products WHERE category_id = 3;

-- Vista for mostrar resumen de pedidos con total calculado
SELECT * FROM vw_order_summary WHERE order_id = 1;

-- Vista para mostrar productos con bajo stock
SELECT * FROM vw_low_stock_products;

-- Vista para mostrar cantidad de pedidos realizados por cliente
SELECT * FROM vw_customer_order_counts ORDER BY total_orders DESC;

-- Vista para mostrar cantidad de productos por proveedor
SELECT * FROM vw_supplier_product_counts ORDER BY total_products DESC;

-- Vista para mostrar cantidad de productos por categoría
SELECT * FROM vw_category_product_counts ORDER BY total_products DESC;

-- Vista para mostrar ventas mensuales
SELECT * FROM vw_monthly_sales ORDER BY order_month DESC;

-- Vista para mostrar productos más vendidos
SELECT * FROM vw_top_selling_products;

-- Vista para mostrar detalles completos de los ítems de los pedidos
SELECT * FROM vw_detailed_order_items WHERE order_id = 1;

-- Vista para mostrar el desempeño de ventas por empleado
SELECT * FROM vw_employee_sales_performance ORDER BY total_revenue_generated DESC;

-- Vista para mostrar el resumen de calificaciones de productos
SELECT * FROM vw_product_rating_summary WHERE average_rating >= 4.0;

-- Vista para mostrar los productos más agregados a listas de deseos
SELECT * FROM vw_most_wishlisted_products LIMIT 10;