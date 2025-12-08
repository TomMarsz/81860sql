CREATE DATABASE TierraDeOsosDB;
USE TierraDeOsosDB;

CREATE TABLE customers
(
  customer_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100),
  phone VARCHAR(50),
  address TEXT
);

CREATE TABLE suppliers
(
  supplier_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(50),
  email VARCHAR(100),
  address TEXT
);

CREATE TABLE categories
(
  category_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL
);

CREATE TABLE products
(
  product_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  category_id INT REFERENCES categories(category_id),
  supplier_id INT REFERENCES suppliers(supplier_id),
  price DECIMAL(10,2),
  stock INT DEFAULT 0
);

CREATE TABLE orders
(
  order_id SERIAL PRIMARY KEY,
  customer_id INT REFERENCES customers(customer_id),
  order_date DATE DEFAULT CURRENT_DATE,
  total_amount DECIMAL(10,2)
);

CREATE TABLE order_items
(
  id SERIAL PRIMARY KEY,
  order_id INT REFERENCES orders(order_id),
  product_id INT REFERENCES products(product_id),
  quantity INT,
  unit_price DECIMAL(10,2)
);
