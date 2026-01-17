# Proyecto Final SQL: Sistema de Gestión "Tierra de Osos"

## 📑 Índice

1. [📌 1. Introducción](#-1-introducción)
2. [🎯 2. Objetivo](#-2-objetivo)
3. [🚨 3. Situación Problemática](#-3-situación-problemática)
4. [💼 4. Modelo de Negocio](#-4-modelo-de-negocio)
5. [📐 5. Diagrama Entidad-Relación](#-5-diagrama-entidad-relación-e-r)
6. [🧱 6. Listado de Tablas y Estructura](#-6-listado-de-tablas-y-estructura)
7. [📂 7. Scripts de Objetos de la DB](#-7-scripts-de-objetos-de-la-db)
8. [📊 8. Informe Analítico](#-8-informe-analítico)
9. [🧰 9. Herramientas Utilizadas](#-9-herramientas-utilizadas)
10. [👤 10. Autor](#-10-autor)
11. [🌟 11. Notas finales](#-11-notas-finales)

## 📌 1. Introducción

Este proyecto consiste en el diseño y despliegue de una base de datos relacional para **"Tierra de Osos"**, una empresa líder en la comercialización de peluches. El sistema está diseñado para gestionar de manera integral el inventario, la fuerza de ventas, el comportamiento de los clientes y la logística de distribución, asegurando la integridad de los datos en cada transacción.

## 🎯 2. Objetivo

El objetivo principal es transformar la operativa manual de la empresa en un ecosistema digital eficiente. El proyecto busca cubrir tres aristas fundamentales:

* **Logística:** Control automatizado de stock y alertas de reabastecimiento.
* **Contable/Ventas:** Registro preciso de facturación, métodos de pago y gestión de devoluciones.
* **Analítica:** Generación de informes estratégicos sobre tendencias de consumo y desempeño de empleados.

## 🚨 3. Situación Problemática

Antes de la implementación, "Tierra de Osos" enfrentaba:

* **Falta de trazabilidad:** No se sabía con certeza qué empleado realizaba cada venta.
* **Inconsistencia de inventario:** Quiebres de stock frecuentes por falta de alertas.
* **Información fragmentada:** Los datos de devoluciones y deseos de clientes (wishlist) se llevaban en archivos aislados, impidiendo campañas de marketing efectivas.

## 💼 4. Modelo de Negocio

La organización opera bajo un modelo **B2C e híbrido**, con ventas presenciales en múltiples sucursales y un catálogo digital. La estructura se centra en la relación entre el stock (productos/categorías) y la demanda (clientes/órdenes), mediada por un equipo de empleados y procesos de auditoría para garantizar la seguridad de la información.

## 📐 5. Diagrama Entidad-Relación (E-R)

El modelo cuenta con **15 entidades** interconectadas. La tabla de hechos principal es `order_items`, que vincula las dimensiones de tiempo (orders), personas (customers, employees) y productos.

![Diagrama Entidad-Relación para la Base de Datos de Tierra de Osos](./public/diagram.png)

## 🧱 6. Listado de Tablas y Estructura

| Tabla | Descripción | Columnas Clave | Tipo de Clave |
| :--- | :--- | :--- | :--- |
| **customers** | Datos maestros de clientes. | `customer_id` | PK |
| **suppliers** | Proveedores de suministros. | `supplier_id` | PK |
| **categories** | Clasificación de peluches. | `category_id` | PK |
| **products** | Catálogo y stock. | `product_id`, `category_id`, `supplier_id` | PK, FK, FK |
| **orders** | Cabecera de pedidos. | `order_id`, `customer_id`, `employee_id` | PK, FK, FK |
| **order_items** | Detalle transaccional (Hechos). | `id`, `order_id`, `product_id` | PK, FK, FK |
| **offices** | Sucursales físicas. | `office_id` | PK |
| **employees** | Staff de ventas y gestión. | `employee_id`, `office_id` | PK, FK |
| **payment_methods** | Opciones de pago. | `payment_id` | PK |
| **shipping_methods** | Logística de entrega. | `shipping_id` | PK |
| **discounts** | Cupones y promociones. | `discount_id` | PK |
| **product_reviews** | Feedback de clientes. | `review_id`, `product_id`, `customer_id` | PK, FK, FK |
| **wishlist** | Productos deseados. | `wishlist_id`, `customer_id`, `product_id` | PK, FK, FK |
| **returns** | Gestión de devoluciones. | `return_id`, `order_id` | PK, FK |
| **audit_logs** | Trazabilidad de cambios. | `log_id` | PK |

> [Tabla E-R en formato Excel](./public/table.xlsx)

## 📂 7. Scripts de Objetos de la DB

Se han desarrollado objetos avanzados para automatizar la lógica de negocio:

* **Vistas (5+):** Incluyendo `vw_monthly_sales` y `vw_employee_sales_performance` para reportes rápidos.
* **Stored Procedures (2+):** Destacando `sp_process_return` (automatiza la devolución de stock) y `sp_create_order`.
* **Funciones (2+):** Como `fn_calculate_order_total` y `fn_apply_discount`.
* **Triggers (2+):** Stock management en `trg_before_order_item_update`, Actualización de precio en pedidos en `trg_after_order_item_insert` y auditoría automática de eliminaciones en `audit_logs`.

## 📊 8. Informe Analítico

Mediante el análisis de las vistas generadas, se determinó que:

1. **Ventas:** La sucursal "Abasto" lidera en ticket promedio, mientras que "Casa Central" lidera en volumen.
2. **Marketing:** Existe un 15% de productos en `wishlist` que podrían convertirse con el cupón `CYBERPELUCHE`.
3. **Calidad:** La tabla `returns` muestra una tasa de devolución del 2% vinculada a un proveedor específico, permitiendo tomar decisiones de compra más inteligentes.

> [Informe Analítico Completo en Word](./public/informe-analitico.docx)

## 🧰 9. Herramientas Utilizadas

* **MySQL Workbench:** Diseño y administración de BB.DD.
* **Microsoft Excel:** Para la analítica de datos.
* **VS Code:** Edición de scripts SQL.

## 👤 10. Autor

Este proyecto fue diseñado y desarrollado por **Tomás Mársico**

Si tiene preguntas, no dude en comunicarse o abrir un problema en el repositorio.

## 🌟 11. Notas finales

Esta base de datos fue creada como un proyecto práctico de aprendizaje para comprender el diseño del modelo relacional, el uso de SQL DDL/DML y la gestión de la información empresarial utilizando un modelo de datos estructurado.

Gracias por visitar este proyecto! 😊
