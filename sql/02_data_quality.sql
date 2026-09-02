-- ============================================================
-- CUSTOMER & REVENUE INTELLIGENCE PLATFORM
-- DATA QUALITY ANALYSIS
-- ============================================================

-- ------------------------------------------------------------
-- 1. MISSING VALUES IN ORDERS
-- Purpose:
-- Identify missing timestamps and customer IDs before analysis.
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_orders,

    COUNT(*) - COUNT(customer_id)
        AS missing_customer_id,

    COUNT(*) - COUNT(order_status)
        AS missing_order_status,

    COUNT(*) - COUNT(order_purchase_timestamp)
        AS missing_purchase_timestamp,

    COUNT(*) - COUNT(order_approved_at)
        AS missing_approved_at,

    COUNT(*) - COUNT(order_delivered_carrier_date)
        AS missing_carrier_date,

    COUNT(*) - COUNT(order_delivered_customer_date)
        AS missing_customer_delivery_date,

    COUNT(*) - COUNT(order_estimated_delivery_date)
        AS missing_estimated_delivery_date

FROM orders;

-- ------------------------------------------------------------
-- 2. MISSING DELIVERY DATES BY ORDER STATUS
-- Purpose:
-- Determine whether missing delivery dates are explained by
-- cancelled, unavailable, or otherwise incomplete orders.
-- ------------------------------------------------------------

SELECT
    order_status,
    COUNT(*) AS orders_with_missing_delivery_date
FROM orders
WHERE order_delivered_customer_date IS NULL
GROUP BY order_status
ORDER BY orders_with_missing_delivery_date DESC;

-- ------------------------------------------------------------
-- 3. DUPLICATE ORDER IDs
-- Purpose:
-- order_id should uniquely identify an order.
-- Any result returned here requires investigation.
-- ------------------------------------------------------------

SELECT
    order_id,
    COUNT(*) AS occurrences
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

-- ------------------------------------------------------------
-- 4. CUSTOMER IDENTIFIER UNIQUENESS
-- Purpose:
-- Understand the difference between customer_id and
-- customer_unique_id before customer-level analysis.
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS unique_real_customers
FROM customers;

-- ------------------------------------------------------------
-- 5. PRICE AND FREIGHT VALUE RANGE
-- Purpose:
-- Detect impossible or suspicious negative transaction values.
-- ------------------------------------------------------------

SELECT
    MIN(price) AS minimum_price,
    MAX(price) AS maximum_price,
    AVG(price) AS average_price,

    MIN(freight_value) AS minimum_freight,
    MAX(freight_value) AS maximum_freight,
    AVG(freight_value) AS average_freight

FROM order_items;

-- ------------------------------------------------------------
-- 6. NEGATIVE PRICE OR FREIGHT VALUES
-- Purpose:
-- Negative prices/freight would require investigation before
-- calculating revenue.
-- ------------------------------------------------------------

SELECT *
FROM order_items
WHERE price < 0
   OR freight_value < 0;

   -- ------------------------------------------------------------
-- 7. REVIEW SCORE DISTRIBUTION
-- Purpose:
-- Verify review scores fall within the expected range and
-- understand the overall distribution.
-- ------------------------------------------------------------

SELECT
    review_score,
    COUNT(*) AS number_of_reviews
FROM reviews
GROUP BY review_score
ORDER BY review_score;

-- ------------------------------------------------------------
-- 8. INVALID DELIVERY CHRONOLOGY
-- Purpose:
-- Detect records where delivery appears to occur before the
-- purchase timestamp.
-- ------------------------------------------------------------

SELECT
    order_id,
    order_purchase_timestamp,
    order_delivered_customer_date
FROM orders
WHERE order_delivered_customer_date::timestamp
      < order_purchase_timestamp::timestamp;


-- ------------------------------------------------------------
-- 9. ORDERS WITHOUT MATCHING CUSTOMER RECORD
-- Purpose:
-- Verify referential consistency between orders and customers.
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS unmatched_orders
FROM orders AS o

LEFT JOIN customers AS c
    ON o.customer_id = c.customer_id

WHERE c.customer_id IS NULL;

-- ------------------------------------------------------------
-- 10. ORDER ITEMS WITHOUT MATCHING ORDER
-- Purpose:
-- Verify that every transaction item belongs to a valid order.
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS unmatched_order_items
FROM order_items AS oi

LEFT JOIN orders AS o
    ON oi.order_id = o.order_id

WHERE o.order_id IS NULL;

-- ============================================================
-- DATA QUALITY CONCLUSIONS
-- ============================================================
--
-- 1. No duplicate order IDs were identified.
--
-- 2. No negative product prices or freight values were found.
--
-- 3. Review scores fall within the expected 1-5 range.
--
-- 4. No delivery dates occurred before purchase dates.
--
-- 5. All orders successfully matched customer records.
--
-- 6. All order items successfully matched order records.
--
-- 7. customer_id and customer_unique_id represent different
--    concepts. customer_unique_id will be used for customer-level
--    analysis because it allows repeat purchases by the same
--    customer to be identified.
--
-- 8. Missing delivery-related timestamps should not automatically
--    be treated as data-quality errors because some orders were
--    canceled, unavailable, shipped, or otherwise incomplete.
--
-- 9. Revenue analysis will primarily use delivered orders so that
--    canceled or incomplete transactions are not treated as
--    completed sales.
--
-- ============================================================