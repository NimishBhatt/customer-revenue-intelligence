-- ============================================================
-- CUSTOMER & REVENUE INTELLIGENCE PLATFORM
-- ANALYTICAL DATABASE VIEWS
-- ============================================================


-- ------------------------------------------------------------
-- 1. CUSTOMER RFM VIEW
-- Purpose:
-- Create a reusable customer-level dataset containing
-- Recency, Frequency, Monetary value and customer segment.
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW customer_rfm AS

WITH reference_date AS (

    SELECT
        MAX(order_purchase_timestamp::timestamp)
            + INTERVAL '1 day' AS analysis_date

    FROM orders

    WHERE order_status = 'delivered'
),

rfm_base AS (

    SELECT
        c.customer_unique_id,

        (
            SELECT analysis_date
            FROM reference_date
        )::date
        -
        MAX(o.order_purchase_timestamp::timestamp)::date
            AS recency_days,

        COUNT(DISTINCT o.order_id)
            AS frequency,

        SUM(oi.price)
            AS monetary_value

    FROM customers AS c

    INNER JOIN orders AS o
        ON c.customer_id = o.customer_id

    INNER JOIN order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
),

rfm_scores AS (

    SELECT
        *,

        CASE
            WHEN recency_days <= 115 THEN 4
            WHEN recency_days <= 219 THEN 3
            WHEN recency_days <= 347 THEN 2
            ELSE 1
        END AS r_score,

        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            WHEN frequency = 3 THEN 3
            ELSE 4
        END AS f_score,

        CASE
            WHEN monetary_value <= 47.65 THEN 1
            WHEN monetary_value <= 89.73 THEN 2
            WHEN monetary_value <= 154.74 THEN 3
            ELSE 4
        END AS m_score

    FROM rfm_base
)

SELECT
    customer_unique_id,

    recency_days,

    frequency,

    ROUND(
        monetary_value::numeric,
        2
    ) AS monetary_value,

    r_score,

    f_score,

    m_score,

    CONCAT(
        r_score,
        f_score,
        m_score
    ) AS rfm_code,

    r_score + f_score + m_score
        AS rfm_total_score,

    CASE

        WHEN r_score >= 3
             AND frequency >= 2
             AND m_score >= 3
            THEN 'Champions'

        WHEN r_score >= 3
             AND frequency >= 2
            THEN 'Active Repeat'

        WHEN r_score = 4
             AND frequency = 1
             AND m_score = 4
            THEN 'High-Value Recent'

        WHEN r_score >= 3
             AND frequency = 1
            THEN 'Recent One-Time'

        WHEN r_score <= 2
             AND (
                 frequency >= 2
                 OR m_score >= 3
             )
            THEN 'At-Risk Valuable'

        ELSE 'Inactive Low-Value'

    END AS customer_segment



FROM rfm_scores;

SELECT
    customer_segment,
    COUNT(*) AS customers,
    ROUND(SUM(monetary_value), 2) AS product_revenue
FROM customer_rfm
GROUP BY customer_segment
ORDER BY product_revenue DESC;

"At-Risk Valuable"	23304	5472922.73
"Recent One-Time"	39728	4277382.92
"High-Value Recent"	5409	1959711.89
"Inactive Low-Value"	23374	1103695.61
"Champions"	1310	393299.50
"Active Repeat"	233	14485.46

