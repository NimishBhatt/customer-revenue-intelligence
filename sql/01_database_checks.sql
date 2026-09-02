-- ============================================
-- DATABASE VALIDATION
-- Customer & Revenue Intelligence Platform
-- ============================================


-- 1. Number of customers
SELECT COUNT(*) AS customers_count
FROM customers;


-- 2. Number of orders
SELECT COUNT(*) AS orders_count
FROM orders;


-- 3. Number of order items
SELECT COUNT(*) AS order_items_count
FROM order_items;


-- 4. Number of payment records
SELECT COUNT(*) AS payments_count
FROM payments;


-- 5. Number of reviews
SELECT COUNT(*) AS reviews_count
FROM reviews;


-- 6. Number of products
SELECT COUNT(*) AS products_count
FROM products;


-- 7. Number of sellers
SELECT COUNT(*) AS sellers_count
FROM sellers;


-- 8. Inspect sample orders
SELECT *
FROM orders
LIMIT 10;


-- 9. Orders by status
SELECT
    order_status,
    COUNT(*) AS number_of_orders
FROM orders
GROUP BY order_status
ORDER BY number_of_orders DESC;


-- 10. Dataset date range
SELECT
    MIN(order_purchase_timestamp) AS first_order,
    MAX(order_purchase_timestamp) AS last_order
FROM orders;


-- 11. Test relationship between orders and customers
SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state
FROM orders AS o

LEFT JOIN customers AS c
    ON o.customer_id = c.customer_id

LIMIT 20;