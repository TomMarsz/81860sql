# 81860sql

## 📌 Overview

This project contains the development of a **relational database** designed for **Tierra de Osos**, a stuffed-toy retail business.

The purpose of this database is to support business operations by allowing owners and administrators to:

* Track product inventory.
* Manage customer orders.
* Maintain supplier information.
* Store relevant client data.

## 📂 Features

* Inventory management
* Order tracking
* Customer records
* Supplier management
* Product categorization
* Stock control

## 🧱 Database Structure

The relational model will include, at minimum, the following entities:

* **Products**
* **Categories**
* **Customers**
* **Orders**
* **Order Items**
* **Suppliers**

These entities are linked through primary and foreign key relationships, enabling consistent and reliable data queries.

## 📐 Entity-Relationship Diagram (ERD)

The database is conceptually based on the following relationships:

* A customer can place multiple orders
* Each order may contain multiple products
* Products are linked to categories
* Products are associated with one supplier
* Suppliers can provide multiple products

![Entity-Relationship Diagram for Tierra de Osos Data Base](./diagram.png)

## 🧱 Data Base Schema (DDL)

```sql
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(50),
    address TEXT
);

CREATE TABLE suppliers (
    supplier_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(50),
    email VARCHAR(100)
);

CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category_id INT REFERENCES categories(category_id),
    supplier_id INT REFERENCES suppliers(supplier_id),
    price DECIMAL(10,2),
    stock INT DEFAULT 0
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    order_date DATE DEFAULT CURRENT_DATE,
    total_amount DECIMAL(10,2)
);

CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    product_id INT REFERENCES products(product_id),
    quantity INT,
    unit_price DECIMAL(10,2)
);
```

## 📦 Sample Data (DML)

```sql
INSERT INTO suppliers(name) VALUES
('Bear Factory'), ('Soft Toys Intl');

INSERT INTO categories(name) VALUES
('Classic'), ('Animals'), ('Fantasy');

INSERT INTO products(name, category_id, supplier_id, price, stock)
VALUES
('Teddy Bear Brown', 1, 1, 4500, 20),
('Polar Bear', 2, 2, 5500, 15),
('Unicorn Pink', 3, 1, 6200, 10);

INSERT INTO customers(name,email) VALUES
('Ana Lopez', 'ana@gmail.com'),
('Juan Perez', 'juan@gmail.com');
```
